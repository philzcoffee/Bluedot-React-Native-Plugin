#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@import BDPointSDK;

@interface BluedotPointSDK : RCTEventEmitter <RCTBridgeModule, BDPSessionDelegate, BDPLocationDelegate>

@end
