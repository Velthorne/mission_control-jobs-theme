# frozen_string_literal: true

module MissionControl
  module Jobs
    unless defined?(MissionControl::Jobs::Engine)
      class Engine < ::Rails::Engine
        endpoint lambda { |_env|
          [200,
           { "content-type" => "text/html" },
           ["<!DOCTYPE html><html><head><title>MC</title></head><body>Jobs</body></html>"]]
        }
      end
    end
  end
end
