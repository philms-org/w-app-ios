require 'xcodeproj'

# Remove test files from the main app target's Sources build phase.
# Test files must not be compiled into the production app binary.
# They will be wired to a proper test target in a future task.

PROJECT_PATH = File.join(__dir__, '..', 'The W App.xcodeproj')
TARGET_NAME  = 'The W App'
TEST_FILES   = %w[KeychainHelperTests.swift WAPSupabaseTests.swift]

project = Xcodeproj::Project.open(PROJECT_PATH)
target  = project.targets.find { |t| t.name == TARGET_NAME }
abort("Target '#{TARGET_NAME}' not found") unless target

sources_phase = target.source_build_phase
removed = []

sources_phase.files.each do |build_file|
  path = build_file.file_ref&.path.to_s
  if TEST_FILES.any? { |f| path.end_with?(f) }
    sources_phase.remove_build_file(build_file)
    removed << path
    puts "Removed #{path} from main app Sources build phase"
  end
end

if removed.empty?
  puts "No test files found in main app Sources build phase — nothing to do"
else
  project.save
  puts "Saved project"
end
