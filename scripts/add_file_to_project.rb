require 'xcodeproj'

PROJECT_PATH  = File.join(__dir__, '..', 'Wing Me.xcodeproj')
TARGET_NAME   = 'The W App'
GROUP_PATH    = 'Wing Me/Classes'
FILE_PATH     = File.join(__dir__, '..', 'Wing Me', 'Classes', 'WAPSupabase.swift')

project = Xcodeproj::Project.open(PROJECT_PATH)
target  = project.targets.find { |t| t.name == TARGET_NAME }
abort("Target '#{TARGET_NAME}' not found") unless target

# Find or traverse to the Classes group
group = project.main_group
GROUP_PATH.split('/').each do |part|
  group = group.children.find { |c| c.respond_to?(:name) && c.name == part } ||
          group.children.find { |c| c.respond_to?(:path) && c.path == part }
  abort("Group segment '#{part}' not found") unless group
end

# Check if already added
already = group.children.any? { |c| c.respond_to?(:path) && c.path == 'WAPSupabase.swift' }
if already
  puts "WAPSupabase.swift already in project group — skipping"
  exit 0
end

file_ref = group.new_reference(File.realpath(FILE_PATH))
target.add_file_references([file_ref])

project.save
puts "Added WAPSupabase.swift to group '#{GROUP_PATH}' and target '#{TARGET_NAME}'"
