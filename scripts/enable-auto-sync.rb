#!/usr/bin/env ruby
#
# Converts MediTimer folder to PBXFileSystemSynchronizedRootGroup
# This enables automatic file detection in Xcode 15+
#

require 'xcodeproj'

PROJECT_PATH = 'MediTimer.xcodeproj'

puts "🔄 Converting MediTimer to auto-sync folder..."
puts ""

project = Xcodeproj::Project.open(PROJECT_PATH)

# Find the MediTimer group
meditimer_group = project.main_group.children.find { |c| c.display_name == 'MediTimer' }

if meditimer_group.nil?
  puts "❌ Error: MediTimer group not found"
  exit 1
end

# Check if it's already a synchronized group
if meditimer_group.is_a?(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
  puts "✅ MediTimer is already auto-synced!"
  exit 0
end

puts "Current type: #{meditimer_group.class.name}"
puts ""

# Find the main target
target = project.targets.find { |t| t.name == 'MediTimer' }

if target.nil?
  puts "❌ Error: MediTimer target not found"
  exit 1
end

# Remove the old group
old_uuid = meditimer_group.uuid
project.main_group.children.delete(meditimer_group)

# Create new synchronized root group
new_group = project.main_group.new_file_system_synchronized_root_group('MediTimer')
new_group.path = 'MediTimer'
new_group.source_tree = '<group>'

puts "✅ Converted MediTimer to PBXFileSystemSynchronizedRootGroup"
puts ""
puts "📝 What this means:"
puts "  • New Swift files in MediTimer/ are automatically detected"
puts "  • No need to manually add files to Xcode"
puts "  • No need to run sync scripts"
puts ""

# Save project
project.save

puts "✅ Project saved!"
puts ""
puts "⚠️  IMPORTANT:"
puts "  1. Close Xcode completely"
puts "  2. Reopen MediTimer.xcodeproj"
puts "  3. Clean build folder (⌘+Shift+K)"
puts "  4. Build (⌘+B)"
puts ""
puts "  If you see issues, you may need to manually configure the synchronized folder in Xcode:"
puts "  - Right-click MediTimer folder → Add Files to MediTimer"
puts "  - Select MediTimer folder → Options: Create folder references"
