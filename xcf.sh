#!/bin/sh

if [ -d "archive" ]; then
  rm -rf archive
fi

mkdir archive

# build for iOS simulator
xcodebuild archive \
  -workspace Amplitude.xcworkspace \
  -scheme Amplitude_iOS \
  -archivePath ./archive/Amplitude-iphonesimulator.xcarchive\
  -arch x86_64 \
  -sdk iphonesimulator \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  SKIP_INSTALL=NO

# build for iOS
xcodebuild archive \
  -workspace Amplitude.xcworkspace \
  -scheme Amplitude_iOS \
  -archivePath ./archive/Amplitude-iphoneos.xcarchive\
  -sdk iphoneos \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  SKIP_INSTALL=NO

# build for macOS
xcodebuild archive \
  -workspace Amplitude.xcworkspace \
  -scheme Amplitude_macOS \
  -archivePath ./archive/Amplitude-macosx.xcarchive\
  -sdk macosx \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  SKIP_INSTALL=NO

# build for tvOS
xcodebuild archive \
  -workspace Amplitude.xcworkspace \
  -scheme Amplitude_tvOS \
  -archivePath ./archive/Amplitude-appletvos.xcarchive\
  -sdk appletvos \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  SKIP_INSTALL=NO

# build for watchOS
xcodebuild archive \
  -workspace Amplitude.xcworkspace \
  -scheme Amplitude_watchOS \
  -archivePath ./archive/Amplitude-watchos.xcarchive\
  -sdk watchos \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  SKIP_INSTALL=NO

 xcodebuild -create-xcframework \
    -framework ./archive/Amplitude-iphonesimulator.xcarchive/Products/Library/Frameworks/Amplitude.framework \
    -framework ./archive/Amplitude-iphoneos.xcarchive/Products/Library/Frameworks/Amplitude.framework \
    -framework ./archive/Amplitude-macosx.xcarchive/Products/Library/Frameworks/Amplitude.framework \
    -framework ./archive/Amplitude-appletvos.xcarchive/Products/Library/Frameworks/Amplitude.framework \
    -framework ./archive/Amplitude-watchos.xcarchive/Products/Library/Frameworks/Amplitude.framework \
    -output ./XCFrameworks/Amplitude.xcframework