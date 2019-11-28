#import <React/RCTBridgeModule.h>
@import BDPointSDK;

@interface BluedotPointSDK : NSObject <RCTBridgeModule, BDPSessionDelegate, BDPLocationDelegate>

@end
