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
    }
    return self;
}

RCT_EXPORT_METHOD(authenticate:(NSString *)projectId
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

    [[BDLocationManager instance] authenticateWithApiKey: projectId requestAuthorization: bdAuthorizationLevel];
}

RCT_EXPORT_METHOD(setCustomEventMetaData: (NSDictionary *) eventMetaData)
{
    [ BDLocationManager.instance setCustomEventMetaData: eventMetaData ];
}

RCT_EXPORT_METHOD(setForegroundNotification: (NSString *) channelId
                  channelName: (NSString *) channelName
                  title: (NSString *) title
                  content: (NSString *) content
                  targetAllAPis: (BOOL) targetAllAPis ) {
    NSLog( @"Note: setForegroundNotification is applicable to Android only");
}

RCT_EXPORT_METHOD(setNotificationIDResourceID: (NSString *) resourceID){
    NSLog( @"Note: setNotificationIDResourceID is applicable to Android only");
}

RCT_EXPORT_METHOD(notifyPushUpdateWithData: (NSDictionary *) data) {
    [[ BDLocationManager instance] notifyPushUpdateWithData:data];
}


RCT_EXPORT_METHOD(logOut: (RCTResponseSenderBlock)logOutSuccessfulCallback
    logOutFailed: (RCTResponseSenderBlock)logOutFailedCallback)
{
    _callbackLogOutSuccessful = logOutSuccessfulCallback;
    _callbackLogOutFailed = logOutFailedCallback;
    [ BDLocationManager.instance logOut ];
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

- (NSArray<NSString *> *)supportedEvents {
    return @[
        @"zoneInfoUpdate",
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
*/
- (void)didUpdateZoneInfo: (NSSet *)zoneInfos {
    NSLog( @"Point sdk updated with %lu zones", (unsigned long)zoneInfos.count );
        
    NSMutableArray  *returnZones = [ NSMutableArray new ];

    for( BDZoneInfo *zone in zoneInfos )
    {
        [ returnZones addObject: [ self zoneToDict: zone ] ];
    }
    
    [self sendEventWithName:@"zoneInfoUpdate" body:@{
        @"zoneInfos" : returnZones
    }];

}


/*
 *  A fence with a Custom Action has been checked into.
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

    NSDictionary *returnFence = [ self fenceToDict: fence ];
    NSDictionary *returnZone = [ self zoneToDict: zone ];
    NSDictionary *returnLocation = [ self locationToDict: location ];

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
 */
- (void)didCheckOutFromFence: (BDFenceInfo *)fence
                      inZone: (BDZoneInfo *)zone
                      onDate: (NSDate *)date
                withDuration: (NSUInteger)checkedInDuration
              withCustomData: (NSDictionary *)customData
{

    NSLog( @"You left fence '%@' in zone '%@', after %u minutes",
          fence.name, zone.name, (unsigned int)checkedInDuration );

    NSDictionary  *returnFence = [ self fenceToDict: fence ];
    NSDictionary *returnZone = [ self zoneToDict: zone ];
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
 *  Proximity of check-in to beacon (Integer)
 *          0 = Unknown
 *          1 = Immediate
 *          2 = Near
 *          3 = Far
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
    
    NSDictionary *returnBeacon = [ self beaconToDict: beacon ];
    NSDictionary *returnZone = [ self zoneToDict: zone ];
    NSDictionary *returnLocation = [ self locationToDict: location ];
    
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
 *  Proximity of check-in to beacon (Integer)
 *          0 = Unknown
 *          1 = Immediate
 *          2 = Near
 *          3 = Far
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

    NSDictionary *returnBeacon = [ self beaconToDict: beacon ];
    NSDictionary *returnZone = [ self zoneToDict: zone ];
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
}

- (void)authenticationWasDeniedWithReason:(NSString *)reason {
    NSLog( @"authenticationWasDeniedWithReason");

    _callbackAuthenticationFailed(@[reason]);

    //  Reset the authentication callback
    _callbackAuthenticationFailed = nil;
    _callbackAuthenticationSuccessful = nil;
}

- (void)authenticationWasSuccessful {
    NSLog( @"authenticationWasSuccessful");

    //  Authentication has been successful; on iOS there are no possible warning issues
    _callbackAuthenticationSuccessful(@[]);

    //  Reset the authentication callback
    _callbackAuthenticationFailed = nil;
    _callbackAuthenticationSuccessful = nil;
}

- (void)didEndSession {
    NSLog( @"Logged out" );
    
    _callbackLogOutSuccessful(@[]);
    
    //  Reset the callback
    _callbackLogOutSuccessful = nil;
    _callbackLogOutFailed = nil;
}

- (void)didEndSessionWithError:(NSError *)error {
    NSLog( @"didEndSessionWithError");
    
    _callbackLogOutFailed(@[error.localizedDescription]);
    
    //  Reset the callback
    _callbackLogOutSuccessful = nil;
    _callbackLogOutFailed = nil;
}

- (void)willAuthenticateWithApiKey:(NSString *)projectId {
    NSLog( @"Authenticating Point service with [%@]", projectId);
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
 *  This method is part of the Bluedot location delegate; it is called if user
 *  intervention on the device had previously been required to enable Location Services
 *  and either Location Services has been enabled or the user is no longer
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
 *  Return an NSDictionary with extrapolated zone details
 */
- (NSDictionary *)zoneToDict: (BDZoneInfo *)zone
{
    NSMutableDictionary  *dict = [ NSMutableDictionary new ];

    [ dict setObject:zone.name forKey:@"name"];
    [ dict setObject:zone.ID forKey:@"ID"];

    return dict;
}

/*
 *  Return a NSDictionary with extrapolated fence details into
 */
- (NSDictionary *)fenceToDict: (BDFenceInfo *)fence
{
    NSMutableDictionary  *dict = [ NSMutableDictionary new ];

    [ dict setObject:fence.name forKey:@"name"];
    [ dict setObject:fence.ID forKey:@"ID"];

    return dict;
}

/*
 *  Return an NSDictionary with extrapolated beacon details into
 */
- (NSDictionary *)beaconToDict: (BDBeaconInfo *)beacon
{
    NSMutableDictionary  *dict = [ NSMutableDictionary new ];

    [ dict setObject:beacon.name forKey:@"name"];
    [ dict setObject:beacon.ID forKey:@"ID"];
    [ dict setObject:beacon.proximityUuid forKey:@"proximityUUID"];
    [ dict setObject:@( beacon.major ) forKey:@"major"];
    [ dict setObject:@( beacon.minor ) forKey:@"minor"];
    [ dict setObject:[ NSNull null ] forKey:@"macAddress"];
    [ dict setObject:@( beacon.location.latitude ) forKey:@"latitude"];
    [ dict setObject:@( beacon.location.longitude ) forKey:@"longitude"];

    return dict;
}

/*
 *  Return an NSDictionary with extrapolated location details into
 */
- (NSDictionary *)locationToDict: (BDLocationInfo *)location
{
    NSMutableDictionary  *dict = [ NSMutableDictionary new ];
    NSTimeInterval  unixDate = [ location.timestamp timeIntervalSince1970 ];
    
    [ dict setObject:@( unixDate ) forKey:@"unixDate"];
    [ dict setObject:@( location.latitude ) forKey:@"latitude"];
    [ dict setObject:@( location.longitude ) forKey:@"longitude"];
    [ dict setObject:@( location.bearing ) forKey:@"bearing"];
    [ dict setObject:@( location.speed ) forKey:@"speed"];

    return dict;
}

@end
