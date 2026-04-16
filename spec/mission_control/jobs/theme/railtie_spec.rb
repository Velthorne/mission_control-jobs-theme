# frozen_string_literal: true

require_relative "../../../support/dummy/config/application"

RSpec.describe MissionControl::Jobs::Theme::Railtie do
  before do
    Dummy::Application.initialize! unless Dummy::Application.initialized?
  end

  it "inserts Rack::Static before Theme::Middleware in the middleware stack" do
    middleware_classes = Dummy::Application.middleware.map(&:klass)
    static_index = middleware_classes.index(Rack::Static)
    theme_index = middleware_classes.index(MissionControl::Jobs::Theme::Middleware)

    expect(static_index).to be < theme_index
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

    expect(theme_middleware.args).to include(hash_including(mount_path: "/jobs", theme: :auto))
  end
end
