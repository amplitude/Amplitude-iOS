//
//  AMPConstants.m

#import "AMPConstants.h"

#if TARGET_OS_IPHONE
NSString *const kAMPLibrary = @"amplitude-ios";
#else
NSString *const kAMPLibrary = @"amplitude-osx";
#endif

#if TARGET_OS_IPHONE
NSString *const kAMPPlatform = @"iOS";
#else
NSString *const kAMPPlatform = @"OSX";
#endif

NSString *const kAMPVersion = @"3.2.1";
NSString *const kAMPEventLogDomain = @"api.amplitude.com";
NSString *const kAMPEventLogUrl = @"https://api.amplitude.com/";
const int kAMPApiVersion = 3;
const int kAMPDBVersion = 3;
const int kAMPDBFirstVersion = 2; // to detect if DB exists yet
const int kAMPEventUploadThreshold = 30;
const int kAMPEventUploadMaxBatchSize = 100;
const int kAMPEventMaxCount = 1000;
const int kAMPEventRemoveBatchSize = 20;
const int kAMPEventUploadPeriodSeconds = 30; // 30s
const long kAMPMinTimeBetweenSessionsMillis = 5 * 60 * 1000; // 5m
const int kAMPMaxStringLength = 1024;

NSString *const IDENTIFY_EVENT = @"$identify";
NSString *const AMP_OP_ADD = @"$add";
NSString *const AMP_OP_SET = @"$set";
NSString *const AMP_OP_SET_ONCE = @"$setOnce";
NSString *const AMP_OP_UNSET = @"$unset";
