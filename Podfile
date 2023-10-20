# Uncomment the next line to define a global platform for your project

target 'OTFMagicBox' do
  use_frameworks!

  source 'https://cdn.cocoapods.org'
  source 'https://github.com/TheraForge/OTFCocoapodSpecs'

  pod 'OTFToolBox/CareHealth', '1.0.3-beta'
  pod 'GoogleSignIn', '~> 7.0.0'
  
  platform :ios, '14.0'
end

target 'OTFMagicBox Watch Watch App' do
  use_frameworks!

  source 'https://cdn.cocoapods.org'
  source 'https://github.com/TheraForge/OTFCocoapodSpecs'

  # Only include the necessary dependency for the watchOS target
  pod 'OTFCareKit/Care', '2.0.2-beta.3'

  platform :watchos, '7.0'
end


post_install do |installer|
    installer.generated_projects.each do |project|
          project.targets.each do |target|
              target.build_configurations.each do |config|
                  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
                  config.build_settings['WATCHOS_DEPLOYMENT_TARGET'] = '7.0'
               end
          end
   end
end
