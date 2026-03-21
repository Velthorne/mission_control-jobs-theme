# frozen_string_literal: true

require "rails"
require "action_controller/railtie"
require "mission_control/jobs/theme"
require "mission_control/jobs/theme/railtie"
require_relative "../../stub_engine"

module Dummy
  class Application < Rails::Application
    config.eager_load = false
    config.logger = Logger.new(nil)

    routes.draw do
      mount MissionControl::Jobs::Engine, at: "/jobs"
    end
  end
end
