# frozen_string_literal: true

module MissionControl
  module Jobs
    module Theme
      # Wire theme middleware into the Mission Control Jobs engine stack.
      #
      # Inserts {Middleware} directly onto +MissionControl::Jobs::Engine+'s
      # internal middleware stack so it runs exclusively for requests the Rails
      # router dispatches to that engine. No path matching is performed here —
      # Rails owns that determination, which makes the middleware correct under
      # sub-URI deployments and for any host-app mount path.
      #
      # Theme assets ship through Propshaft (or Sprockets) via the standard
      # +app/assets/+ and +vendor/assets/+ conventions — this Engine's asset
      # paths are picked up automatically by the asset pipeline.
      #
      # @see Configuration
      # @see Middleware
      class Engine < ::Rails::Engine
        initializer "mission_control.jobs.theme.middleware", after: :load_config_initializers do
          MissionControl::Jobs::Engine.middleware.use(
            MissionControl::Jobs::Theme::Middleware,
            config: MissionControl::Jobs::Theme.configuration
          )
        end
      end
    end
  end
end
