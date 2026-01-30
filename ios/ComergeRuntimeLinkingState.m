#import "ComergeRuntimeLinkingState.h"

static BOOL ComergeRuntimeMicroRuntimeActive = NO;
static NSURL *ComergeRuntimeInitialURL = nil;

@implementation ComergeRuntimeLinkingState

+ (void)setMicroRuntimeActive:(BOOL)active
{
  ComergeRuntimeMicroRuntimeActive = active;
}

+ (BOOL)isMicroRuntimeActive
{
  return ComergeRuntimeMicroRuntimeActive;
}

+ (void)clearInitialURL
{
  ComergeRuntimeInitialURL = nil;
}

+ (NSURL *)initialURL
{
  return ComergeRuntimeInitialURL;
}

+ (void)setInitialURL:(NSURL *)url
{
  ComergeRuntimeInitialURL = url;
}

@end
