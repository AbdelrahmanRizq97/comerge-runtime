#import "ComergeRuntimeView.h"

#import "Runtime.h"
#import "ComergeRuntimeTurboModuleDelegate.h"

#import <React/RCTRedBoxSetEnabled.h>
#import <React/RCTDevLoadingViewSetEnabled.h>

static const NSTimeInterval kMicroAppContextInitStartDelaySeconds = 0.2;

@interface ComergeRuntimeView ()
@property (nonatomic, strong) Runtime *runtime;
@property (nonatomic, strong) UIView *surfaceView;
@property (nonatomic, assign) NSInteger loadGeneration;
@property (nonatomic, assign) BOOL started;
@property (nonatomic, assign) BOOL starting;
@property (nonatomic, assign) BOOL hasNonZeroSize;
@property (nonatomic, assign) BOOL contextInitialized;
@property (nonatomic, strong) ComergeRuntimeTurboModuleDelegate *tmDelegate;
@end

@implementation ComergeRuntimeView

- (instancetype)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    self.backgroundColor = UIColor.clearColor;
    self.clipsToBounds = YES;
    _loadGeneration = 0;
    _started = NO;
    _starting = NO;
    _hasNonZeroSize = NO;
    _contextInitialized = NO;
  }
  return self;
}

- (void)setAppKey:(NSString *)appKey
{
  if ((_appKey == appKey) || ([_appKey isEqualToString:appKey])) {
    return;
  }
  _appKey = [appKey copy];
  if (self.runtime.host != nil) {
    [self unloadMicroApp];
  }
  [self maybeLoadMicroApp];
}

- (void)setBundlePath:(NSString *)bundlePath
{
  NSString *next = bundlePath ?: @"";
  if ([next hasPrefix:@"file://"]) {
    next = [next substringFromIndex:7];
  }
  if ((_bundlePath == next) || ([_bundlePath isEqualToString:next])) {
    return;
  }
  _bundlePath = [next copy];
  if (self.runtime.host != nil) {
    [self unloadMicroApp];
  }
  [self maybeLoadMicroApp];
}

- (void)setInitialProps:(NSDictionary *)initialProps
{
  _initialProps = initialProps;
  if (self.runtime.surface && self.runtime.host) {
    [self unloadMicroApp];
    [self maybeLoadMicroApp];
  }
}

- (void)maybeLoadMicroApp
{
  if (self.appKey.length == 0 || self.bundlePath.length == 0) {
    return;
  }
  if (self.runtime.host != nil) {
    return;
  }
  NSString *pathCopy = [self.bundlePath copy];
  NSInteger gen = self.loadGeneration;
  // Disable Dev overlays for this micro host and route fatals to NSLog
  @try { RCTRedBoxSetEnabled(NO); } @catch (__unused NSException *e) {}
  @try { RCTDevLoadingViewSetEnabled(NO); } @catch (__unused NSException *e) {}
  self.tmDelegate = [ComergeRuntimeTurboModuleDelegate new];

  Runtime *runtime = [[Runtime alloc] initWithBundlePath:pathCopy
                               turboModuleManagerDelegate:self.tmDelegate];

  __weak __typeof(self) weakSelf = self;
  runtime.onContextInitialized = ^{
    __strong __typeof(self) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    if (strongSelf.loadGeneration != gen || strongSelf.runtime != runtime) {
      return;
    }
    strongSelf.contextInitialized = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMicroAppContextInitStartDelaySeconds * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
      if (strongSelf.loadGeneration != gen || strongSelf.runtime != runtime) {
        return;
      }
      [strongSelf tryStartIfPossible];
    });
  };

  [runtime startHostIfNeeded];

  NSDictionary *props = self.initialProps ?: @{};
  [runtime createSurfaceIfNeededWithAppKey:self.appKey initialProps:props];

  self.runtime = runtime;
  self.surfaceView = runtime.surfaceView;
  self.surfaceView.frame = self.bounds;
  self.surfaceView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [self addSubview:self.surfaceView];
  [self.runtime setSurfaceSize:self.bounds.size];
  // Ensure we layout before attempting to start the surface
  [self setNeedsLayout];
  [self layoutIfNeeded];
  dispatch_async(dispatch_get_main_queue(), ^{
    __strong __typeof(self) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    if (strongSelf.loadGeneration != gen || strongSelf.runtime != runtime) {
      return;
    }
    [strongSelf tryStartIfPossible];
  });
}

- (void)unloadMicroApp
{
  self.loadGeneration += 1;
  [self.runtime stopAndDestroy];
  if (self.surfaceView) {
    [self.surfaceView removeFromSuperview];
  }
  self.surfaceView = nil;
  self.runtime = nil;
  self.tmDelegate = nil;
  self.started = NO;
  self.starting = NO;
  self.hasNonZeroSize = NO;
  self.contextInitialized = NO;
}

- (void)dealloc
{
  [self unloadMicroApp];
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  if (self.surfaceView) {
    self.surfaceView.frame = self.bounds;
    [self.runtime setSurfaceSize:self.bounds.size];
  }
  BOOL nonZero = self.bounds.size.width > 0 && self.bounds.size.height > 0;
  if (nonZero && !self.hasNonZeroSize) {
    self.hasNonZeroSize = YES;
    [self tryStartIfPossible];
  }
}

- (void)didMoveToWindow
{
  [super didMoveToWindow];
  // Defer to layout pass; we'll start after we have non-zero size
  [self setNeedsLayout];
}

- (void)tryStartIfPossible
{
  if (self.started) {
    return;
  }
  if (self.starting) {
    return;
  }
  if (self.runtime.host == nil || self.runtime.surface == nil) {
    return;
  }
  if (!self.contextInitialized) {
    return;
  }
  if (self.bounds.size.width <= 0 || self.bounds.size.height <= 0) {
    return;
  }
  self.starting = YES;
  @try {
    [self.runtime startSurface];
    self.started = YES;
  } @catch (__unused NSException *e) {
  } @finally {
    self.starting = NO;
  }
}

@end


