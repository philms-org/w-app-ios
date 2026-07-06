require 'xcodeproj'

PROJECT_PATH = File.join(__dir__, '..', 'Wing Me.xcodeproj')
OLD_NAME = 'Wing Me'
NEW_NAME = 'The W App'
NEW_BUNDLE_ID = 'com.thewapp.wap'

project = Xcodeproj::Project.open(PROJECT_PATH)

project.targets.each do |target|
  next unless target.name == OLD_NAME
  target.name = NEW_NAME
  target.product_name = NEW_NAME
  target.build_configurations.each do |config|
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = NEW_BUNDLE_ID
    config.build_settings['PRODUCT_NAME'] = NEW_NAME
  end
  puts "Renamed target '#{OLD_NAME}' → '#{NEW_NAME}'"
  puts "Bundle ID set to '#{NEW_BUNDLE_ID}'"
end

project.save
puts "Saved #{PROJECT_PATH}"
