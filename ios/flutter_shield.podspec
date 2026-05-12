#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_shield.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_shield'
  s.version          = '1.1.9'
  s.summary          = 'A comprehensive device security and vulnerability detection package for Flutter.'
  s.description      = <<-DESC
Flutter Shield provides a unified API to detect 31 security vulnerabilities across Android and iOS — from root/jailbreak detection to WebView misconfigurations.
                       DESC
  s.homepage         = 'https://github.com/sanjaysharmajw/flutter_shield'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Sanjay Sharma' => 'sanjaysharmajw@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Sources/flutter_shield/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'flutter_shield_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
