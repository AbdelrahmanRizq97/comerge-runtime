#import <Foundation/Foundation.h>
#import <ReactCommon/RCTTurboModuleManager.h>

@interface ComergeRuntimeTurboModuleDelegate : NSObject <RCTTurboModuleManagerDelegate>

- (instancetype)initWithBundleURL:(NSURL *)bundleURL;

@end


