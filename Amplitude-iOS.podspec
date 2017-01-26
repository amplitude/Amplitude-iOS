Pod::Spec.new do |s|
  s.name                   = "Amplitude-iOS"
  s.version                = "3.12.1"
  s.summary                = "Amplitude mobile analytics iOS SDK."
  s.homepage               = "https://amplitude.com"
  s.license                = { :type => "MIT" }
  s.author                 = { "Amplitude" => "dev@amplitude.com" }
  s.source                 = { :git => "https://github.com/amplitude/Amplitude-iOS.git", :tag => "v3.12.1" }
  s.ios.deployment_target  = '6.0'
  s.tvos.deployment_target = '9.0'
  s.source_files           = 'Amplitude/*.{h,m}'
  s.requires_arc           = true
  s.library 	             = 'sqlite3.0'
end
