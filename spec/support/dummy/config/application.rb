# frozen_string_literal: true

require "rails"
require "action_controller/railtie"
require "propshaft"
require "mission_control/jobs/theme"
require "mission_control/jobs/theme/engine"
require_relative "../../stub_engine"

module Dummy
  class Application < Rails::Application
    config.eager_load = false
    config.logger = Logger.new(nil)
    config.root = File.expand_path("..", __dir__)

    routes.draw do
      mount MissionControl::Jobs::Engine, at: "/jobs"
    end
  end
end
