#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ScreenStateObserverDelegate <NSObject>

- (void)screenDidWake;
- (void)screenDidSleep;
- (void)computerSleep;
- (void)computerWake;
- (void)sessionDidLock;
- (void)sessionDidUnlock;

@end

@interface ScreenStateObserver : NSObject

@property (weak, nonatomic) id <ScreenStateObserverDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
