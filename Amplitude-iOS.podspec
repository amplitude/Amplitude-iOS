Pod::Spec.new do |s|
  s.name         = "Amplitude-iOS"
  s.version      = "3.8.1"
  s.summary      = "Amplitude mobile analytics iOS SDK."
  s.homepage     = "https://amplitude.com"
  s.license      = { :type => "MIT" }
  s.author       = { "Amplitude" => "dev@amplitude.com" }
  s.source       = { :git => "https://github.com/amplitude/Amplitude-iOS.git", :tag => "v3.8.1" }
  s.platform     = :ios, '5.0'
  s.source_files = 'Amplitude/*.{h,m}'
  s.requires_arc = true
  s.library 	 = 'sqlite3.0'
end
