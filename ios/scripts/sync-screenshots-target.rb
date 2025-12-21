#!/usr/bin/env ruby
#
# Synchronizes the StillMoment-Screenshots target with the main StillMoment target
#
# Usage: ruby scripts/sync-screenshots-target.rb
#
# This script:
# 1. Finds all source files in StillMoment target
# 2. Adds missing files to StillMoment-Screenshots target
# 3. Ensures both targets have the same source files (except Screenshots-specific files)
#
# Run this script:
# - After adding new Swift files
# - As part of pre-commit hook
# - When Screenshots target build fails due to missing files
#

require 'xcodeproj'

# Support running from repo root or ios/ directory
SCRIPT_DIR = File.dirname(File.expand_path(__FILE__))
IOS_DIR = File.dirname(SCRIPT_DIR)
PROJECT_PATH = File.join(IOS_DIR, 'StillMoment.xcodeproj')
MAIN_TARGET_NAME = 'StillMoment'
SCREENSHOTS_TARGET_NAME = 'StillMoment-Screenshots'

# Open project
project = Xcodeproj::Project.open(PROJECT_PATH)

# Find targets
main_target = project.targets.find { |t| t.name == MAIN_TARGET_NAME }
screenshots_target = project.targets.find { |t| t.name == SCREENSHOTS_TARGET_NAME }

unless main_target
  puts "ERROR: Could not find target '#{MAIN_TARGET_NAME}'"
  exit 1
end

unless screenshots_target
  puts "ERROR: Could not find target '#{SCREENSHOTS_TARGET_NAME}'"
  puts "Run 'ruby scripts/create-screenshots-target.rb' first to create the target."
  exit 1
end

files_added = 0

# Sync source files
main_target.source_build_phase.files.each do |build_file|
  file_ref = build_file.file_ref
  next unless file_ref

  # Check if already in screenshots target
  existing = screenshots_target.source_build_phase.files.find { |f| f.file_ref == file_ref }
  unless existing
    screenshots_target.source_build_phase.add_file_reference(file_ref)
    files_added += 1
    puts "Added source: #{file_ref.path}" if ENV['VERBOSE']
  end
end

# Sync resource files
main_target.resources_build_phase.files.each do |build_file|
  file_ref = build_file.file_ref
  next unless file_ref

  existing = screenshots_target.resources_build_phase.files.find { |f| f.file_ref == file_ref }
  unless existing
    screenshots_target.resources_build_phase.add_file_reference(file_ref)
    files_added += 1
    puts "Added resource: #{file_ref.path}" if ENV['VERBOSE']
  end
end

# Sync framework dependencies
main_target.frameworks_build_phase.files.each do |build_file|
  file_ref = build_file.file_ref
  next unless file_ref

  existing = screenshots_target.frameworks_build_phase.files.find { |f| f.file_ref == file_ref }
  unless existing
    screenshots_target.frameworks_build_phase.add_file_reference(file_ref)
    files_added += 1
    puts "Added framework: #{file_ref.path}" if ENV['VERBOSE']
  end
end

if files_added > 0
  project.save
  puts "Synced #{files_added} file(s) to #{SCREENSHOTS_TARGET_NAME}"
else
  puts "Targets already in sync - no changes needed"
end
