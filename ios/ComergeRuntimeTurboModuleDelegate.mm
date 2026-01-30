#import "ComergeRuntimeTurboModuleDelegate.h"
#import "ComergeRuntimeSourceCode.h"
#import "ComergeRuntimeLinkingManager.h"
#import "ComergeRuntimeLinkingManagerLegacy.h"

#import <string.h>
#import <React/CoreModulesPlugins.h>
#import <React/RCTNetworking.h>
#import <React/RCTHTTPRequestHandler.h>
#import <React/RCTDataRequestHandler.h>
#import <React/RCTFileRequestHandler.h>
#import <React/RCTURLRequestHandler.h>
#import <react/nativemodule/defaults/DefaultTurboModules.h>

@class RCTModuleRegistry;
@protocol RCTTurboModule;

@implementation ComergeRuntimeTurboModuleDelegate {
  NSURL *_bundleURL;
}

- (instancetype)initWithBundleURL:(NSURL *)bundleURL
{
  if ((self = [super init])) {
    _bundleURL = bundleURL;
  }
  return self;
}

- (Class)getModuleClassFromName:(const char *)name
{
  if (strcmp(name, "SourceCode") == 0) {
    return ComergeRuntimeSourceCode.class;
  }
  if (strcmp(name, "NativeLinkingManager") == 0) {
    return ComergeRuntimeLinkingManager.class;
  }
  if (strcmp(name, "LinkingManager") == 0) {
    return ComergeRuntimeLinkingManagerLegacy.class;
  }
  return RCTCoreModulesClassProvider(name);
}

- (id<RCTTurboModule>)getModuleInstanceFromClass:(Class)moduleClass
{
  if (moduleClass == ComergeRuntimeSourceCode.class) {
    return [[moduleClass alloc] initWithBundleURL:_bundleURL];
  }
  if (moduleClass == ComergeRuntimeLinkingManager.class) {
    return [ComergeRuntimeLinkingManager new];
  }
  if (moduleClass == ComergeRuntimeLinkingManagerLegacy.class) {
    return [ComergeRuntimeLinkingManagerLegacy new];
  }
  if (moduleClass == RCTNetworking.class) {
    return [[moduleClass alloc]
        initWithHandlersProvider:^NSArray<id<RCTURLRequestHandler>> *(RCTModuleRegistry *moduleRegistry) {
          return @[
            [RCTHTTPRequestHandler new],
            [RCTDataRequestHandler new],
            [RCTFileRequestHandler new],
            [moduleRegistry moduleForName:"BlobModule"],
          ];
        }];
  }
  return nil;
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const std::string &)name
                                                      jsInvoker:(std::shared_ptr<facebook::react::CallInvoker>)jsInvoker
{
  return facebook::react::DefaultTurboModules::getTurboModule(name, jsInvoker);
}

@end


