# Uncomment the next line to define a global platform for your project
source 'https://cdn.cocoapods.org'
source 'https://github.com/theraforge/OTFCocoapodSpecs'

use_frameworks!

target 'OTFMagicBox' do
  inhibit_all_warnings!

  platform :ios, '16.4'
  
  pod 'OTFToolBox/CareHealth', '2.0.0'
  pod 'GoogleSignIn', '~> 7.0.0'
end

target 'OTFMagicBoxWatch' do
  inhibit_all_warnings!
  
  platform :watchos, '9.0'
  
  pod 'OTFCloudantStore/CloudantCareHealth', '2.0.0'
  pod 'OTFCareKit/CareHealth', '2.0.2-tf.2'
end


post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.4'
        config.build_settings['WATCHOS_DEPLOYMENT_TARGET'] = '9.0'
      end
    end
  end
end
