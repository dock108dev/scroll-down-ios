#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'ScrollDown.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main app target
app_target = project.targets.find { |t| t.name == 'ScrollDown' }

# Remove DEPLOYMENT_LOCATION from app Debug config (breaks test host resolution)
app_target.build_configurations.each do |config|
  config.build_settings.delete('DEPLOYMENT_LOCATION')
end

# Create the test target
test_target = project.new_target(
  :unit_test_bundle,
  'ScrollDownTests',
  :ios,
  '17.6'
)

# Set test host dependency
test_target.add_dependency(app_target)

# Configure build settings for both Debug and Release
test_target.build_configurations.each do |config|
  config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
  config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/ScrollDown.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/ScrollDown'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.scrolldown.ScrollDownTests'
  config.build_settings['DEVELOPMENT_TEAM'] = 'E3G5D247ZN'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['SUPPORTED_PLATFORMS'] = 'iphoneos iphonesimulator'
  config.build_settings['SUPPORTS_MACCATALYST'] = 'NO'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  config.build_settings['SWIFT_EMIT_LOC_STRINGS'] = 'NO'
end

# Find or create the Tests group
scrolldown_group = project.main_group.find_subpath('ScrollDown', false)
tests_group = scrolldown_group.new_group('Tests', 'Tests')
helpers_group = tests_group.new_group('Helpers', 'Helpers')

# Test files in ScrollDown/Tests/
test_files = %w[
  ModelDecodingTests.swift
  GameDetailViewModelTests.swift
  OddsCalculatorTests.swift
  EVCalculatorTests.swift
  AmericanOddsTests.swift
  BetPairingTests.swift
  FairOddsCalculatorTests.swift
  SharpBookConfigTests.swift
  GameSummaryTests.swift
  GameModelTests.swift
  EnumsTests.swift
  SocialPostTests.swift
  GameFlowModelTests.swift
  FlowAdapterTests.swift
  HomeGameCacheTests.swift
  MockLoaderTests.swift
  AppDateTests.swift
]

# Helper files in ScrollDown/Tests/Helpers/
helper_files = %w[
  TestFixtures.swift
]

# Add test files to group and target
test_files.each do |filename|
  file_ref = tests_group.new_reference(filename)
  test_target.source_build_phase.add_file_reference(file_ref)
end

helper_files.each do |filename|
  file_ref = helpers_group.new_reference(filename)
  test_target.source_build_phase.add_file_reference(file_ref)
end

# Save the project
project.save

puts "Successfully added ScrollDownTests target with #{test_files.count + helper_files.count} test files"
puts "Removed DEPLOYMENT_LOCATION from app build configurations"
