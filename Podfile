#Podfile
platform :ios, '8.0'

use_frameworks!

target 'Music Player' do
  pod "XCDYouTubeKit”
  pod "SnapKit"
  pod ’SwiftyJSON’
end


pods_with_specific_swift_versions = {
  'SwiftyJSON' => '4.0'
}

post_install do |installer|
    installer.pods_project.targets.each do |target|
      if pods_with_specific_swift_versions.key? target.name
        swift_version = pods_with_specific_swift_versions[target.name]
        target.build_configurations.each do |config|
          config.build_settings['SWIFT_VERSION'] = swift_version
        end
      end
    end
end
