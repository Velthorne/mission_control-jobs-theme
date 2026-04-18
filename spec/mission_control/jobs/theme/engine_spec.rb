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

  it "registers the theme middleware on MissionControl::Jobs::Engine.middleware" do
    MissionControl::Jobs::Engine.app # force lazy middleware stack build
    theme_entry =
      MissionControl::Jobs::Engine.middleware.middlewares
        .find { |m| m.klass == MissionControl::Jobs::Theme::Middleware }

    expect(theme_entry).not_to be_nil
    expect(theme_entry.args).to contain_exactly(
      hash_including(config: an_instance_of(MissionControl::Jobs::Theme::Configuration))
    )
  end
end
