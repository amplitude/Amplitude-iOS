Pod::Spec.new do |s|
  s.name                   = "Amplitude-Segment-tvOS"
  s.version                = "4.0.4"
  s.summary                = "Amplitude mobile analytics iOS SDK."
  s.homepage               = "https://amplitude.com"
  s.license                = { :type => "MIT" }
  s.author                 = { "Amplitude" => "dev@amplitude.com" }
  s.source                 = { :git => "https://github.com/fubotv/Amplitude-iOS" }
  s.ios.deployment_target  = '7.0'
  s.tvos.deployment_target = '9.0'
  s.source_files           = 'Amplitude/*.{h,m}', 'Amplitude/SSLCertificatePinning/*.{h,m}'
  s.resources              = 'Amplitude/*.der'
  s.requires_arc           = true
  s.library 	             = 'sqlite3.0'
  s.dependency             'Analytics', '~> 3.6'
end
