source 'https://github.com/CocoaPods/Specs.git'

project 'Amplitude'

abstract_target 'shared' do
  
  pod 'OCMock', '~> 3.2.1'
  
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
