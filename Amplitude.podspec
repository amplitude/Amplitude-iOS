amplitude_version = "8.22.0" # Version is managed automatically by semantic-release, please don't change it manually

Pod::Spec.new do |s|
  s.name                   = "Amplitude"
  s.version                = amplitude_version 
  s.summary                = "Amplitude iOS/tvOS/macOS SDK."
  s.homepage               = "https://amplitude.com"
  s.license                = { :type => "MIT" }
  s.author                 = { "Amplitude" => "dev@amplitude.com" }
  s.source                 = { :git => "https://github.com/amplitude/Amplitude-iOS.git", :tag => "v#{s.version}" }
  s.requires_arc           = true
  s.library                = 'sqlite3.0'

  s.swift_version = '4.1'
  
  s.ios.deployment_target  = '10.0'
  s.ios.source_files       = 'Sources/Amplitude/**/*.{h,m}'
  s.ios.resource_bundle    = { 'Amplitude_Amplitude': ['Sources/Resources/*.{der}', 'Sources/PrivacyInfo.xcprivacy'] }

  s.tvos.deployment_target = '9.0'
  s.tvos.source_files      = 'Sources/Amplitude/**/*.{h,m}'
  s.tvos.resource_bundle    = { 'Amplitude_Amplitude': ['Sources/Resources/*.{der}', 'Sources/PrivacyInfo.xcprivacy'] }

  s.osx.deployment_target  = '10.10'
  s.osx.source_files       = 'Sources/Amplitude/**/*.{h,m}'
  s.osx.resource_bundle    = { 'Amplitude_Amplitude': ['Sources/Resources/*.{der}', 'Sources/PrivacyInfo.xcprivacy'] }

  s.watchos.deployment_target  = '3.0'
  s.watchos.source_files       = 'Sources/Amplitude/**/*.{h,m}'
  s.watchos.resource_bundle    = { 'Amplitude_Amplitude': ['Sources/Resources/*.{der}', 'Sources/PrivacyInfo.xcprivacy'] }
  
  s.dependency 'AnalyticsConnector', '~> 1.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
