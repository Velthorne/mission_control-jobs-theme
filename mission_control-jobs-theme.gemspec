# frozen_string_literal: true

require_relative "lib/mission_control/jobs/theme/version"

Gem::Specification.new do |spec|
  spec.name = "mission_control-jobs-theme"
  spec.version = MissionControl::Jobs::Theme::VERSION
  spec.authors = ["Łukasz Tackowiak"]
  spec.email = ["contact@velthorne.dev"]

  spec.summary = "Emerald theme for mission_control-jobs"
  spec.description = "CSS reskin and PrismJS syntax highlighting for the MissionControl Jobs UI. " \
                     "Drop-in Rack middleware with zero-config Rails integration via Railtie."
  spec.homepage = "https://github.com/Velthorne/mission_control-jobs-theme"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files =
    IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
      ls.readlines("\x0", chomp: true).reject do |f|
        (f == gemspec) ||
          f.start_with?(*%w[bin/ test/ spec/ features/ docs/ .git appveyor Gemfile])
      end
    end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "mission_control-jobs", ">= 1.1"
  spec.add_dependency "rack", ">= 2.0"
  spec.add_dependency "railties", ">= 8.1"
end
