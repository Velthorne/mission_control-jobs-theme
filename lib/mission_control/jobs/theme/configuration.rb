# frozen_string_literal: true

module MissionControl
  module Jobs
    module Theme
      # Hold user-configurable options for the theme middleware.
      #
      # @see Theme.configure
      class Configuration
        # @return [String, nil] override the auto-discovered engine mount path
        #   (e.g. +"/admin/jobs"+). When +nil+, {RouteDiscovery} detects it at boot.
        attr_accessor :mount_path

        # @return [Boolean] whether to inject Prism.js syntax highlighting for
        #   JSON payloads (default: +true+)
        attr_accessor :syntax_highlighting

        def initialize
          @mount_path = nil
          @syntax_highlighting = true
        end
      end
    end
  end
end
