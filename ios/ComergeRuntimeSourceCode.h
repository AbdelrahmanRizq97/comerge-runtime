#import <Foundation/Foundation.h>

#import <FBReactNativeSpec/FBReactNativeSpec.h>
#import <React/RCTBridgeModule.h>

@interface ComergeRuntimeSourceCode : NSObject <NativeSourceCodeSpec>

- (instancetype)initWithBundleURL:(NSURL *)bundleURL;

@end
