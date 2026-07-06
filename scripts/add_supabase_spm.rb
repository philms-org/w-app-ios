require 'xcodeproj'

PROJECT_PATH = File.join(__dir__, '..', 'The W App.xcodeproj')
TARGET_NAME  = 'The W App'
REPO_URL     = 'https://github.com/supabase/supabase-swift'
MIN_VERSION  = '2.0.0'
PRODUCT_NAME = 'Supabase'

project = Xcodeproj::Project.open(PROJECT_PATH)

# Check if already added
existing = project.root_object.package_references.find do |ref|
  ref.respond_to?(:repositoryURL) && ref.repositoryURL == REPO_URL
end
if existing
  puts "Supabase SPM package already present — skipping"
  exit 0
end

# Add remote package reference
pkg_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
pkg_ref.repositoryURL = REPO_URL
pkg_ref.requirement = {
  'kind'           => 'upToNextMajorVersion',
  'minimumVersion' => MIN_VERSION
}
project.root_object.package_references << pkg_ref

# Add product dependency to target
target = project.targets.find { |t| t.name == TARGET_NAME }
abort("Target '#{TARGET_NAME}' not found — run rebrand_target.rb first") unless target

dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
dep.package = pkg_ref
dep.product_name = PRODUCT_NAME
target.package_product_dependencies << dep

project.save
puts "Added Supabase SPM package to target '#{TARGET_NAME}'"
