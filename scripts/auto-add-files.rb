#!/usr/bin/env ruby
#
# Automatically adds new Swift files from the MediTimer directory to Xcode project
# Run this script whenever you add new files to auto-add them to the project
#

require 'xcodeproj'

PROJECT_PATH = 'MediTimer.xcodeproj'
SOURCE_DIR = 'MediTimer'
TEST_DIR = 'MediTimerTests'
UI_TEST_DIR = 'MediTimerUITests'

project = Xcodeproj::Project.open(PROJECT_PATH)

# Find targets
main_target = project.targets.find { |t| t.name == 'MediTimer' }
test_target = project.targets.find { |t| t.name == 'MediTimerTests' }
ui_test_target = project.targets.find { |t| t.name == 'MediTimerUITests' }

def add_files_recursively(project, group, folder_path, target, parent_path = '')
  added_count = 0

  Dir.foreach(folder_path) do |item|
    next if item == '.' || item == '..'

    full_path = File.join(folder_path, item)
    relative_path = File.join(parent_path, item)

    if File.directory?(full_path)
      # Create group if it doesn't exist
      subgroup = group[item] || group.new_group(item, relative_path)
      added_count += add_files_recursively(project, subgroup, full_path, target, relative_path)
    elsif item.end_with?('.swift')
      # Check if file already exists in project
      existing_file = group.files.find { |f| f.path == item }

      unless existing_file
        file_ref = group.new_file(relative_path)
        target.add_file_references([file_ref])
        puts "  ✅ Added: #{relative_path}"
        added_count += 1
      end
    end
  end

  added_count
end

puts "🔍 Scanning for new Swift files..."
puts ""

# Add main source files
main_group = project.main_group[SOURCE_DIR]
if main_group && main_target
  puts "📱 Main App (MediTimer):"
  count = add_files_recursively(project, main_group, SOURCE_DIR, main_target)
  puts count.zero? ? "  ℹ️  No new files found" : "  Total: #{count} files added"
  puts ""
end

# Add test files
test_group = project.main_group[TEST_DIR]
if test_group && test_target
  puts "🧪 Unit Tests (MediTimerTests):"
  count = add_files_recursively(project, test_group, TEST_DIR, test_target)
  puts count.zero? ? "  ℹ️  No new files found" : "  Total: #{count} files added"
  puts ""
end

# Add UI test files
ui_test_group = project.main_group[UI_TEST_DIR]
if ui_test_group && ui_test_target
  puts "🎨 UI Tests (MediTimerUITests):"
  count = add_files_recursively(project, ui_test_group, UI_TEST_DIR, ui_test_target)
  puts count.zero? ? "  ℹ️  No new files found" : "  Total: #{count} files added"
  puts ""
end

project.save

puts "✅ Done! Project file updated."
puts ""
puts "💡 Next steps:"
puts "  1. Open MediTimer.xcodeproj in Xcode"
puts "  2. Build the project (⌘B)"
puts "  3. Run tests (⌘U)"
