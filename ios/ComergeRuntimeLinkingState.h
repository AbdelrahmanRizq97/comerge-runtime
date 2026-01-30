#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ComergeRuntimeLinkingState : NSObject
+ (void)setMicroRuntimeActive:(BOOL)active;
+ (BOOL)isMicroRuntimeActive;

+ (void)clearInitialURL;
+ (nullable NSURL *)initialURL;
+ (void)setInitialURL:(nullable NSURL *)url;
@end

NS_ASSUME_NONNULL_END
