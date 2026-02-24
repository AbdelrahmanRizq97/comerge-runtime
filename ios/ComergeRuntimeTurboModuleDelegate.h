#import <Foundation/Foundation.h>
#import <ReactCommon/RCTTurboModuleManager.h>
#import "ComergeRuntimeTurboModuleProvider.h"

@interface ComergeRuntimeTurboModuleDelegate : NSObject <RCTTurboModuleManagerDelegate>

- (instancetype)initWithBundleURL:(NSURL *)bundleURL;
- (instancetype)initWithBundleURL:(NSURL *)bundleURL
                         providers:(NSArray<id<ComergeRuntimeTurboModuleProvider>> *)providers;

@end


