# frozen_string_literal: true

Dummy::Application.routes.draw do
  mount MissionControl::Jobs::Engine, at: "/jobs"
  get "/non_engine",
      to: lambda { |_env|
        [200, { "content-type" => "text/html" }, ["<!DOCTYPE html><html><head></head><body>Host</body></html>"]]
      }
end
