#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class RCTHost;
@class RCTFabricSurface;
@protocol RCTTurboModuleManagerDelegate;

NS_ASSUME_NONNULL_BEGIN

typedef void (^MicroAppOnContextInitializedBlock)(void);

@interface Runtime : NSObject

@property (nonatomic, copy, readonly) NSString *bundlePath;
@property (nonatomic, strong, readonly, nullable) RCTHost *host;
@property (nonatomic, strong, readonly, nullable) RCTFabricSurface *surface;
@property (nonatomic, strong, readonly, nullable) UIView *surfaceView;

@property (nonatomic, copy, nullable) MicroAppOnContextInitializedBlock onContextInitialized;

- (instancetype)initWithBundlePath:(NSString *)bundlePath
          turboModuleManagerDelegate:(id<RCTTurboModuleManagerDelegate>)tmDelegate NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

- (void)startHostIfNeeded;
- (void)createSurfaceIfNeededWithAppKey:(NSString *)appKey initialProps:(NSDictionary *)initialProps;
- (void)setSurfaceSize:(CGSize)size;
- (void)startSurface;
- (void)stopAndDestroy;

@end

NS_ASSUME_NONNULL_END


