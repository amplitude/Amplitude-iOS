project 'Amplitude'

def common_pods
  pod 'AmplitudeCore', '~> 1.0.0-alpha.1'
end

target 'Amplitude_iOS' do 
  common_pods
end

target 'Amplitude_tvOS' do 
  common_pods
end

target 'Amplitude_macOS' do 
  common_pods
end

target 'Amplitude_watchOS' do
  common_pods
end

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
