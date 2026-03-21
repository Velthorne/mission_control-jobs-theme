# frozen_string_literal: true

module MissionControl
  module Jobs
    module Theme
      # Detect where {MissionControl::Jobs::Engine} is mounted by inspecting
      # the Rails route table at boot time.
      #
      # Falls back to {FALLBACK} when the engine is not loaded or no matching
      # route is found.
      #
      # @see Railtie
      module RouteDiscovery
        FALLBACK = "/jobs"

        # Inspect the application route set for a mounted Mission Control Jobs
        # engine and return its path prefix.
        #
        # @param routes [ActionDispatch::Routing::RouteSet] the application route set
        # @return [String] the engine mount path, or {FALLBACK} if not found
        #
        # @example
        #   RouteDiscovery.discover(Rails.application.routes) #=> "/admin/jobs"
        def self.discover(routes)
          engine = defined?(MissionControl::Jobs::Engine) ? MissionControl::Jobs::Engine : nil
          return FALLBACK unless engine

          routes.routes.each do |route|
            mounted_app = route.app&.app
            next unless mounted_app == engine

            return route.path.spec.to_s.chomp("(.:format)").delete_suffix("/")
          rescue NoMethodError
            next
          end

          FALLBACK
        end
      end
    end
  end
end
