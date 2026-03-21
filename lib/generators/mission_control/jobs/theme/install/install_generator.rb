# frozen_string_literal: true

module MissionControl
  module Jobs
    module Theme
      # Scaffold an initializer with default {Configuration} options.
      #
      # @example
      #   bin/rails generate mission_control:jobs:theme:install
      class InstallGenerator < Rails::Generators::Base
        source_root File.expand_path("templates", __dir__)
        desc "Creates a MissionControl::Jobs::Theme initializer"

        def copy_initializer
          template "initializer.rb.tt", "config/initializers/mission_control_jobs_theme.rb"
        end
      end
    end
  end
end
