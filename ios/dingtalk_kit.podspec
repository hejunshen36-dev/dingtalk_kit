#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint dingtalk_kit.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'dingtalk_kit'
  s.version          = '0.0.1'
  s.summary          = 'dingtalk SDK flutter plugin.'
  s.description      = <<-DESC
dingtalk SDK flutter plugin.
                       DESC
  # Upstream source attribution; the local Pod name is dingtalk_kit.
  s.homepage         = 'https://github.com/saperliu/flutter_dingtalk_sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'liuyf' => 'saperliu@163.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.static_framework = true
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Official DTShareKit 3.1.0: device and simulator slices.
  s.subspec 'vendor' do |sp|
    sp.vendored_frameworks = 'Libraries/*.xcframework'
  end
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
