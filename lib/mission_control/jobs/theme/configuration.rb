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

        # @return [Symbol] the theme applied when none is explicitly configured
        DEFAULT_THEME = :malachite_light

        # @return [String, nil] override the auto-discovered engine mount path
        #   (e.g. +"/admin/jobs"+). When +nil+, {RouteDiscovery} detects it at boot.
        attr_accessor :mount_path

        # @return [Boolean] whether to inject Prism.js syntax highlighting for
        #   JSON payloads (default: +true+)
        attr_accessor :syntax_highlighting

        # @return [Symbol] the active theme name (must be listed in {THEMES})
        attr_reader :theme

        def initialize
          @mount_path = nil
          @syntax_highlighting = true
          @theme = DEFAULT_THEME
        end

        # Set the active theme, validating it against {THEMES}.
        #
        # @param value [Symbol, String] theme identifier (converted to Symbol)
        # @raise [MissionControl::Jobs::Theme::Error] if the theme is not in {THEMES}
        def theme=(value)
          value = value.to_sym

          unless THEMES.include?(value)
            raise MissionControl::Jobs::Theme::Error,
                  "unknown theme #{value.inspect}; available themes: #{THEMES.join(", ")}"
          end

          @theme = value
        end
      end
    end
  end
end
