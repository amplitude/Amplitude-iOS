#import "SEGAmplitudeIntegrationFactory.h"
#import "SEGAmplitudeIntegration.h"


@implementation SEGAmplitudeIntegrationFactory

+ (instancetype)instance
{
    static dispatch_once_t once;
    static SEGAmplitudeIntegrationFactory *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    return self;
}

- (id<SEGIntegration>)createWithSettings:(NSDictionary *)settings forAnalytics:(SEGAnalytics *)analytics
{
    return [[SEGAmplitudeIntegration alloc] initWithSettings:settings];
}

- (NSString *)key
{
    return @"Amplitude";
}

@end
