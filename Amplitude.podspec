Pod::Spec.new do |s|
  s.name                   = "Amplitude"
  s.version                = "5.2.1"
  s.summary                = "Amplitude iOS/tvOS/macOS SDK."
  s.homepage               = "https://amplitude.com"
  s.license                = { :type => "MIT" }
  s.author                 = { "Amplitude" => "dev@amplitude.com" }
  s.source                 = { :git => "https://github.com/amplitude/Amplitude-iOS.git", :tag => "v#{s.version}" }
  s.ios.deployment_target  = '10.0'
  s.tvos.deployment_target = '9.0'
  s.osx.deployment_target  = '10.10'
  s.source_files           = 'Sources/Amplitude/*.{h,m}', 'Sources/Amplitude/SSLCertificatePinning/*.{h,m}'
  s.resources              = 'Sources/Amplitude/*.der'
  s.requires_arc           = true
  s.library 	           = 'sqlite3.0'
end
