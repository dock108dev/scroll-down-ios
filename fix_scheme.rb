#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'ScrollDown.xcodeproj'
project = Xcodeproj::Project.open(project_path)

app_target = project.targets.find { |t| t.name == 'ScrollDown' }
test_target = project.targets.find { |t| t.name == 'ScrollDownTests' }

# Fix: add product reference to app target if missing
if app_target.product_reference.nil?
  products_group = project.main_group.find_subpath('Products', false) || project.products_group
  app_product = products_group.new_reference('ScrollDown.app')
  app_product.explicit_file_type = 'wrapper.application'
  app_product.include_in_index = '0'
  app_product.source_tree = 'BUILT_PRODUCTS_DIR'
  app_target.product_reference = app_product
  project.save
  puts "Added product reference for ScrollDown.app"
end

# Now generate the scheme
scheme_path = "#{project_path}/xcshareddata/xcschemes/ScrollDown.xcscheme"
File.delete(scheme_path) if File.exist?(scheme_path)

scheme = Xcodeproj::XCScheme.new

# Build Action
scheme.build_action.parallelize_buildables = true
scheme.build_action.build_implicit_dependencies = true

entry = Xcodeproj::XCScheme::BuildAction::Entry.new(app_target)
entry.build_for_testing = true
entry.build_for_running = true
entry.build_for_profiling = true
entry.build_for_archiving = true
entry.build_for_analyzing = true
scheme.build_action.add_entry(entry)

# Test Action
scheme.test_action.build_configuration = 'Debug'
scheme.test_action.code_coverage_enabled = true

testable = Xcodeproj::XCScheme::TestAction::TestableReference.new(test_target)
testable.skipped = false
scheme.test_action.add_testable(testable)

# Launch Action
scheme.launch_action.build_configuration = 'Debug'
scheme.launch_action.buildable_product_runnable = Xcodeproj::XCScheme::BuildableProductRunnable.new(app_target)

# Profile Action
scheme.profile_action.build_configuration = 'Release'
scheme.profile_action.buildable_product_runnable = Xcodeproj::XCScheme::BuildableProductRunnable.new(app_target)

# Save
scheme.save_as(project_path, 'ScrollDown', true)

puts "Scheme regenerated successfully"
puts "Test target UUID: #{test_target.uuid}"
puts "App target UUID: #{app_target.uuid}"
