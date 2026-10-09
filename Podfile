# Uncomment the next line to define a global platform for your project
IOS_DEPLOYMENT_TARGET = '15.0'
platform :ios, IOS_DEPLOYMENT_TARGET

target 'zmaticoo-ios-demo' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  pod 'zMaticoo', '2.3.2'

end

target 'zmaticoo-ios-demo-swift' do
  use_frameworks!

  pod 'zMaticoo', '2.3.2'

end

# Each pod target's IPHONEOS_DEPLOYMENT_TARGET comes from its own podspec (usually 9.0-12.0) and does not follow the platform above.
# Only raise it, never lower it: pods that already require a higher version keep their own value.
# Required because Xcode 27 does not support deployment targets below iOS 15.
post_install do |installer|
  min_version = Gem::Version.new(IOS_DEPLOYMENT_TARGET)
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        current = config.build_settings['IPHONEOS_DEPLOYMENT_TARGET']
        next if current && Gem::Version.new(current) >= min_version
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = IOS_DEPLOYMENT_TARGET
      end
    end
  end
end
