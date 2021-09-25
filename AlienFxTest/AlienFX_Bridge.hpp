#ifndef AlienFX_Bridge_hpp
#define AlienFX_Bridge_hpp

#import <Foundation/Foundation.h>

@interface AlienFX_Bridge : NSObject
{
}

+ (AlienFX_Bridge *)sharedManager;

- (int)initAlienFx;

- (int)uninitAlienFx;

- (bool)ToggleKeyboardBrightness:(uint8)brightness;

- (bool)ToggleOtherBrightness:(uint8)brightness;

- (bool)TurnOffOnScreenOff;

- (bool)RestoreOnScreenOn;

@end

#endif /* AlienFX_Bridge_hpp */
