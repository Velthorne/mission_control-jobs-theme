# frozen_string_literal: true

module MissionControl
  module Jobs
    module Theme
      # Wire theme middleware into the Rails middleware stack.
      #
      # Inserts {Middleware} after +:load_config_initializers+ so it can inject
      # asset links into engine HTML responses. The mount path is resolved via
      # {RouteDiscovery} unless explicitly configured. Theme assets ship through
      # Propshaft (or Sprockets) via the standard +app/assets/+ and
      # +vendor/assets/+ conventions — this Engine's asset paths are picked up
      # automatically by the asset pipeline.
      #
      # @see Configuration
      # @see Middleware
      # @see RouteDiscovery
      class Engine < ::Rails::Engine
        initializer "mission_control.jobs.theme.middleware", after: :load_config_initializers do |app|
          config = MissionControl::Jobs::Theme.configuration
          mount_path = config.mount_path || RouteDiscovery.discover(app.routes)

          app.middleware.use MissionControl::Jobs::Theme::Middleware, mount_path:, config:
        end
      end
    end
  end
end
