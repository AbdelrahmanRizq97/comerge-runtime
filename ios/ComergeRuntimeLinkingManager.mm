#import "ComergeRuntimeLinkingManager.h"

#import <React/RCTBridge.h>
#import <React/RCTLog.h>
#import <React/RCTUtils.h>

@implementation ComergeRuntimeLinkingManager

RCT_EXPORT_MODULE(NativeLinkingManager)

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (void)startObserving
{
  // Intentionally no-op: we do not want micro-apps to inherit host URL events.
}

- (void)stopObserving
{
  // Intentionally no-op.
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[ @"url" ];
}

RCT_EXPORT_METHOD(getInitialURL : (RCTPromiseResolveBlock)resolve reject : (__unused RCTPromiseRejectBlock)reject)
{
  // Always null to prevent host deep link propagation into micro-apps.
  resolve((id)kCFNull);
}

RCT_EXPORT_METHOD(openURL
                  : (NSURL *)URL resolve
                  : (RCTPromiseResolveBlock)resolve reject
                  : (RCTPromiseRejectBlock)reject)
{
  [RCTSharedApplication() openURL:URL
                          options:@{}
                completionHandler:^(BOOL success) {
    if (success) {
      resolve(@YES);
    } else {
#if TARGET_OS_SIMULATOR
      if ([URL.absoluteString hasPrefix:@"tel:"]) {
        RCTLogWarn(@"Unable to open the Phone app in the simulator for telephone URLs. URL:  %@", URL);
        resolve(@NO);
      } else {
        reject(RCTErrorUnspecified, [NSString stringWithFormat:@"Unable to open URL: %@", URL], nil);
      }
#else
      reject(RCTErrorUnspecified, [NSString stringWithFormat:@"Unable to open URL: %@", URL], nil);
#endif
    }
  }];
}

RCT_EXPORT_METHOD(canOpenURL
                  : (NSURL *)URL resolve
                  : (RCTPromiseResolveBlock)resolve reject
                  : (__unused RCTPromiseRejectBlock)reject)
{
  if (RCTRunningInAppExtension()) {
    resolve(@NO);
    return;
  }

  BOOL canOpen = [RCTSharedApplication() canOpenURL:URL];
  NSString *scheme = [URL scheme];
  if (canOpen) {
    resolve(@YES);
  } else if (![[scheme lowercaseString] hasPrefix:@"http"] && ![[scheme lowercaseString] hasPrefix:@"https"]) {
    NSArray *querySchemes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"LSApplicationQueriesSchemes"];
    if (querySchemes != nil &&
        ([querySchemes containsObject:scheme] || [querySchemes containsObject:[scheme lowercaseString]])) {
      resolve(@NO);
    } else {
      reject(
          RCTErrorUnspecified,
          [NSString
              stringWithFormat:@"Unable to open URL: %@. Add %@ to LSApplicationQueriesSchemes in your Info.plist.",
                               URL,
                               scheme],
          nil);
    }
  } else {
    resolve(@NO);
  }
}

RCT_EXPORT_METHOD(openSettings : (RCTPromiseResolveBlock)resolve reject : (__unused RCTPromiseRejectBlock)reject)
{
  NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
  [RCTSharedApplication() openURL:url
                          options:@{}
                completionHandler:^(BOOL success) {
    if (success) {
      resolve(nil);
    } else {
      reject(RCTErrorUnspecified, @"Unable to open app settings", nil);
    }
  }];
}

RCT_EXPORT_METHOD(sendIntent
                  : (__unused NSString *)action extras
                  : (__unused NSArray *_Nullable)extras resolve
                  : (RCTPromiseResolveBlock)resolve reject
                  : (__unused RCTPromiseRejectBlock)reject)
{
  // Not supported on iOS.
  resolve(nil);
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
  return std::make_shared<facebook::react::NativeLinkingManagerSpecJSI>(params);
}

@end
