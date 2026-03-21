# frozen_string_literal: true

module MissionControl
  module Jobs
    unless defined?(MissionControl::Jobs::Engine)
      class Engine < Rails::Engine
      end
    end
  end
end
