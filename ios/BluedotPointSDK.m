#import "BluedotPointSDK.h"
@import BDPointSDK;

@implementation BluedotPointSDK {
    /*
     *  Callback identifiers for the Bluedot Location delegates.
     */
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
        
        BDLocationManager.instance.sessionDelegate = self;
        BDLocationManager.instance.locationDelegate = self;

        //  Setup a generic date formatter
        _dateFormatter = [ NSDateFormatter new ];
        [ _dateFormatter setDateFormat: @"dd-MMM-yyyy HH:mm" ];
        
        _authenticated = NO;
    }
    return self;
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
        
    _callbackAuthenticationSuccessful = authenticationSuccessfulCallback;
    _callbackAuthenticationFailed = authenticationFailedCallback;
    
    NSLog( @"%@", BDLocationManager.instance);

    [[BDLocationManager instance] authenticateWithApiKey: apiKey requestAuthorization: bdAuthorizationLevel];
}

RCT_EXPORT_METHOD(setCustomEventMetaData: (NSDictionary *) eventMetaData)
{
    [ BDLocationManager.instance setCustomEventMetaData: eventMetaData ];
}


RCT_EXPORT_METHOD(disableZone: (NSString *) zoneId) {
    [[ BDLocationManager instance] setZone: zoneId disableByApplication: YES ];
}

RCT_EXPORT_METHOD(enableZone: (NSString *) zoneId) {
    [[ BDLocationManager instance] setZone: zoneId disableByApplication: NO ];
}

RCT_EXPORT_METHOD(notifyPushUpdateWithData: (NSDictionary *) data) {
    [[ BDLocationManager instance] notifyPushUpdateWithData:data];
}


RCT_EXPORT_METHOD(logOut: logOutSuccessful:(RCTResponseSenderBlock)logOutSuccessfulCallback
    logOutFailed: (RCTResponseSenderBlock)logOutFailedCallback)
{
    _callbackLogOutSuccessful = logOutSuccessfulCallback;
    _callbackLogOutFailed = logOutFailedCallback;
    [ BDLocationManager.instance logOut ];
}


- (NSArray<NSString *> *)supportedEvents {
    return @[
        @"ruleUpdate",
        @"checkedIntoFence",
        @"checkedOutFromFence",
        @"checkedIntoBeacon",
        @"checkedOutFromBeacon",
        @"startRequiringUserInterventionForBluetooth",
        @"stopRequiringUserInterventionForBluetooth",
        @"startRequiringUserInterventionForLocationServices",
        @"stopRequiringUserInterventionForLocationServices"
    ];
}

