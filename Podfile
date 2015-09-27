source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '6.0'

xcodeproj 'Amplitude'

# pod 'sqlite3', '~> 3.8'
pod 'FMDB/standalone', '~> 2.5'

target :test do
  link_with "AmplitudeTests"
  pod 'OCMock', '~> 3.1.1'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    puts target.name
  end
end
