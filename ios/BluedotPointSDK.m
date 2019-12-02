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
    NSDateFormatter  *_dateFormatter;
}

RCT_EXPORT_MODULE()

- (instancetype)init {
    self = [super init];
    if (self) {
        
        //  Setup a generic date formatter
        _dateFormatter = [ NSDateFormatter new ];
        [ _dateFormatter setDateFormat: @"dd-MMM-yyyy HH:mm" ];
        
        _authenticated = NO;
    }
    return self;
}

RCT_EXPORT_METHOD(zoneInfoCallback:(RCTResponseSenderBlock)callback)
{
    _callbackIdZoneInfo = callback;
}

RCT_EXPORT_METHOD(authenticate:(NSString *)apiKey
    requestAuthorization:(NSString *)authorizationLevel
    authenticationSuccessful:(RCTResponseSenderBlock)authenticationSuccessfulCallback
    authenticationFailed: (RCTResponseSenderBlock)authenticationFailedCallback)
{
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


- (NSArray<NSString *> *)supportedEvents {
    return @[@"checkedIntoFence"];
}

/*
 *  A fence with a Custom Action has been checked into.
 *
 *  Returns the following multipart status:
 *      Array identifying fence:
 *          name (String)
 *          description (String)
 *      Array of strings identifying zone:
 *          name (String)
 *          description (String)
 *          ID (String)
 *      Array of double values identifying location:
 *          Date of check-in (Integer - UNIX timestamp)
 *          Latitude of check-in (Double)
 *          Longitude of check-in (Double)
 *          Bearing of check-in (Double)
 *          Speed of check-in (Double)
 *      Fence is awaiting check-out (BOOL)
 *      Custom fields setup in the <b>Point Access</b> web-interface.</p>
 */
- (void)didCheckIntoFence: (BDFenceInfo *)fence
                   inZone: (BDZoneInfo *)zone
               atLocation: (BDLocationInfo *)location
             willCheckOut: (BOOL)willCheckOut
           withCustomData: (NSDictionary *)customData
{
    NSLog( @"HERE: You have checked into fence '%@' in zone '%@', at %@%@",
          fence.name, zone.name, [ _dateFormatter stringFromDate: location.timestamp ],
          ( willCheckOut == YES ) ? @" and awaiting check out" : @"" );

    //  Ensure that a delegate for fence info has been setup
    if ( _callbackIdCheckedIntoFence == nil )
    {
        NSLog( @"Callback for fence check-ins has not been setup." );
        return;
    }

    NSArray  *returnFence = [ self fenceToArray: fence ];
    NSArray  *returnZone = [ self zoneToArray: zone ];
    NSArray  *returnLocation = [ self locationToArray: location ];

    [self sendEventWithName:@"checkedIntoFence" body:@{
        @"fenceInfo" : returnFence,
        @"zoneInfo" : returnZone,
        @"locationInfo" : returnLocation,
        @"willCheckOut" : @(willCheckOut),
        @"customData" : customData != nil ? customData : [NSNull null]
    }];

}

/*
 *  A beacon with a Custom Action has been checked into.
 *
 *  Returns the following multipart status:
 *      Array identifying beacon:
 *          name (String)
 *          description (String)
 *          proximity UUID (String)
 *          major (Integer)
 *          minor (Integer)
 *          latitude (Double)
 *          longitude (Double)
 *      Array of strings identifying zone:
 *          name (String)
 *          description (String)
 *          ID (String)
 *      Array of double values identifying location:
 *          Date of check-in (Integer - UNIX timestamp)
 *          Latitude of beacon setting (Double)
 *          Longitude of beacon setting (Double)
 *          Bearing of beacon setting (Double)
 *          Speed of beacon setting (Double)
 *      Proximity of check-in to beacon (Integer)
 *          0 = Unknown
 *          1 = Immediate
 *          2 = Near
 *          3 = Far
 *      Beacon is awaiting check-out (BOOL)
 *      Custom fields setup in the <b>Point Access</b> web-interface.</p>
 */
- (void)didCheckIntoBeacon: (BDBeaconInfo *)beacon
                    inZone: (BDZoneInfo *)zone
                atLocation: (BDLocationInfo *)location
             withProximity: (CLProximity)proximity
              willCheckOut: (BOOL)willCheckOut
            withCustomData: (NSDictionary *)customData
{

    NSLog( @"You have checked into beacon '%@' in zone '%@' with proximity %d at %@%@",
          beacon.name, zone.name, (int)proximity, [ _dateFormatter stringFromDate: location.timestamp ],
          ( willCheckOut == YES ) ? @" and awaiting check out" : @"" );

    //  Ensure that a delegate for fence info has been setup
    if ( _callbackIdCheckedIntoBeacon == nil )
    {
        NSLog( @"Callback for beacon check-ins has not been setup." );
        return;
    }

    NSArray  *returnBeacon = [ self beaconToArray: beacon ];
    NSArray  *returnZone = [ self zoneToArray: zone ];
    NSArray  *returnLocation = [ self locationToArray: location ];
    
    [self sendEventWithName:@"checkedIntoBeacon" body:@{
        @"fenceInfo" : returnBeacon,
        @"zoneInfo" : returnZone,
        @"locationInfo" : returnLocation,
        @"proximity" : @(proximity),
        @"willCheckOut" : @(willCheckOut),
        @"customData" : customData != nil ? customData : [NSNull null]
    }];

}

- (void)didUpdateZoneInfo: (NSSet *)zoneInfos {
    NSLog( @"Point sdk updated with %lu zones", (unsigned long)zoneInfos.count );
    
    //  Ensure that a delegate for fence info has been setup
    if ( _callbackIdZoneInfo == nil )
    {
        NSLog( @"Callback for Zone Update info has not been setup." );
        return;
    }
    
    NSMutableArray  *returnZones = [ NSMutableArray new ];

    for( BDZoneInfo *zone in zoneInfos )
    {
        [ returnZones addObject: [ self zoneToArray: zone ] ];
    }
    
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
 *  Return an array with extrapolated zone details
 */
- (NSArray *)zoneToArray: (BDZoneInfo *)zone
{
    NSMutableArray  *strings = [ NSMutableArray new ];

    [ strings addObject: zone.name ];
    [ strings addObject: ( zone.description == nil ) ? @"" : zone.description ];
    [ strings addObject: zone.ID ];

    return strings;
}

/*
 *  Return an array with extrapolated fence details into
 *      Array identifying fence:
 *          name (String)
 *          description (String)
 *          ID (String)
 */
- (NSArray *)fenceToArray: (BDFenceInfo *)fence
{
    NSMutableArray  *strings = [ NSMutableArray new ];

    [ strings addObject: fence.name ];
    [ strings addObject: ( fence.description == nil ) ? @"" : fence.description ];
    [ strings addObject: fence.ID ];

    return strings;
}

/*
 *  Return an array with extrapolated beacon details into
 *      Array identifying beacon:
 *          name (String)
 *          description (String)
 *          ID (String)
 *          isiBeacon (BOOL)
 *          proximity UUID (String)
 *          major (Integer)
 *          minor (Integer)
 *          MAC address (String)
 *          latitude (Double)
 *          longitude (Double)
 */
- (NSArray *)beaconToArray: (BDBeaconInfo *)beacon
{
    NSMutableArray  *objs = [ NSMutableArray new ];

    [ objs addObject: beacon.name ];
    [ objs addObject: ( beacon.description == nil ) ? @"" : beacon.description ];
    [ objs addObject: beacon.ID ];

    [ objs addObject: @(YES) ];
    [ objs addObject: beacon.proximityUuid ];
    [ objs addObject: @( beacon.major ) ];
    [ objs addObject: @( beacon.minor ) ];

    //  Arrays cannot contain nil, add an NSNULL object
    [ objs addObject: [ NSNull null ] ];

    [ objs addObject: @( beacon.location.latitude ) ];
    [ objs addObject: @( beacon.location.longitude ) ];

    return objs;
}

/*
 *  Return an array with extrapolated location details into
 *      Array identifying location:
 *          Date of check-in (Integer - UNIX timestamp)
 *          Latitude of check-in (Double)
 *          Longitude of check-in (Double)
 *          Bearing of check-in (Double)
 *          Speed of check-in (Double)
 */
- (NSArray *)locationToArray: (BDLocationInfo *)location
{
    NSMutableArray  *doubles = [ NSMutableArray new ];

    NSTimeInterval  unixDate = [ location.timestamp timeIntervalSince1970 ];
    [ doubles addObject: @( unixDate ) ];
    [ doubles addObject: @( location.latitude ) ];
    [ doubles addObject: @( location.longitude ) ];
    [ doubles addObject: @( location.bearing ) ];
    [ doubles addObject: @( location.speed ) ];

    return doubles;
}

@end
