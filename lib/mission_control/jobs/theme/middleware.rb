# frozen_string_literal: true

module MissionControl
  module Jobs
    module Theme
      # Intercept HTML responses from the Mission Control Jobs engine and inject
      # theme CSS and optional Prism.js syntax highlighting before +</head>+.
      #
      # Only rewrites responses that match the engine mount path and have an
      # +text/html+ content type.
      #
      # @see Railtie
      # @see RouteDiscovery
      #
      # @example Manual Rack usage (typically wired by {Railtie})
      #   use MissionControl::Jobs::Theme::Middleware,
      #       mount_path: "/admin/jobs",
      #       theme: :malachite_light,
      #       syntax_highlighting: true
      class Middleware
        PRISM_JS   = '<script src="/mission_control/js/prism.min.js" data-manual></script>'
        PRISM_INIT = '<script src="/mission_control/js/prism-init.js"></script>'

        # @param app [#call] the next Rack application in the middleware stack
        # @param mount_path [String] engine mount path to match against requests
        # @param theme [Symbol] theme identifier used to resolve the CSS filename
        # @param syntax_highlighting [Boolean] inject Prism.js assets when +true+
        def initialize(app, mount_path: RouteDiscovery::FALLBACK,
                       theme: Configuration::DEFAULT_THEME, syntax_highlighting: true)
          @app = app
          @mount_path = mount_path
          @mount_path_prefix = "#{mount_path}/"
          @injection = build_injection(theme, syntax_highlighting)
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

            body = inject_assets(body)
            headers["content-length"] = body.bytesize.to_s if headers.key?("content-length")

            [status, headers, [body]]
          else
            [status, headers, response]
          end
        end

        private

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

        def inject_assets(body)
          body.sub!("</head>", @injection)
          body
        end

        def theme_css(theme)
          %(<link rel="stylesheet" href="/mission_control/css/#{theme}.min.css">)
        end

        def prism_css(theme)
          file = theme.to_s.end_with?("_dark") ? "prism.tomorrow.min.css" : "prism.default.min.css"
          %(<link rel="stylesheet" href="/mission_control/css/#{file}">)
        end

        def build_injection(theme, syntax_highlighting)
          parts =
            if syntax_highlighting
              [prism_css(theme), theme_css(theme), PRISM_JS, PRISM_INIT]
            else
              [theme_css(theme)]
            end
          "#{parts.join("\n")}</head>".freeze
        end
      end
    end
  end
end
