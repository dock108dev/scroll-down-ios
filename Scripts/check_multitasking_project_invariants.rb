#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"
require "yaml"

ROOT_DIR = File.expand_path("..", __dir__)
INFO_PLIST = File.join(ROOT_DIR, "ScrollDownSports/Resources/Info.plist")
PROJECT_YML = File.join(ROOT_DIR, "project.yml")
APP_ENTRY = File.join(ROOT_DIR, "ScrollDownSports/App/ScrollDownSportsApp.swift")

IPHONE_ORIENTATIONS = %w[
  UIInterfaceOrientationPortrait
  UIInterfaceOrientationLandscapeLeft
  UIInterfaceOrientationLandscapeRight
].freeze

IPAD_ORIENTATIONS = %w[
  UIInterfaceOrientationPortrait
  UIInterfaceOrientationPortraitUpsideDown
  UIInterfaceOrientationLandscapeLeft
  UIInterfaceOrientationLandscapeRight
].freeze

def fail_check(message)
  warn "Multitasking invariant failed: #{message}"
  exit 1
end

def run_json_plutil(path)
  stdout, stderr, status = Open3.capture3("plutil", "-convert", "json", "-o", "-", path)
  fail_check("could not read #{path}: #{stderr.strip}") unless status.success?

  JSON.parse(stdout)
rescue JSON::ParserError => error
  fail_check("could not parse #{path} as JSON plist: #{error.message}")
end

def assert_equal_array(actual, expected, label)
  fail_check("#{label} missing") unless actual.is_a?(Array)
  return if actual == expected

  fail_check("#{label} expected #{expected.inspect}, got #{actual.inspect}")
end

def version_parts(version)
  parts = version.to_s.split(".").map { |part| Integer(part, 10) }
  [parts[0] || 0, parts[1] || 0, *parts.drop(2)]
rescue ArgumentError
  fail_check("iOS deployment target is not a dotted numeric version: #{version.inspect}")
end

def assert_contains(source, snippet, label)
  return if source.include?(snippet)

  fail_check("#{label} missing from #{APP_ENTRY}")
end

info = run_json_plutil(INFO_PLIST)
fail_check("Info.plist must not declare UIRequiresFullScreen") if info.key?("UIRequiresFullScreen")
assert_equal_array(
  info["UISupportedInterfaceOrientations"],
  IPHONE_ORIENTATIONS,
  "iPhone supported orientations"
)
assert_equal_array(
  info["UISupportedInterfaceOrientations~ipad"],
  IPAD_ORIENTATIONS,
  "iPad supported orientations"
)

project = YAML.load_file(PROJECT_YML)
targets = project.fetch("targets") { fail_check("project.yml has no targets") }
app_targets = targets.select { |_name, config| config["type"] == "application" }
fail_check("project.yml must define exactly one application target") unless app_targets.size == 1
app_name, app_config = app_targets.first
fail_check("application target must remain ScrollDownSports") unless app_name == "ScrollDownSports"
fail_check("application target must remain platform iOS") unless app_config["platform"] == "iOS"

target_names = targets.keys
forked_targets = target_names.grep(/ipad|catalyst|macos|mac catalyst/i)
fail_check("device-specific or Catalyst target fork found: #{forked_targets.join(", ")}") unless forked_targets.empty?

non_ios_targets = targets.select { |_name, config| config["platform"] != "iOS" }
fail_check("all targets must stay on platform iOS: #{non_ios_targets.keys.join(", ")}") unless non_ios_targets.empty?

deployment_target = project.dig("options", "deploymentTarget", "iOS")
fail_check("project.yml must declare an iOS deployment target") if deployment_target.nil?
fail_check("iOS deployment target must be 18.0 or newer") if (version_parts(deployment_target) <=> [18, 0]).negative?

app_source = File.read(APP_ENTRY)
window_group_count = app_source.scan(/\bWindowGroup\b/).size
fail_check("app entry must declare exactly one WindowGroup") unless window_group_count == 1
assert_contains(app_source, "private let gameStateStore: any GameStateStore", "shared game state store")
assert_contains(app_source, "BackgroundDataScheduler.shared.gameStateStore = gameStateStore", "app-wide scheduler store assignment")
assert_contains(app_source, "ContentView(gameStateStore: gameStateStore)", "WindowGroup shared store injection")
assert_contains(app_source, "@Environment(\\.scenePhase) private var scenePhase", "app-wide scene phase environment")
assert_contains(app_source, ".onChange(of: scenePhase)", "scene phase handler")
assert_contains(app_source, "scheduler: BackgroundDataScheduler.shared", "app-wide background scheduler")

puts "Multitasking project invariants passed."
