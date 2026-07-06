require 'xcodeproj'

PROJECT_PATH  = File.join(__dir__, '..', 'The W App.xcodeproj')
TARGET_NAME   = 'The W App'
TEST_TARGET_NAME = 'The W AppTests'

# Files to add
FILES_TO_ADD = [
  {
    group_path: 'Wing Me/Classes',
    target: TARGET_NAME,
    file_path: File.join(__dir__, '..', 'Wing Me', 'Classes', 'KeychainHelper.swift'),
    filename: 'KeychainHelper.swift'
  },
  {
    group_path: 'The W AppTests',
    target: TEST_TARGET_NAME,
    file_path: File.join(__dir__, '..', 'The W AppTests', 'KeychainHelperTests.swift'),
    filename: 'KeychainHelperTests.swift'
  }
]

project = Xcodeproj::Project.open(PROJECT_PATH)

FILES_TO_ADD.each do |file_config|
  group_path = file_config[:group_path]
  target_name = file_config[:target]
  file_path = file_config[:file_path]
  filename = file_config[:filename]

  target = project.targets.find { |t| t.name == target_name }
  abort("Target '#{target_name}' not found") unless target

  # Find or traverse to the group
  group = project.main_group
  group_path.split('/').each do |part|
    group = group.children.find { |c| c.respond_to?(:name) && c.name == part } ||
            group.children.find { |c| c.respond_to?(:path) && c.path == part }
    abort("Group segment '#{part}' not found in path '#{group_path}'") unless group
  end

  # Check if already added
  already = group.children.any? { |c| c.respond_to?(:path) && c.path == filename }
  if already
    puts "#{filename} already in project group — skipping"
    next
  end

  file_ref = group.new_reference(File.realpath(file_path))
  target.add_file_references([file_ref])
  puts "Added #{filename} to group '#{group_path}' and target '#{target_name}'"
end

project.save
puts "Project updated successfully"
