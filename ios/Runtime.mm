#import "Runtime.h"

#import <ReactCommon/RCTHost.h>
#import <ReactCommon/RCTHermesInstance.h>
#import <React/RCTFabricSurface.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTJavaScriptLoader.h>
#import <React_RCTAppDelegate/RCTDefaultReactNativeFactoryDelegate.h>

@interface Runtime () <RCTHostDelegate>
@property (nonatomic, copy, readwrite) NSString *bundlePath;
@property (nonatomic, strong, readwrite, nullable) RCTHost *host;
@property (nonatomic, strong, readwrite, nullable) RCTFabricSurface *surface;
@property (nonatomic, strong, readwrite, nullable) UIView *surfaceView;

@property (nonatomic, strong) RCTDefaultReactNativeFactoryDelegate *rnFactoryDelegate;
@property (nonatomic, strong) id<RCTTurboModuleManagerDelegate> tmDelegate;
@end

@implementation Runtime

- (instancetype)initWithBundlePath:(NSString *)bundlePath
          turboModuleManagerDelegate:(id<RCTTurboModuleManagerDelegate>)tmDelegate
{
  if ((self = [super init])) {
    _bundlePath = [bundlePath copy];
    _tmDelegate = tmDelegate;
    _rnFactoryDelegate = [RCTDefaultReactNativeFactoryDelegate new];
  }
  return self;
}

- (void)startHostIfNeeded
{
  if (self.host != nil) {
    return;
  }

  NSString *pathCopy = [self.bundlePath copy];

  RCTHostBundleURLProvider provider = ^NSURL *{
    if (pathCopy.length == 0) {
      return (NSURL *)nil;
    }
    return [NSURL fileURLWithPath:pathCopy isDirectory:NO];
  };

  RCTHostJSEngineProvider jsProvider = ^std::shared_ptr<facebook::react::JSRuntimeFactory> {
    return std::make_shared<facebook::react::RCTHermesInstance>();
  };

  self.host = [[RCTHost alloc] initWithBundleURLProvider:provider
                                           hostDelegate:self
                             turboModuleManagerDelegate:self.tmDelegate
                                       jsEngineProvider:jsProvider
                                          launchOptions:nil];

  // start host immediately (surface starts later).
  [self.host start];
}

- (void)createSurfaceIfNeededWithAppKey:(NSString *)appKey initialProps:(NSDictionary *)initialProps
{
  if (self.surface != nil || self.host == nil) {
    return;
  }

  self.surface = [self.host createSurfaceWithModuleName:appKey
                                                   mode:facebook::react::DisplayMode::Visible
                                      initialProperties:initialProps ?: @{}];
  self.surfaceView = (UIView *)[self.surface view];
}

- (void)setSurfaceSize:(CGSize)size
{
  if (self.surface == nil) {
    return;
  }
  @try {
    [self.surface setSize:size];
  } @catch (__unused NSException *e) {
  }
}

- (void)startSurface
{
  if (self.surface == nil) {
    return;
  }
  @try {
    [self.surface start];
  } @catch (__unused NSException *e) {
  }
}

- (void)stopAndDestroy
{
  if (self.surface) {
    @try {
      [self.surface stop];
    } @catch (__unused NSException *e) {
    }
  }

  self.surfaceView = nil;
  self.surface = nil;
  self.host = nil;
  self.tmDelegate = nil;
  self.rnFactoryDelegate = nil;
}

#pragma mark - RCTHostDelegate

- (void)hostDidStart:(RCTHost *)host
{
  // bundle-load completion is handled in loadBundleAtURL:... before signaling context init.
}

- (void)loadBundleAtURL:(NSURL *)sourceURL
             onProgress:(RCTSourceLoadProgressBlock)onProgress
             onComplete:(RCTSourceLoadBlock)loadCallback
{
  // Ensure packager access is disabled; always use the provided file path
#if RCT_DEV_MENU || RCT_PACKAGER_LOADING_FUNCTIONALITY
  @try { RCTBundleURLProviderAllowPackagerServerAccess(NO); } @catch (__unused NSException *e) {}
#endif

  NSString *path = self.bundlePath;
  NSURL *url = path.length > 0 ? [NSURL fileURLWithPath:path isDirectory:NO] : sourceURL;
  if (url == nil) {
    NSError *err = [NSError errorWithDomain:RCTJavaScriptLoaderErrorDomain
                                       code:RCTJavaScriptLoaderErrorNoScriptURL
                                   userInfo:@{NSLocalizedDescriptionKey: @"No script URL provided (ComergeRuntimeView)"}];
    loadCallback(err, nil);
    return;
  }

  [RCTJavaScriptLoader loadBundleAtURL:url
                            onProgress:onProgress
                            onComplete:^(NSError *error, RCTSource *source) {
    loadCallback(error, source);
    if (error == nil) {
      MicroAppOnContextInitializedBlock cb = self.onContextInitialized;
      if (cb) {
        dispatch_async(dispatch_get_main_queue(), ^{
          cb();
        });
      }
    } else {
    }
  }];
}

@end


