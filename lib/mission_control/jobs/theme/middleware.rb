# frozen_string_literal: true

require "rack/utils"

module MissionControl
  module Jobs
    module Theme
      # Intercept HTML responses from the Mission Control Jobs engine and inject
      # theme CSS and optional Prism.js syntax highlighting before +</head>+.
      #
      # Only rewrites responses that match the engine mount path and have an
      # +text/html+ content type.
      #
      # The color scheme is resolved per-request: a +mc_jobs_color_scheme+ cookie
      # (set by the client-side color scheme switcher) takes precedence over the configured
      # default. When the effective scheme is +:auto+, both light and dark
      # stylesheets are injected with +prefers-color-scheme+ media queries.
      # When an explicit scheme is active, only that variant's CSS is loaded.
      #
      # Injected +<script>+ tags automatically receive a CSP nonce when one is
      # available via +action_dispatch.content_security_policy_nonce+ in the Rack
      # env or a +<meta name="csp-nonce">+ tag in the response body.
      #
      # @see Railtie
      # @see RouteDiscovery
      #
      # @example Manual Rack usage (typically wired by {Railtie})
      #   config = MissionControl::Jobs::Theme::Configuration.new
      #   config.color_scheme = :dark
      #   config.syntax_highlighting = false
      #
      #   use MissionControl::Jobs::Theme::Middleware, mount_path: "/admin/jobs", config: config
      class Middleware
        NONCE_PLACEHOLDER = "THEME_NONCE"
        NONCE_ATTR = " nonce=\"#{NONCE_PLACEHOLDER}\"".freeze

        # @param app [#call] the next Rack application in the middleware stack
        # @param mount_path [String] engine mount path to match against requests
        # @param config [Configuration] theme configuration (defaults to current
        #   global configuration)
        def initialize(app, mount_path: RouteDiscovery::FALLBACK, config: Configuration.new)
          @app = app
          @mount_path = mount_path
          @mount_path_prefix = "#{mount_path}/"
          @theme = config.theme
          @default_color_scheme = config.color_scheme
          @syntax_highlighting = config.syntax_highlighting
          @color_scheme_switcher = config.color_scheme_switcher
          @injections =
            (Configuration::COLOR_SCHEMES + [:auto]).to_h { |scheme| [scheme, build_injection(scheme)] }
        end

        # Process a Rack request, injecting theme assets into matching HTML responses.
        #
        # @param env [Hash] Rack environment hash
        # @return [Array(Integer, Hash, #each)] Rack-compatible response triplet
        def call(env)
          status, headers, response = @app.call(env)

          if inject_theme?(env, status, headers)
            body = +""
            response.each { |part| body << part }
            response.close if response.respond_to?(:close)

            scheme = resolve_color_scheme(env)
            nonce = resolve_csp_nonce(env, body)
            injection = @injections[scheme].gsub(nonce ? NONCE_PLACEHOLDER : NONCE_ATTR, nonce || "")

            body.sub!("</head>", injection)
            headers["content-length"] = body.bytesize.to_s if headers.key?("content-length")

            [status, headers, [body]]
          else
            [status, headers, response]
          end
        end

        private

        def resolve_color_scheme(env)
          cookie_color_scheme(env) || @default_color_scheme
        end

        def cookie_color_scheme(env)
          return unless (header = env["HTTP_COOKIE"])

          value = ::Rack::Utils.parse_cookies_header(header)[Configuration::COOKIE_NAME]&.to_sym
          value if value && Configuration::COLOR_SCHEMES.include?(value)
        end

        # Checks the Rack env first (set by Rails when the view renders
        # +csp_meta_tag+), then falls back to extracting it from the HTML
        # +<meta name="csp-nonce">+ tag. The meta-tag path only recognises
        # standard and URL-safe Base64 nonces; the env path accepts any string.
        #
        # @param env [Hash] Rack environment hash
        # @param body [String] accumulated HTML response body
        # @return [String, nil] the nonce value, or +nil+ if not available
        def resolve_csp_nonce(env, body)
          env["action_dispatch.content_security_policy_nonce"] ||
            body[/<meta name="csp-nonce" content="([A-Za-z0-9+\/=\-_]+)"/, 1]
        end

        # Determine whether the response should receive theme injection.
        #
        # Matches when the request path falls under the engine mount path, the
        # status is 200, and the content type is +text/html+. Accounts for
        # +SCRIPT_NAME+ to support sub-URI deployments.
        #
        # @param env [Hash] Rack environment hash
        # @param status [Integer] HTTP response status code
        # @param headers [Hash] HTTP response headers
        # @return [Boolean]
        def inject_theme?(env, status, headers)
          return false unless status == 200
          return false unless headers["content-type"]&.include?("text/html")

          script_name = env["SCRIPT_NAME"]
          full_path = script_name.empty? ? env["PATH_INFO"] : "#{script_name}#{env["PATH_INFO"]}"
          full_path == @mount_path || full_path.start_with?(@mount_path_prefix)
        end

        def build_injection(color_scheme)
          auto = color_scheme == :auto
          schemes = auto ? Configuration::COLOR_SCHEMES : [color_scheme]

          # Theme stylesheets
          parts =
            schemes.map do |scheme|
              stylesheet_tag("/mission_control/css/#{@theme}_#{scheme}.min.css", scheme: (scheme if auto))
            end

          # Prism.js syntax highlighting (CSS + JS)
          syntax_highlighting_tags(schemes, auto:, into: parts) if @syntax_highlighting

          # Client-side color scheme switcher (auto / light / dark)
          parts << color_scheme_switcher_tag if @color_scheme_switcher

          "#{parts.join("\n")}</head>".freeze
        end

        def syntax_highlighting_tags(schemes, auto:, into:)
          schemes.each do |scheme|
            prism_theme = scheme == :dark ? "tomorrow" : "default"
            into << stylesheet_tag("/mission_control/css/prism.#{prism_theme}.min.css", scheme: (scheme if auto))
          end
          into << script_tag("/mission_control/js/prism.min.js", extra: "data-manual")
          into << script_tag("/mission_control/js/prism-init.js")
        end

        def script_tag(src, extra: nil)
          extra_attrs = extra ? " #{extra}" : ""
          %(<script src="#{src}"#{extra_attrs}#{NONCE_ATTR}></script>)
        end

        def stylesheet_tag(href, scheme: nil)
          media_attr = %( media="(prefers-color-scheme: #{scheme})") if scheme
          %(<link rel="stylesheet" href="#{href}"#{media_attr}>)
        end

        def color_scheme_switcher_tag
          script_tag(
            "/mission_control/js/color-scheme-switcher.js",
            extra: "data-default-color-scheme=\"#{@default_color_scheme}\" " \
                   "data-cookie-name=\"#{Configuration::COOKIE_NAME}\""
          )
        end
      end
    end
  end
end
