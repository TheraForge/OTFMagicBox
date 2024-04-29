# Uncomment the next line to define a global platform for your project
source 'https://cdn.cocoapods.org'
source 'https://github.com/TheraForge/OTFCocoapodSpecs'

use_frameworks!

target 'OTFMagicBox' do
  platform :ios, '14.6'
  
  pod 'OTFToolBox/CareHealth', '1.0.4-beta'
  pod 'GoogleSignIn', '~> 7.0.0'
end

target 'OTFMagicBoxWatch' do
  platform :watchos, '8.0'
  
  pod 'OTFCloudantStore/CloudantCareHealth', '1.0.4-beta'
  pod 'OTFCareKit/CareHealth', '2.0.2-beta.4'
end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
        config.build_settings['WATCHOS_DEPLOYMENT_TARGET'] = '8.0'
      end
    end
  end
end
