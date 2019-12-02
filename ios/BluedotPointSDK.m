#import "BluedotPointSDK.h"
@import BDPointSDK;

@implementation BluedotPointSDK {
    /*
     *  Callback identifiers for the Bluedot Location delegates.
     */
    RCTResponseSenderBlock _callbackIdZoneInfo;
}

RCT_EXPORT_MODULE()

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

RCT_EXPORT_METHOD(zoneInfoCallback:(RCTResponseSenderBlock)callback)
{
    NSLog( @"Here");
    _callbackIdZoneInfo = callback;
}

RCT_EXPORT_METHOD(sampleMethod:(NSString *)stringArgument numberParameter:(nonnull NSNumber *)numberArgument callback:(RCTResponseSenderBlock)callback)
{
    // TODO: Implement some actually useful functionality
    callback(@[[NSString stringWithFormat: @"numberArgument: %@ stringArgument2: %@", numberArgument, stringArgument]]);
}

RCT_EXPORT_METHOD(authenticate:(NSString *)apiKey requestAuthorization:(NSString *)authorizationLevel callback:(RCTResponseSenderBlock)callback)
{
    
    NSLog( @"Here");
    
    BDAuthorizationLevel bdAuthorizationLevel;
    
    if ([authorizationLevel isEqualToString:@"WhenInUse"])
    {
        bdAuthorizationLevel = authorizedWhenInUse;
    } else {
        bdAuthorizationLevel = authorizedAlways;
    }
    
    BDLocationManager.instance.sessionDelegate = self;
    BDLocationManager.instance.locationDelegate = self;
    
    NSLog( @"%@", BDLocationManager.instance);

    [[BDLocationManager instance] authenticateWithApiKey: apiKey requestAuthorization: bdAuthorizationLevel];
    callback(@[[NSString stringWithFormat: @"apiKey: %@ authorizationLevel: %@", apiKey, authorizationLevel]]);
}

- (void)didUpdateZoneInfo: (NSSet *)zoneInfos {
    NSLog( @"Point sdk updated with %lu zones", (unsigned long)zoneInfos.count );
    
    NSMutableArray  *returnZones = [ NSMutableArray new ];

    for( BDZoneInfo *zone in zoneInfos )
    {
        [ returnZones addObject: [ self zoneToArray: zone ] ];
    }
    
    _callbackIdZoneInfo(@[[NSNull null], returnZones]);

}

- (void)authenticationFailedWithError:(NSError *)error {
    NSLog( @"authenticationFailedWithError");
}

- (void)authenticationWasDeniedWithReason:(NSString *)reason {
    NSLog( @"authenticationWasDeniedWithReason");
}

- (void)authenticationWasSuccessful {
    NSLog( @"authenticationWasSuccessful");
}

- (void)didEndSession {
    NSLog( @"didEndSession");
}

- (void)didEndSessionWithError:(NSError *)error {
    NSLog( @"didEndSessionWithError");
}

- (void)willAuthenticateWithApiKey:(NSString *)apiKey {
    NSLog( @"willAuthenticateWithApiKey");
}

/*
 *  Return an array with extrapolated zone details into Cordova variable types.
 */
- (NSArray *)zoneToArray: (BDZoneInfo *)zone
{
    NSMutableArray  *strings = [ NSMutableArray new ];

    [ strings addObject: zone.name ];
    [ strings addObject: ( zone.description == nil ) ? @"" : zone.description ];
    [ strings addObject: zone.ID ];

    return strings;
}


@end
