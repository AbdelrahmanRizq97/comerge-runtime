#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ComergeRuntimeTurboModuleProvider <NSObject>
@optional
/// Return a native module class for the requested TurboModule name.
- (nullable Class)moduleClassForName:(NSString *)name;

/// Return a preconstructed module instance for a resolved class/name pair.
- (nullable id)moduleInstanceForClass:(Class)moduleClass moduleName:(NSString *)moduleName;
@end

@interface ComergeRuntimeTurboModuleRegistry : NSObject
+ (void)setProviders:(NSArray<id<ComergeRuntimeTurboModuleProvider>> *)providers;
+ (NSArray<id<ComergeRuntimeTurboModuleProvider>> *)providers;
@end

NS_ASSUME_NONNULL_END

