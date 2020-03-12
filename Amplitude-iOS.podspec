# PLEASE READ!
# This podspec is not maintained anymore since we add macOS support. The name of this pod won't make sense anymore.
# It's been renamed to `Amplitude`. Please use `Amplitude.podspec` in the future.
# v4.10.0, 3/11/2020

Pod::Spec.new do |s|
  s.name                   = "Amplitude-iOS"
  s.version                = "4.10.0"
  s.summary                = "Amplitude mobile analytics iOS SDK."
  s.homepage               = "https://amplitude.com"
  s.license                = { :type => "MIT" }
  s.author                 = { "Amplitude" => "dev@amplitude.com" }
  s.source                 = { :git => "https://github.com/amplitude/Amplitude-iOS.git", :tag => "v#{s.version}" }
  s.ios.deployment_target  = '10.0'
  s.tvos.deployment_target = '9.0'
  s.source_files           = 'Sources/Amplitude/*.{h,m}', 'Sources/Amplitude/SSLCertificatePinning/*.{h,m}'
  s.resources              = 'Sources/Amplitude/*.der'
  s.requires_arc           = true
  s.library 	           = 'sqlite3.0'
end
