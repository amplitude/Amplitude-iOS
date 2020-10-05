amplitude_version = "8.0.1"

Pod::Spec.new do |s|
  s.name                   = "jooohhn-Amplitude"
  s.version                = amplitude_version 
  s.summary                = "Amplitude iOS/tvOS/macOS SDK."
  s.homepage               = "https://amplitude.com"
  s.license                = { :type => "MIT" }
  s.author                 = { "jooohhn" => "john.tran@amplitude.com" }
  s.source                 = { :git => "https://github.com/jooohhn/Amplitude-iOS.git", :tag => "v#{s.version}" }
  s.requires_arc           = true
  s.library                = 'sqlite3.0'
  
  s.ios.deployment_target  = '10.0'
  s.ios.source_files       = 'Sources/Amplitude/*.{h,m}'
  s.ios.resources          = 'Sources/Amplitude/**/*.{der,xib,png}'

  s.tvos.deployment_target = '9.0'
  s.tvos.source_files      = 'Sources/Amplitude/*.{h,m}'
  s.tvos.resources         = 'Sources/Amplitude/**/*.{der}'
  s.tvos.exclude_files     = [
  'Sources/Amplitude/AMPBubbleView.{h,m}',
  'Sources/Amplitude/AMPEventExplorer.{h,m}',
  'Sources/Amplitude/AMPInfoViewController.{h,m}'
  ]
  
  s.osx.deployment_target  = '10.10'
  s.osx.source_files       = 'Sources/Amplitude/*.{h,m}'
  s.osx.resources          = 'Sources/Amplitude/**/*.{der}'
  s.osx.exclude_files      = [
  'Sources/Amplitude/AMPBubbleView.{h,m}',
  'Sources/Amplitude/AMPEventExplorer.{h,m}',
  'Sources/Amplitude/AMPInfoViewController.{h,m}'
  ]
end
