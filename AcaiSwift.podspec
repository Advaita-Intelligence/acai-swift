Pod::Spec.new do |s|
  s.name             = 'AcaiSwift'
  s.version          = '1.0.0'
  s.summary          = 'Acai iOS/tvOS/macOS/watchOS analytics SDK'
  s.homepage         = 'https://github.com/your-org/Acai-Swift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Your Org' => 'sdk@your-org.com' }
  s.source           = { :git => 'https://github.com/your-org/Acai-Swift.git', :tag => s.version.to_s }
  s.ios.deployment_target  = '13.0'
  s.tvos.deployment_target = '13.0'
  s.osx.deployment_target  = '10.15'
  s.watchos.deployment_target = '7.0'
  s.swift_version    = '5.7'
  s.source_files     = 'Sources/Acai/**/*.swift'
  s.dependency       'AmplitudeCore-Swift', '~> 1.4'
  s.dependency       'analytics-connector-ios', '~> 1.3'
end
