require 'xcodeproj'

PROJECT_PATH = File.join(__dir__, '..', 'The W App.xcodeproj')
TARGET_NAME = 'The W App'

# Files to add: [group_path, file_path, filename]
FILES_TO_ADD = [
  ['Wing Me/Classes', File.join(__dir__, '..', 'Wing Me', 'Classes', 'KeychainHelper.swift'), 'KeychainHelper.swift'],
  ['The W AppTests', File.join(__dir__, '..', 'The W AppTests', 'KeychainHelperTests.swift'), 'KeychainHelperTests.swift']
]

project = Xcodeproj::Project.open(PROJECT_PATH)
target = project.targets.find { |t| t.name == TARGET_NAME }
abort("Target '#{TARGET_NAME}' not found") unless target

FILES_TO_ADD.each do |group_path, file_path, filename|
  # Navigate to the correct group
  group = project.main_group
  group_path.split('/').each do |part|
    found_group = group.children.find { |c|
      (c.respond_to?(:name) && c.name == part) || (c.respond_to?(:path) && c.path == part)
    }

    # If group doesn't exist, create it
    if found_group
      group = found_group
    else
      # For The W AppTests, we might need to create it
      if part == 'The W AppTests'
        # Try to find it as a group reference
        group = group.children.find { |c| c.respond_to?(:real_path) && c.real_path.to_s.include?('The W AppTests') }
        if !group
          # Create a new group reference
          test_group_path = File.join(__dir__, '..', 'The W AppTests')
          group = project.main_group.new_group('The W AppTests', test_group_path)
        end
      else
        abort("Group '#{part}' not found in path '#{group_path}'")
      end
    end
  end

  # Check if file is already added
  already_added = group.children.any? { |c| c.respond_to?(:path) && c.path == filename }
  if already_added
    puts "#{filename} already in group — skipping"
    next
  end

  # Add file reference
  file_ref = group.new_reference(File.realpath(file_path))
  target.add_file_references([file_ref])
  puts "Added #{filename} to group and target"
end

project.save
puts "Xcode project updated successfully"
