# frozen_string_literal: true

require_relative "theme/version"
require_relative "theme/configuration"
require_relative "theme/middleware"
require_relative "theme/route_discovery"

module MissionControl
  module Jobs
    # Inject a custom CSS theme and optional syntax highlighting into the
    # Mission Control Jobs dashboard.
    #
    # Provides a configuration DSL and Rack middleware that rewrites HTML
    # responses served by {MissionControl::Jobs::Engine}.
    #
    # @see Configuration
    # @see Middleware
    # @see Engine
    #
    # @example Configure in an initializer
    #   MissionControl::Jobs::Theme.configure do |config|
    #     config.theme = :malachite
    #     config.color_scheme = :auto
    #     config.mount_path = "/admin/jobs"
    #     config.syntax_highlighting = false
    #   end
    module Theme
      class Error < StandardError; end

      # @yield [config] the mutable configuration instance
      # @yieldparam config [Configuration] current configuration
      # @return [void]
      def self.configure
        yield(configuration)
      end

      # @return [Configuration] the current (lazily-initialized) configuration instance
      def self.configuration
        @configuration ||= Configuration.new
      end

      # @return [Configuration] the fresh configuration instance
      def self.reset_configuration!
        @configuration = Configuration.new
      end
    end
  end
end

require_relative "theme/engine" if defined?(Rails::Engine)
