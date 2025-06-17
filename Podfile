project 'Amplitude'
use_frameworks!

abstract_target 'AnalyticsConnector' do
  pod 'AnalyticsConnector', '~> 1.0.0', :configurations => ['Debug', 'Release']

  target 'Amplitude_iOS' do
    platform :ios, '11.0'
  end

  target 'Amplitude_macOS' do
    platform :macos, '10.15'
  end

  target 'Amplitude_watchOS' do
    platform :watchos, '3.0'
  end

  target 'Amplitude_tvOS' do
    platform :tvos, '9.0'
  end
end

abstract_target 'shared' do
  
  pod 'OCMock', '~> 3.8.1'

  target 'Amplitude_iOSTests' do
      platform :ios, '10.0'
  end

  target 'Amplitude_tvOSTests' do
      platform :tvos, '9.0'
  end

  target 'Amplitude_macOSTests' do
      platform :osx, '10.10'
  end
  
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    puts target.name
  end
end
