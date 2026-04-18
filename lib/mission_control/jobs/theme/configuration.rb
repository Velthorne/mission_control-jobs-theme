# frozen_string_literal: true

module MissionControl
  module Jobs
    module Theme
      # Hold user-configurable options for the theme middleware.
      #
      # @see Theme.configure
      class Configuration
        # Available theme families. Each entry must have matching
        # +{name}_light.min.css+ and +{name}_dark.min.css+ files under
        # +app/assets/stylesheets/mission_control/theme/+.
        THEMES = %i[malachite].freeze

        COLOR_SCHEMES = %i[light dark].freeze
        COOKIE_NAME = "mc_jobs_color_scheme"
        DEFAULT_THEME = :malachite
        DEFAULT_COLOR_SCHEME = :auto

        # @return [Symbol] the active color scheme (+:auto+, +:light+, or +:dark+).
        #   +:auto+ injects both light and dark stylesheets with
        #   +prefers-color-scheme+ media queries so the browser picks the one
        #   matching the OS preference.
        attr_reader :color_scheme

        # @return [Boolean] whether to inject the color scheme switcher UI control
        #   (default: +true+)
        attr_accessor :color_scheme_switcher

        # @return [Boolean] whether to inject Prism.js syntax highlighting for
        #   JSON payloads (default: +true+)
        attr_accessor :syntax_highlighting

        # @return [Symbol] the active theme family (must be listed in {THEMES})
        attr_reader :theme

        def initialize
          @color_scheme = DEFAULT_COLOR_SCHEME
          @color_scheme_switcher = true
          @syntax_highlighting = true
          @theme = DEFAULT_THEME
        end

        # Set the color scheme preference, validating it against {COLOR_SCHEMES}
        # or +:auto+.
        #
        # @param value [Symbol, String] color scheme (converted to Symbol)
        # @raise [MissionControl::Jobs::Theme::Error] if the color scheme is not recognized
        # @return [Symbol] the assigned color scheme
        def color_scheme=(value)
          value = value&.to_sym

          unless value == :auto || COLOR_SCHEMES.include?(value)
            available = ([:auto] + COLOR_SCHEMES).map(&:inspect).join(", ")
            raise MissionControl::Jobs::Theme::Error,
                  "unknown color scheme #{value.inspect}; available: #{available}"
          end

          @color_scheme = value
        end

        # Set the active theme family, validating it against {THEMES}.
        #
        # @param value [Symbol, String] theme family identifier (converted to Symbol)
        # @raise [MissionControl::Jobs::Theme::Error] if the theme is not recognized
        # @return [Symbol] the assigned theme family
        def theme=(value)
          value = value&.to_sym

          unless THEMES.include?(value)
            raise MissionControl::Jobs::Theme::Error,
                  "unknown theme #{value.inspect}; available: #{THEMES.join(", ")}"
          end

          @theme = value
        end
      end
    end
  end
end
