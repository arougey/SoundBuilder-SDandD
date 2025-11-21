#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint audio_engine.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'audio_engine'
  s.version          = '1.0.0'
  s.summary          = 'Local audio engine with pitch/speed/pan'
  s.description      = <<-DESC
AVAudioEngine based engine for multi track modifications of pitch/speed/sound
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Alex' => 'arougebec@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.frameworks       = 'AVFoundation', 'AVFAudio'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'audio_engine_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
  s.static_framework = true
end
