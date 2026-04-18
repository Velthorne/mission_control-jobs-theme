# frozen_string_literal: true

require_relative "../../../support/dummy/config/application"

RSpec.describe MissionControl::Jobs::Theme::Engine do
  before do
    Dummy::Application.initialize! unless Dummy::Application.initialized?
  end

  it "runs after load_config_initializers to respect user configuration" do
    theme_initializer =
      described_class.initializers.find do |initializer|
        initializer.name == "mission_control.jobs.theme.middleware"
      end

    expect(theme_initializer.after).to eq(:load_config_initializers)
  end

  it "auto-discovers the /jobs mount path from routes" do
    theme_middleware =
      Dummy::Application.middleware.detect do |middleware|
        middleware.klass == MissionControl::Jobs::Theme::Middleware
      end

    expect(theme_middleware.args).to include(hash_including(mount_path: "/jobs"))
  end
end
