#import <React/RCTBridgeModule.h>
@import BDPointSDK;

@interface BluedotPointSdk : NSObject <RCTBridgeModule, BDPSessionDelegate, BDPLocationDelegate>

@end
