# Uncomment the next line to define a global platform for your project
source 'https://cdn.cocoapods.org'
source 'https://github.com/TheraForge/OTFCocoapodSpecs'

use_frameworks!

target 'OTFMagicBox' do
  inhibit_all_warnings!

  platform :ios, '16.4'
  
  pod 'OTFToolBox/CareHealth', '2.5.0'
  pod 'GoogleSignIn', '~> 7.0.0'
end

target 'OTFMagicBoxWatch' do
  inhibit_all_warnings!
  
  platform :watchos, '9.0'
  
  pod 'OTFCloudantStore/CloudantCareHealth', '2.1.0'
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

  # Xcode 26 can resolve TOOLCHAIN_DIR to the optional Metal toolchain during linking.
  generated_swift_path = '${TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}'
  xcode_default_swift_path = '${DEVELOPER_DIR}/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/${PLATFORM_NAME}'
  support_files_pattern = File.join(installer.sandbox.root.to_s, 'Target Support Files', '**', '*.xcconfig')

  Dir.glob(support_files_pattern).each do |xcconfig_path|
    contents = File.read(xcconfig_path)
    updated_contents = contents.gsub(generated_swift_path, xcode_default_swift_path)
    File.write(xcconfig_path, updated_contents) if updated_contents != contents
  end
end
