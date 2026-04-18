# frozen_string_literal: true

require "bundler/gem_tasks"
require "pathname"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

namespace :assets do
  desc "Minify theme CSS and JS with esbuild"
  task :minify do
    minify_theme_assets
  end

  namespace :minify do
    desc "Fail if committed .min.* artifacts are stale"
    task :check do
      minify_theme_assets
      stale = `git status --porcelain ':(glob)app/assets/**/*.min.css' ':(glob)app/assets/**/*.min.js'`.strip
      abort "Minified assets are stale:\n#{stale}\nRun 'bundle exec rake assets:minify' and commit." unless stale.empty?
    end
  end
end

def minify_theme_assets
  esbuild = "./node_modules/.bin/esbuild"
  abort "esbuild missing — run 'npm ci' first" unless File.executable?(esbuild)

  minify_each("app/assets/stylesheets/mission_control/theme", ".css", esbuild)
  minify_each("app/assets/javascripts/mission_control/theme", ".js", esbuild)
end

def minify_each(dir, ext, bin)
  Dir.glob("#{dir}/*#{ext}").reject { |f| f.end_with?(".min#{ext}") }.each do |source|
    target = Pathname(source).sub_ext(".min#{ext}").to_s
    sh bin, source, "--minify", "--outfile=#{target}"
  end
end
