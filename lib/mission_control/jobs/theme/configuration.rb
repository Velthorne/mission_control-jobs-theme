# frozen_string_literal: true

module MissionControl
  module Jobs
    module Theme
      # Hold user-configurable options for the theme middleware.
      #
      # @see Theme.configure
      class Configuration
        # Available theme identifiers. Each entry must have a matching
        # +{name}.min.css+ file under +assets/mission_control/css/+.
        THEMES = %i[malachite_light malachite_dark].freeze

        # @return [Symbol] the theme applied when none is explicitly configured.
        #   +:auto+ injects both light and dark stylesheets with
        #   +prefers-color-scheme+ media queries so the browser picks the one
        #   matching the OS preference.
        DEFAULT_THEME = :auto

        # @return [String, nil] override the auto-discovered engine mount path
        #   (e.g. +"/admin/jobs"+). When +nil+, {RouteDiscovery} detects it at boot.
        attr_accessor :mount_path

        # @return [Boolean] whether to inject Prism.js syntax highlighting for
        #   JSON payloads (default: +true+)
        attr_accessor :syntax_highlighting

        # @return [Symbol] the active theme name (must be listed in {THEMES}),
        #   or +:auto+ to follow OS color preference
        attr_reader :theme

        def initialize
          @mount_path = nil
          @syntax_highlighting = true
          @theme = DEFAULT_THEME
        end

        # Set the active theme, validating it against {THEMES} or +:auto+.
        #
        # @param value [Symbol, String] theme identifier (converted to Symbol)
        # @raise [MissionControl::Jobs::Theme::Error] if the theme is not recognized
        def theme=(value)
          value = value.to_sym

          unless value == :auto || THEMES.include?(value)
            raise MissionControl::Jobs::Theme::Error,
                  "unknown theme #{value.inspect}; available: :auto, #{THEMES.join(", ")}"
          end

          @theme = value
        end
      end
    end
  end
end
