# frozen_string_literal: true

RSpec.describe MissionControl::Jobs::Theme::Configuration do
  subject(:config) { described_class.new }

  it "has sensible defaults" do
    expect(config.mount_path).to be_nil
    expect(config.syntax_highlighting).to be(true)
    expect(config.color_scheme_switcher).to be(true)
    expect(config.theme).to eq(:malachite)
    expect(config.color_scheme).to eq(:auto)
  end

  it "allows overriding settings" do
    config.mount_path = "/admin/jobs"
    config.syntax_highlighting = false
    config.color_scheme_switcher = false

    expect(config.mount_path).to eq("/admin/jobs")
    expect(config.syntax_highlighting).to be(false)
    expect(config.color_scheme_switcher).to be(false)
  end

  it "defines constants" do
    expect(described_class::THEMES).to eq(%i[malachite])
    expect(described_class::THEMES).to be_frozen
    expect(described_class::COLOR_SCHEMES).to eq(%i[light dark])
    expect(described_class::COLOR_SCHEMES).to be_frozen
    expect(described_class::DEFAULT_THEME).to eq(:malachite)
    expect(described_class::DEFAULT_COLOR_SCHEME).to eq(:auto)
    expect(described_class::COOKIE_NAME).to eq("mc_jobs_color_scheme")
  end

  describe "#theme=" do
    it "accepts a registered theme as Symbol or String" do
      config.theme = :malachite
      expect(config.theme).to eq(:malachite)

      config.theme = "malachite"
      expect(config.theme).to eq(:malachite)
    end

    it "raises for an unknown theme" do
      expect { config.theme = :nonexistent }
        .to raise_error(MissionControl::Jobs::Theme::Error, /unknown theme :nonexistent/)
    end

    it "raises for nil" do
      expect { config.theme = nil }
        .to raise_error(MissionControl::Jobs::Theme::Error, /unknown theme nil/)
    end
  end

  describe "#color_scheme=" do
    it "accepts :auto, :light, or :dark as Symbol or String" do
      config.color_scheme = :auto
      expect(config.color_scheme).to eq(:auto)

      config.color_scheme = "light"
      expect(config.color_scheme).to eq(:light)

      config.color_scheme = :dark
      expect(config.color_scheme).to eq(:dark)
    end

    it "raises for an unknown color scheme" do
      expect { config.color_scheme = :nonexistent }
        .to raise_error(MissionControl::Jobs::Theme::Error, /unknown color scheme :nonexistent/)
    end

    it "raises for nil" do
      expect { config.color_scheme = nil }
        .to raise_error(MissionControl::Jobs::Theme::Error, /unknown color scheme nil/)
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
