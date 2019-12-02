#import "BluedotPointSDK.h"
@import BDPointSDK;

@implementation BluedotPointSDK {
    /*
     *  Callback identifiers for the Bluedot Location delegates.
     */
    RCTResponseSenderBlock _callbackIdZoneInfo;
    RCTResponseSenderBlock _callbackAuthenticationSuccessful;
    RCTResponseSenderBlock _callbackAuthenticationFailed;
    RCTResponseSenderBlock _callbackLogOutSuccessful;
    RCTResponseSenderBlock _callbackLogOutFailed;
    BOOL _authenticated;
}

RCT_EXPORT_MODULE()

- (instancetype)init {
    self = [super init];
    if (self) {
        _authenticated = NO;
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

RCT_EXPORT_METHOD(authenticate:(NSString *)apiKey
    requestAuthorization:(NSString *)authorizationLevel
    authenticationSuccessful:(RCTResponseSenderBlock)authenticationSuccessfulCallback
    authenticationFailed: (RCTResponseSenderBlock)authenticationFailedCallback)
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
    
    _callbackAuthenticationSuccessful = authenticationSuccessfulCallback;
    _callbackAuthenticationFailed = authenticationFailedCallback;
    
    NSLog( @"%@", BDLocationManager.instance);

    [[BDLocationManager instance] authenticateWithApiKey: apiKey requestAuthorization: bdAuthorizationLevel];
}

RCT_EXPORT_METHOD(setCustomEventMetaData: (NSDictionary *) eventMetaData)
{
    [ BDLocationManager.instance setCustomEventMetaData: eventMetaData ];
}

RCT_EXPORT_METHOD(logOut: logOutSuccessful:(RCTResponseSenderBlock)logOutSuccessfulCallback
    logOutFailed: (RCTResponseSenderBlock)logOutFailedCallback)
{
    _callbackLogOutSuccessful = logOutSuccessfulCallback;
    _callbackLogOutFailed = logOutFailedCallback;
    [ BDLocationManager.instance logOut ];
}

- (void)didUpdateZoneInfo: (NSSet *)zoneInfos {
    NSLog( @"Point sdk updated with %lu zones", (unsigned long)zoneInfos.count );
    
    NSMutableArray  *returnZones = [ NSMutableArray new ];

    for( BDZoneInfo *zone in zoneInfos )
    {
        [ returnZones addObject: [ self zoneToArray: zone ] ];
    }
    
    NSLog( @"returnZones updated with %lu zones", (unsigned long)returnZones.count );
    
    _callbackIdZoneInfo(@[[NSNull null], returnZones]);

}

- (void)authenticationFailedWithError:(NSError *)error {
    NSLog( @"authenticationFailedWithError");
    _callbackAuthenticationFailed(@[error.localizedDescription, [NSNull null] ]);

    //  Reset the authentication callback
    _callbackAuthenticationFailed = nil;
    _callbackAuthenticationSuccessful = nil;
    
    _authenticated = NO;
}

- (void)authenticationWasDeniedWithReason:(NSString *)reason {
    NSLog( @"authenticationWasDeniedWithReason");

    _callbackAuthenticationFailed(@[reason, [NSNull null] ]);

    //  Reset the authentication callback
    _callbackAuthenticationFailed = nil;
    _callbackAuthenticationSuccessful = nil;
    
    _authenticated = NO;
}

- (void)authenticationWasSuccessful {
    NSLog( @"authenticationWasSuccessful");

    //  Authentication has been successful; on iOS there are no possible warning issues
    _callbackAuthenticationSuccessful(@[@( 0 ), [NSNull null] ]);

    //  Reset the authentication callback
    _callbackAuthenticationFailed = nil;
    _callbackAuthenticationSuccessful = nil;

    //  Session is authenticated
    _authenticated = YES;
}

- (void)didEndSession {
    NSLog( @"didEndSession" );
    
    _callbackLogOutSuccessful(@[]);
    
    //  Reset the callback
    _callbackLogOutSuccessful = nil;
    _callbackLogOutFailed = nil;
    
    _authenticated = NO;
}

- (void)didEndSessionWithError:(NSError *)error {
    NSLog( @"didEndSessionWithError");
    
    _callbackLogOutFailed(@[error.localizedDescription]);
    
    //  Reset the callback
    _callbackLogOutSuccessful = nil;
    _callbackLogOutFailed = nil;
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
