# frozen_string_literal: true

require "spec_helper"
require "rails/generators"
require "generators/mission_control/jobs/theme/install/install_generator"
require "tmpdir"

RSpec.describe MissionControl::Jobs::Theme::InstallGenerator do
  it "creates the initializer with configure block and both options commented out" do
    Dir.mktmpdir do |tmpdir|
      described_class.start([], destination_root: tmpdir)
      content = File.read(File.join(tmpdir, "config/initializers/mission_control_jobs_theme.rb"))

      expect(content).to include("MissionControl::Jobs::Theme.configure")
      expect(content).to include("# config.color_scheme =", "# config.color_scheme_switcher",
                                 "# config.syntax_highlighting", "# config.theme")
    end
  end
end
