#import "ComergeRuntimeSourceCode.h"

using namespace facebook::react;

@interface ComergeRuntimeSourceCode ()
@property (nonatomic, copy) NSString *scriptURL;
@end

@implementation ComergeRuntimeSourceCode

RCT_EXPORT_MODULE(SourceCode)

- (instancetype)initWithBundleURL:(NSURL *)bundleURL
{
  if ((self = [super init])) {
    _scriptURL = bundleURL.absoluteString ?: @"";
  }
  return self;
}

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

- (NSDictionary<NSString *, id> *)constantsToExport
{
  return [self getConstants];
}

- (NSDictionary<NSString *, id> *)getConstants
{
  return @{
    @"scriptURL" : self.scriptURL ?: @"",
  };
}

- (std::shared_ptr<TurboModule>)getTurboModule:(const ObjCTurboModule::InitParams &)params
{
  return std::make_shared<NativeSourceCodeSpecJSI>(params);
}

@end
