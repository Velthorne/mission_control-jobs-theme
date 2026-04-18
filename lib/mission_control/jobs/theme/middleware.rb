# frozen_string_literal: true

require "rack/utils"

module MissionControl
  module Jobs
    module Theme
      # Intercept HTML responses from the Mission Control Jobs engine and inject
      # theme CSS and optional Prism.js syntax highlighting before +</head>+.
      #
      # Only rewrites +200+ responses with a +text/html+ content type.
      #
      # The color scheme is resolved per-request: a +mc_jobs_color_scheme+ cookie
      # (set by the client-side color scheme switcher) takes precedence over the configured
      # default. When the effective scheme is +:auto+, both light and dark
      # stylesheets are injected with +prefers-color-scheme+ media queries.
      # When an explicit scheme is active, only that variant's CSS is loaded.
      #
      # Asset URLs are resolved through the Rails asset pipeline
      # (Propshaft/Sprockets), so injected +<link>+ and +<script>+ tags use
      # fingerprinted, cache-friendly paths that respect +config.relative_url_root+.
      #
      # Injected +<script>+ tags automatically receive a CSP nonce when one is
      # available via +action_dispatch.content_security_policy_nonce+ in the Rack
      # env or a +<meta name="csp-nonce">+ tag in the response body.
      #
      # @see Engine
      class Middleware
        # @param app [#call] the next Rack application in the middleware stack
        # @param config [Configuration] theme configuration
        def initialize(app, config:)
          @app = app
          @theme = config.theme
          @default_color_scheme = config.color_scheme
          @syntax_highlighting = config.syntax_highlighting
          @color_scheme_switcher = config.color_scheme_switcher
        end

        # @param env [Hash] Rack environment hash
        # @return [Array(Integer, Hash, #each)] Rack-compatible response triplet
        def call(env)
          status, headers, response = @app.call(env)

          if inject_theme?(status, headers)
            body = +""
            response.each { |part| body << part }
            response.close if response.respond_to?(:close)

            scheme = resolve_color_scheme(env)
            nonce = resolve_csp_nonce(env, body)
            injection = build_injection(scheme, nonce)

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
            body[%r{<meta name="csp-nonce" content="([A-Za-z0-9+/=\-_]+)"}, 1]
        end

        # Determine whether the response should receive theme injection.
        #
        # @param status [Integer] HTTP response status code
        # @param headers [Hash] HTTP response headers
        # @return [Boolean]
        def inject_theme?(status, headers)
          status == 200 && headers["content-type"]&.include?("text/html")
        end

        def build_injection(color_scheme, nonce)
          auto = color_scheme == :auto
          schemes = auto ? Configuration::COLOR_SCHEMES : [color_scheme]

          # Theme stylesheets
          parts =
            schemes.map do |scheme|
              stylesheet_tag(asset_path("mission_control/theme/#{@theme}_#{scheme}.min.css"), scheme: (scheme if auto))
            end

          # Prism.js syntax highlighting (CSS + JS)
          syntax_highlighting_tags(schemes, auto:, nonce:, into: parts) if @syntax_highlighting

          # Client-side color scheme switcher (auto / light / dark)
          parts << color_scheme_switcher_tag(nonce) if @color_scheme_switcher

          "#{parts.join("\n")}</head>"
        end

        def syntax_highlighting_tags(schemes, auto:, nonce:, into:)
          schemes.each do |scheme|
            prism_theme = scheme == :dark ? "tomorrow" : "default"
            href = asset_path("mission_control/theme/prism.#{prism_theme}.min.css")
            into << stylesheet_tag(href, scheme: (scheme if auto))
          end
          into << script_tag(asset_path("mission_control/theme/prism.min.js"), nonce:, extra: "data-manual")
          into << script_tag(asset_path("mission_control/theme/prism-init.js"), nonce:)
        end

        def script_tag(src, nonce:, extra: nil)
          extra_attrs = extra ? " #{extra}" : ""
          nonce_attr = nonce ? %( nonce="#{nonce}") : ""
          %(<script src="#{src}"#{extra_attrs}#{nonce_attr}></script>)
        end

        def stylesheet_tag(href, scheme: nil)
          media_attr = %( media="(prefers-color-scheme: #{scheme})") if scheme
          %(<link rel="stylesheet" href="#{href}"#{media_attr}>)
        end

        def color_scheme_switcher_tag(nonce)
          script_tag(
            asset_path("mission_control/theme/color-scheme-switcher.js"),
            nonce:,
            extra: "data-default-color-scheme=\"#{@default_color_scheme}\" " \
                   "data-cookie-name=\"#{Configuration::COOKIE_NAME}\""
          )
        end

        def asset_path(logical_path)
          ActionController::Base.helpers.asset_path(logical_path)
        end
      end
    end
  end
end
