#import <UIKit/UIKit.h>
#import <React/RCTBridge.h>

@interface ComergeRuntimeView : UIView

@property (nonatomic, copy) NSString *appKey;
@property (nonatomic, copy) NSString *bundlePath;
@property (nonatomic, strong) NSDictionary *initialProps;

@end


