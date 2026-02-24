#import "ComergeRuntimeTurboModuleDelegate.h"
#import "ComergeRuntimeSourceCode.h"
#import "ComergeRuntimeLinkingManager.h"
#import "ComergeRuntimeLinkingManagerLegacy.h"
#import "ComergeRuntimeTurboModuleProvider.h"

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
  NSArray<id<ComergeRuntimeTurboModuleProvider>> *_providers;
}

- (instancetype)initWithBundleURL:(NSURL *)bundleURL
{
  return [self initWithBundleURL:bundleURL providers:[ComergeRuntimeTurboModuleRegistry providers]];
}

- (instancetype)initWithBundleURL:(NSURL *)bundleURL
                        providers:(NSArray<id<ComergeRuntimeTurboModuleProvider>> *)providers
{
  if ((self = [super init])) {
    _bundleURL = bundleURL;
    _providers = [providers copy] ?: @[];
  }
  return self;
}

static void ComergeRuntimeLogModuleResolution(NSString *moduleName, NSString *path)
{
  NSLog(@"[ComergeRuntime][TurboModule] resolve '%@' via %@", moduleName ?: @"<unknown>", path ?: @"<none>");
}

- (Class)getModuleClassFromName:(const char *)name
{
  NSString *moduleName = name != nullptr ? [NSString stringWithUTF8String:name] : nil;
  if (moduleName.length == 0) {
    return Nil;
  }

  if (strcmp(name, "SourceCode") == 0) {
    ComergeRuntimeLogModuleResolution(moduleName, @"internal");
    return ComergeRuntimeSourceCode.class;
  }
  if (strcmp(name, "NativeLinkingManager") == 0) {
    ComergeRuntimeLogModuleResolution(moduleName, @"internal");
    return ComergeRuntimeLinkingManager.class;
  }
  if (strcmp(name, "LinkingManager") == 0) {
    ComergeRuntimeLogModuleResolution(moduleName, @"internal");
    return ComergeRuntimeLinkingManagerLegacy.class;
  }

  for (id<ComergeRuntimeTurboModuleProvider> provider in _providers) {
    if (![provider respondsToSelector:@selector(moduleClassForName:)]) {
      continue;
    }
    Class moduleClass = [provider moduleClassForName:moduleName];
    if (moduleClass != Nil) {
      ComergeRuntimeLogModuleResolution(moduleName, @"host_provider");
      return moduleClass;
    }
  }

  Class coreClass = RCTCoreModulesClassProvider(name);
  if (coreClass != Nil) {
    ComergeRuntimeLogModuleResolution(moduleName, @"core");
    return coreClass;
  }

  ComergeRuntimeLogModuleResolution(moduleName, @"missing");
  return Nil;
}

- (id<RCTTurboModule>)getModuleInstanceFromClass:(Class)moduleClass
{
  NSString *moduleName = NSStringFromClass(moduleClass);

  if (moduleClass == ComergeRuntimeSourceCode.class) {
    ComergeRuntimeLogModuleResolution(moduleName, @"internal");
    return [[moduleClass alloc] initWithBundleURL:_bundleURL];
  }
  if (moduleClass == ComergeRuntimeLinkingManager.class) {
    ComergeRuntimeLogModuleResolution(moduleName, @"internal");
    return [ComergeRuntimeLinkingManager new];
  }
  if (moduleClass == ComergeRuntimeLinkingManagerLegacy.class) {
    ComergeRuntimeLogModuleResolution(moduleName, @"internal");
    return [ComergeRuntimeLinkingManagerLegacy new];
  }
  if (moduleClass == RCTNetworking.class) {
    ComergeRuntimeLogModuleResolution(moduleName, @"internal");
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

  for (id<ComergeRuntimeTurboModuleProvider> provider in _providers) {
    if (![provider respondsToSelector:@selector(moduleInstanceForClass:moduleName:)]) {
      continue;
    }
    id moduleInstance = [provider moduleInstanceForClass:moduleClass moduleName:moduleName];
    if (moduleInstance != nil) {
      ComergeRuntimeLogModuleResolution(moduleName, @"host_provider");
      return (id<RCTTurboModule>)moduleInstance;
    }
  }

  return nil;
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const std::string &)name
                                                      jsInvoker:(std::shared_ptr<facebook::react::CallInvoker>)jsInvoker
{
  NSString *moduleName = [NSString stringWithUTF8String:name.c_str()];
  ComergeRuntimeLogModuleResolution(moduleName, @"default");
  return facebook::react::DefaultTurboModules::getTurboModule(name, jsInvoker);
}

@end


