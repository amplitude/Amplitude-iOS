//
//  AMPConstants.h
//  Copyright (c) 2014 Amplitude Inc. (https://amplitude.com/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <Foundation/Foundation.h>

extern NSString *const kAMPLibrary;
extern NSString *const kAMPVersion;
extern NSString *const kAMPUnknownLibrary;
extern NSString *const kAMPUnknownVersion;
extern NSString *const kAMPPlatform;
extern NSString *const kAMPOSName;
extern NSString *const kAMPEventLogDomain;
extern NSString *const kAMPEventLogEuDomain;
extern NSString *const kAMPEventLogUrl;
extern NSString *const kAMPEventLogEuUrl;
extern NSString *const kAMPContentTypeHeader;
extern NSString *const kAMPDyanmicConfigUrl;
extern NSString *const kAMPDyanmicConfigEuUrl;
extern NSString *const kAMPDefaultInstance;
extern const int kAMPApiVersion;
extern const int kAMPDBVersion;
extern const int kAMPDBFirstVersion;
extern const int kAMPEventUploadThreshold;
extern const int kAMPEventUploadMaxBatchSize;
extern const int kAMPEventMaxCount;
extern const int kAMPEventRemoveBatchSize;
extern const int kAMPEventUploadPeriodSeconds;
extern const int kAMPIdentifyUploadPeriodSeconds;
extern const int kAMPMinIdentifyUploadPeriodSeconds;
extern const long kAMPMinTimeBetweenSessionsMillis;
extern const int kAMPMaxStringLength;
extern const int kAMPMaxPropertyKeys;

extern NSString *const IDENTIFY_EVENT;
extern NSString *const GROUP_IDENTIFY_EVENT;
extern NSString *const AMP_OP_ADD;
extern NSString *const AMP_OP_APPEND;
extern NSString *const AMP_OP_CLEAR_ALL;
extern NSString *const AMP_OP_PREPEND;
extern NSString *const AMP_OP_SET;
extern NSString *const AMP_OP_SET_ONCE;
extern NSString *const AMP_OP_UNSET;
extern NSString *const AMP_OP_PREINSERT;
extern NSString *const AMP_OP_POSTINSERT;
extern NSString *const AMP_OP_REMOVE;

// Revenue
extern NSString *const AMP_REVENUE_PRODUCT_ID;
extern NSString *const AMP_REVENUE_QUANTITY;
extern NSString *const AMP_REVENUE_PRICE;
extern NSString *const AMP_REVENUE_REVENUE_TYPE;
extern NSString *const AMP_REVENUE_RECEIPT;

// Options
extern NSString *const AMP_TRACKING_OPTION_CARRIER;
extern NSString *const AMP_TRACKING_OPTION_CITY;
extern NSString *const AMP_TRACKING_OPTION_COUNTRY;
extern NSString *const AMP_TRACKING_OPTION_DEVICE_MANUFACTURER;
extern NSString *const AMP_TRACKING_OPTION_DEVICE_MODEL;
extern NSString *const AMP_TRACKING_OPTION_DMA;
extern NSString *const AMP_TRACKING_OPTION_IDFA;
extern NSString *const AMP_TRACKING_OPTION_IDFV;
extern NSString *const AMP_TRACKING_OPTION_IP_ADDRESS;
extern NSString *const AMP_TRACKING_OPTION_LANGUAGE;
extern NSString *const AMP_TRACKING_OPTION_LAT_LNG;
extern NSString *const AMP_TRACKING_OPTION_OS_NAME;
extern NSString *const AMP_TRACKING_OPTION_OS_VERSION;
extern NSString *const AMP_TRACKING_OPTION_PLATFORM;
extern NSString *const AMP_TRACKING_OPTION_REGION;
extern NSString *const AMP_TRACKING_OPTION_VERSION_NAME;

// Plan
extern NSString *const AMP_PLAN_BRANCH;
extern NSString *const AMP_PLAN_SOURCE;
extern NSString *const AMP_PLAN_VERSION;
extern NSString *const AMP_PLAN_VERSION_ID;

// Ingestion Metadata
extern NSString *const AMP_INGESTION_METADATA_SOURCE_NAME;
extern NSString *const AMP_INGESTION_METADATA_SOURCE_VERSION;
