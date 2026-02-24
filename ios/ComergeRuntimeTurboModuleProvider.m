#import "ComergeRuntimeTurboModuleProvider.h"

static NSArray<id<ComergeRuntimeTurboModuleProvider>> *ComergeRuntimeTurboModuleProviders = nil;

@implementation ComergeRuntimeTurboModuleRegistry

+ (void)setProviders:(NSArray<id<ComergeRuntimeTurboModuleProvider>> *)providers
{
  @synchronized(self) {
    ComergeRuntimeTurboModuleProviders = [providers copy] ?: @[];
  }
}

+ (NSArray<id<ComergeRuntimeTurboModuleProvider>> *)providers
{
  @synchronized(self) {
    return ComergeRuntimeTurboModuleProviders ?: @[];
  }
}

@end

