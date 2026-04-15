# frozen_string_literal: true

require_relative "lib/mission_control/jobs/theme/version"

Gem::Specification.new do |spec|
  spec.name = "mission_control-jobs-theme"
  spec.version = MissionControl::Jobs::Theme::VERSION
  spec.authors = ["Łukasz Tackowiak"]
  spec.email = ["contact@velthorne.dev"]

  spec.summary = "A polished visual theme for the mission_control-jobs dashboard"
  spec.description = "Drop-in theme that refreshes the MissionControl::Jobs UI with refined " \
                     "typography, a malachite color palette, and JSON syntax highlighting. " \
                     "Zero configuration — works via Rack middleware without overriding views."
  spec.homepage = "https://github.com/Velthorne/mission_control-jobs-theme"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["documentation_uri"] = "#{spec.homepage}/blob/main/README.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files =
    IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
      ls.readlines("\x0", chomp: true).reject do |f|
        (f == gemspec) ||
          f.start_with?(*%w[bin/ test/ spec/ features/ docs/ .git .rspec .rubocop appveyor Gemfile Rakefile]) ||
          (f.start_with?("assets/mission_control/css/") && f.end_with?(".css") && !f.end_with?(".min.css"))
      end
    end
  spec.require_paths = ["lib"]

  spec.add_dependency "mission_control-jobs", "~> 1.1"
  spec.add_dependency "railties", ">= 7.1", "< 9"
end
