source 'https://github.com/CocoaPods/Specs.git'

project 'Amplitude'

abstract_target 'shared' do
  
  pod 'OCMock', '~> 3.2.1'
  
  target 'AmplitudeTests' do
      platform :ios, '7.0'
  end

  target 'AmplitudeTVOSTests' do
      platform :tvos, '9.0'
  end

  target 'AmplitudeMacOSTests' do
      platform :osx, '10.12'
  end
  
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    puts target.name
  end
end
