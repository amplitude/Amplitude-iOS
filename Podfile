source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '7.0'

project 'Amplitude'

target 'AmplitudeTests' do
    pod 'OCMock', '~> 3.2.1'
end

target 'AmplitudeTVOSTests' do
    platform :tvos, '9.0'
    pod 'OCMock', '~> 3.2.1'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    puts target.name
  end
end
