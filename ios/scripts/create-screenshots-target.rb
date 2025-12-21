#!/usr/bin/env ruby
#
# Creates the StillMoment-Screenshots target for screenshot automation
#
# Usage: ruby scripts/create-screenshots-target.rb
#
# This script:
# 1. Duplicates the StillMoment target
# 2. Renames it to StillMoment-Screenshots
# 3. Changes the bundle ID
# 4. Adds -D SCREENSHOTS_BUILD Swift flag
# 5. Adds StillMoment-Screenshots/ folder to the target
#

require 'xcodeproj'
require 'fileutils'

PROJECT_PATH = 'StillMoment.xcodeproj'
MAIN_TARGET_NAME = 'StillMoment'
SCREENSHOTS_TARGET_NAME = 'StillMoment-Screenshots'
SCREENSHOTS_BUNDLE_ID = 'com.stillmoment.StillMoment.screenshots'
SCREENSHOTS_FOLDER = 'StillMoment-Screenshots'

# Open project
project = Xcodeproj::Project.open(PROJECT_PATH)

# Check if target already exists
if project.targets.find { |t| t.name == SCREENSHOTS_TARGET_NAME }
  puts "Target '#{SCREENSHOTS_TARGET_NAME}' already exists. Skipping creation."
  exit 0
end

# Find main target
main_target = project.targets.find { |t| t.name == MAIN_TARGET_NAME }
unless main_target
  puts "ERROR: Could not find target '#{MAIN_TARGET_NAME}'"
  exit 1
end

puts "Creating #{SCREENSHOTS_TARGET_NAME} target..."

# Create new target by duplicating main target's configuration
screenshots_target = project.new_target(
  :application,
  SCREENSHOTS_TARGET_NAME,
  :ios,
  main_target.deployment_target
)

# Copy build configurations from main target
main_target.build_configurations.each do |main_config|
  screenshots_config = screenshots_target.build_configurations.find { |c| c.name == main_config.name }
  next unless screenshots_config

  # Copy all build settings
  main_config.build_settings.each do |key, value|
    screenshots_config.build_settings[key] = value
  end

  # Override specific settings
  screenshots_config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = SCREENSHOTS_BUNDLE_ID
  screenshots_config.build_settings['PRODUCT_NAME'] = SCREENSHOTS_TARGET_NAME
  screenshots_config.build_settings['INFOPLIST_FILE'] = main_config.build_settings['INFOPLIST_FILE']

  # Add SCREENSHOTS_BUILD Swift flag
  existing_flags = screenshots_config.build_settings['OTHER_SWIFT_FLAGS'] || '$(inherited)'
  unless existing_flags.include?('SCREENSHOTS_BUILD')
    screenshots_config.build_settings['OTHER_SWIFT_FLAGS'] = "#{existing_flags} -D SCREENSHOTS_BUILD"
  end
end

# Find or create Screenshots group
screenshots_group = project.main_group.find_subpath(SCREENSHOTS_FOLDER, false)
unless screenshots_group
  screenshots_group = project.main_group.new_group(SCREENSHOTS_FOLDER, SCREENSHOTS_FOLDER)
end

# Add all files from StillMoment-Screenshots folder
def add_files_recursively(group, path, target, project)
  Dir.foreach(path) do |entry|
    next if entry.start_with?('.')

    full_path = File.join(path, entry)

    if File.directory?(full_path)
      # Create subgroup
      subgroup = group.find_subpath(entry, false) || group.new_group(entry, entry)
      add_files_recursively(subgroup, full_path, target, project)
    else
      # Add file if not already in group
      unless group.files.find { |f| f.path == entry }
        file_ref = group.new_file(full_path)

        # Add to target's build phase based on file type
        if entry.end_with?('.swift')
          target.source_build_phase.add_file_reference(file_ref)
        elsif entry.end_with?('.mp3', '.m4a', '.wav')
          target.resources_build_phase.add_file_reference(file_ref)
        end
      end
    end
  end
end

# Add Screenshots folder files
if File.directory?(SCREENSHOTS_FOLDER)
  add_files_recursively(screenshots_group, SCREENSHOTS_FOLDER, screenshots_target, project)
  puts "Added files from #{SCREENSHOTS_FOLDER}/"
end

# Copy all source files from main target
main_target.source_build_phase.files.each do |build_file|
  file_ref = build_file.file_ref
  next unless file_ref

  # Skip if already added (from Screenshots folder)
  existing = screenshots_target.source_build_phase.files.find { |f| f.file_ref == file_ref }
  unless existing
    screenshots_target.source_build_phase.add_file_reference(file_ref)
  end
end

# Copy all resource files from main target
main_target.resources_build_phase.files.each do |build_file|
  file_ref = build_file.file_ref
  next unless file_ref

  existing = screenshots_target.resources_build_phase.files.find { |f| f.file_ref == file_ref }
  unless existing
    screenshots_target.resources_build_phase.add_file_reference(file_ref)
  end
end

# Copy framework dependencies
main_target.frameworks_build_phase.files.each do |build_file|
  file_ref = build_file.file_ref
  next unless file_ref

  existing = screenshots_target.frameworks_build_phase.files.find { |f| f.file_ref == file_ref }
  unless existing
    screenshots_target.frameworks_build_phase.add_file_reference(file_ref)
  end
end

# Save project
project.save

puts "Successfully created target '#{SCREENSHOTS_TARGET_NAME}'"
puts ""
puts "Next steps:"
puts "1. Open Xcode and verify the target"
puts "2. Check that a scheme was created (Product -> Scheme -> Manage Schemes)"
puts "3. Build and run: xcodebuild -scheme #{SCREENSHOTS_TARGET_NAME} -destination 'platform=iOS Simulator,name=iPhone 16'"