/*
*  This method is passed the Zone information utilised by the Bluedot SDK.
*
*  Returning:
*      Array of zones
*          Array of strings identifying zone:
*              name
*              description
*              ID
*/
- (void)didUpdateZoneInfo: (NSSet *)zoneInfos {
    NSLog( @"Point sdk updated with %lu zones", (unsigned long)zoneInfos.count );
        
    NSMutableArray  *returnZones = [ NSMutableArray new ];

    for( BDZoneInfo *zone in zoneInfos )
    {
        [ returnZones addObject: [ self zoneToArray: zone ] ];
    }
    
    [self sendEventWithName:@"ruleUpdate" body:@{
        @"zoneInfos" : returnZones
    }];

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
    NSLog( @"You have checked into fence '%@' in zone '%@', at %@%@",
          fence.name, zone.name, [ _dateFormatter stringFromDate: location.timestamp ],
          ( willCheckOut == YES ) ? @" and awaiting check out" : @"" );

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
 *  A fence with a Custom Action has been checked out of.
 *
 *  Returns the following multipart status:
 *      Array identifying fence:
 *          name (String)
 *          description (String)
 *      Array of strings identifying zone:
 *          name (String)
 *          description (String)
 *          ID (String)
 *      Date of check-out (Integer - UNIX timestamp)
 *      Dwell time in minutes (Unsigned integer)
 */
- (void)didCheckOutFromFence: (BDFenceInfo *)fence
                      inZone: (BDZoneInfo *)zone
                      onDate: (NSDate *)date
                withDuration: (NSUInteger)checkedInDuration
              withCustomData: (NSDictionary *)customData
{

    NSLog( @"You left fence '%@' in zone '%@', after %u minutes",
          fence.name, zone.name, (unsigned int)checkedInDuration );

    NSArray  *returnFence = [ self fenceToArray: fence ];
    NSArray  *returnZone = [ self zoneToArray: zone ];
    NSTimeInterval  unixDate = [ date timeIntervalSince1970 ];

    [self sendEventWithName:@"checkedOutFromFence" body:@{
        @"fenceInfo" : returnFence,
        @"zoneInfo" : returnZone,
        @"date" : @( unixDate ),
        @"dwellTime" : @( checkedInDuration ),
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
    
    NSArray  *returnBeacon = [ self beaconToArray: beacon ];
    NSArray  *returnZone = [ self zoneToArray: zone ];
    NSArray  *returnLocation = [ self locationToArray: location ];
    
    [self sendEventWithName:@"checkedIntoBeacon" body:@{
        @"beaconInfo" : returnBeacon,
        @"zoneInfo" : returnZone,
        @"locationInfo" : returnLocation,
        @"proximity" : @(proximity),
        @"willCheckOut" : @(willCheckOut),
        @"customData" : customData != nil ? customData : [NSNull null]
    }];

}

/*
 *  A beacon with a Custom Action has been checked out of.
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
 *      Proximity of check-in to beacon (Integer)
 *          0 = Unknown
 *          1 = Immediate
 *          2 = Near
 *          3 = Far
 *      Date of check-in (Integer - UNIX timestamp)
 *      Dwell time in minutes (Unsigned integer)
 */
- (void)didCheckOutFromBeacon: (BDBeaconInfo *)beacon
                       inZone: (BDZoneInfo *)zone
                withProximity: (CLProximity)proximity
                       onDate: (NSDate *)date
                 withDuration: (NSUInteger)checkedInDuration
               withCustomData: (NSDictionary *)customData
{

    NSLog( @"You have left beacon '%@' in zone '%@' with proximity %d at %@ after %u minutes",
          beacon.name, zone.name, (int)proximity, [ _dateFormatter stringFromDate: date ],
          (unsigned int)checkedInDuration );

    NSArray  *returnBeacon = [ self beaconToArray: beacon ];
    NSArray  *returnZone = [ self zoneToArray: zone ];
    NSTimeInterval  unixDate = [ date timeIntervalSince1970 ];

    [self sendEventWithName:@"checkedOutFromBeacon" body:@{
        @"fenceInfo" : returnBeacon,
        @"zoneInfo" : returnZone,
        @"proximity" : @(proximity),
        @"date" : @(unixDate),
        @"dwellTime" : @(checkedInDuration),
        @"customData" : customData != nil ? customData : [NSNull null]
    }];

}

- (void)authenticationFailedWithError:(NSError *)error {
    NSLog( @"authenticationFailedWithError");
    _callbackAuthenticationFailed(@[error.localizedDescription]);

    //  Reset the authentication callback
    _callbackAuthenticationFailed = nil;
    _callbackAuthenticationSuccessful = nil;
    
    _authenticated = NO;
}

- (void)authenticationWasDeniedWithReason:(NSString *)reason {
    NSLog( @"authenticationWasDeniedWithReason");

    _callbackAuthenticationFailed(@[reason]);

    //  Reset the authentication callback
    _callbackAuthenticationFailed = nil;
    _callbackAuthenticationSuccessful = nil;
    
    _authenticated = NO;
}

- (void)authenticationWasSuccessful {
    NSLog( @"authenticationWasSuccessful");

    //  Authentication has been successful; on iOS there are no possible warning issues
    _callbackAuthenticationSuccessful(@[]);

    //  Reset the authentication callback
    _callbackAuthenticationFailed = nil;
    _callbackAuthenticationSuccessful = nil;

    //  Session is authenticated
    _authenticated = YES;
}

- (void)didEndSession {
    NSLog( @"Logged out" );
    
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
    NSLog( @"Authenticating Point service with [%@]", apiKey);
}

/*
 *  This method is part of the Bluedot location delegate and is called when Bluetooth is required by the SDK but is not
 *  enabled on the device; requiring user intervention.
 */
- (void)didStartRequiringUserInterventionForBluetooth
{
    NSLog( @"There are nearby Beacons which cannot be detected because Bluetooth is disabled."
          "Re-enable Bluetooth to restore full functionality." );

    [self sendEventWithName:@"startRequiringUserInterventionForBluetooth" body:@{}];
}

/*
 *  This method is part of the Bluedot location delegate; it is called if user intervention on the device had previously
 *  been required to enable Bluetooth and either user intervention has enabled Bluetooth or the Bluetooth service is
 *  no longer required.
 */
- (void)didStopRequiringUserInterventionForBluetooth
{
    NSLog( @"User intervention for Bluetooth is no longer required." );

    [self sendEventWithName:@"stopRequiringUserInterventionForLocationServices" body:@{}];
}

/*
 *  This method is part of the Bluedot location delegate and is called when Location Services are not enabled
 *  on the device; requiring user intervention.
 */
- (void)didStartRequiringUserInterventionForLocationServicesAuthorizationStatus: (CLAuthorizationStatus)authorizationStatus
{
    NSString *authorizationString;
    switch(authorizationStatus){
        case kCLAuthorizationStatusDenied:
            authorizationString = @"denied";
        case kCLAuthorizationStatusRestricted:
            authorizationString = @"restricted";
        case kCLAuthorizationStatusNotDetermined:
            authorizationString = @"notDetermined";
        case kCLAuthorizationStatusAuthorizedAlways:
            authorizationString = @"always";
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            authorizationString = @"whenInUse";
        default:
            authorizationString = @"unknown";
    }
    NSLog( @"This App requires Location Services which are currently set to %@.", authorizationString );

    [self sendEventWithName:@"startRequiringUserInterventionForLocationServices"
                       body:@{@"authorizationStatus" : authorizationString}];

}

/*
 *  This method is part of the Bluedot location delegate; it is called if user intervention on the device had previously
 *  been required to enable Location Services and either Location Services has been enabled or the user is no longer
 *  within an authenticated session, thereby no longer requiring Location Services.
 */
- (void)didStopRequiringUserInterventionForLocationServicesAuthorizationStatus: (CLAuthorizationStatus)authorizationStatus
{
    NSString *authorizationString;
    switch(authorizationStatus){
        case kCLAuthorizationStatusDenied:
            authorizationString = @"denied";
        case kCLAuthorizationStatusRestricted:
            authorizationString = @"restricted";
        case kCLAuthorizationStatusNotDetermined:
            authorizationString = @"notDetermined";
        case kCLAuthorizationStatusAuthorizedAlways:
            authorizationString = @"always";
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            authorizationString = @"whenInUse";
        default:
            authorizationString = @"unknown";
    }
    NSLog( @"This App requires Location Services which are currently set to %@.", authorizationString );

    [self sendEventWithName:@"stopRequiringUserInterventionForLocationServices"
                       body:@{@"authorizationStatus" : authorizationString}];
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
