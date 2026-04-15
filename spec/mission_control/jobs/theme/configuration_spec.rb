# frozen_string_literal: true

RSpec.describe MissionControl::Jobs::Theme::Configuration do
  subject(:config) { described_class.new }

  it "has sensible defaults" do
    expect(config.mount_path).to be_nil
    expect(config.syntax_highlighting).to be(true)
    expect(config.theme).to eq(:malachite_light)
  end

  it "allows overriding settings" do
    config.mount_path = "/admin/jobs"
    config.syntax_highlighting = false

    expect(config.mount_path).to eq("/admin/jobs")
    expect(config.syntax_highlighting).to be(false)
  end

  it "defines THEMES and DEFAULT_THEME constants" do
    expect(described_class::THEMES).to eq(%i[malachite_light malachite_dark])
    expect(described_class::THEMES).to be_frozen
    expect(described_class::DEFAULT_THEME).to eq(:malachite_light)
    expect(described_class::THEMES).to include(described_class::DEFAULT_THEME)
  end

  describe "#theme=" do
    it "accepts a registered theme as Symbol or String" do
      config.theme = "malachite_light"
      expect(config.theme).to eq(:malachite_light)

      config.theme = :malachite_dark
      expect(config.theme).to eq(:malachite_dark)
    end

    it "raises for an unknown theme" do
      expect { config.theme = :nonexistent }
        .to raise_error(MissionControl::Jobs::Theme::Error, /unknown theme :nonexistent/)
    end
  end

  describe "module-level DSL" do
    after { MissionControl::Jobs::Theme.reset_configuration! }

    it "returns the same memoized configuration instance" do
      first = MissionControl::Jobs::Theme.configuration
      second = MissionControl::Jobs::Theme.configuration

      expect(first).to be(second)
    end

    it "yields configuration to the configure block" do
      MissionControl::Jobs::Theme.configure { |c| c.mount_path = "/custom" }

      expect(MissionControl::Jobs::Theme.configuration.mount_path).to eq("/custom")
    end

    it "resets configuration to defaults via reset_configuration!" do
      MissionControl::Jobs::Theme.configure { |c| c.mount_path = "/custom" }
      MissionControl::Jobs::Theme.reset_configuration!

      expect(MissionControl::Jobs::Theme.configuration.mount_path).to be_nil
    end
  end
end
