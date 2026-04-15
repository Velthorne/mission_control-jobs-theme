# frozen_string_literal: true

module MissionControl
  module Jobs
    module Theme
      # Wire theme assets and middleware into the Rails middleware stack.
      #
      # Inserts a {Rack::Static} instance to serve CSS, JS, and font assets with
      # immutable cache headers, then inserts {Middleware} to inject them into engine HTML
      # responses. The engine mount path is resolved via {RouteDiscovery} unless
      # explicitly configured.
      #
      # @see Configuration
      # @see Middleware
      # @see RouteDiscovery
      class Railtie < Rails::Railtie
        initializer "mission_control.jobs.theme.middleware", after: :load_config_initializers do |app|
          config = MissionControl::Jobs::Theme.configuration
          mount_path = config.mount_path || RouteDiscovery.discover(app.routes)

          app.middleware.use Rack::Static,
                             urls: %w[/mission_control/css /mission_control/js /mission_control/fonts],
                             root: File.join(Gem.loaded_specs["mission_control-jobs-theme"].gem_dir, "assets"),
                             header_rules: [[:all, { "cache-control" => "public, max-age=31536000, immutable" }]]

          app.middleware.use MissionControl::Jobs::Theme::Middleware,
                             mount_path:,
                             theme: config.theme,
                             syntax_highlighting: config.syntax_highlighting
        end
      end
    end
  end
end
