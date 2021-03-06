#include "AlienFX_Bridge.hpp"
#include "AlienFX_SDK.h"

@implementation AlienFX_Bridge

static AlienFX_Bridge *_sharedManager = nil;
int _lastKeyboardBrightnessSave = 50;

+(AlienFX_Bridge *)sharedManager {
    if(!_sharedManager)
        _sharedManager = [[self alloc] init];
    return _sharedManager;
}

AlienFX_SDK::Functions keyboardFn;
AlienFX_SDK::Functions otherFn;

- (int)initAlienFx
{
    int ret1 = keyboardFn.AlienFXInitialize(0xd62, 0x1a1c, 64);
    int ret2 = otherFn.AlienFXInitialize(0x187c, 0x550, 34);
    return (ret1 == 0) && (ret2 == 0);
}

/*- (int)reinitAlienFx
{
    int ret1 = keyboardFn.AlienFXReinitialize();
    int ret2 = otherFn.AlienFXReinitialize();
    return (ret1 == 0) && (ret2 == 0);
}*/

- (int)uninitAlienFx
{
    keyboardFn.AlienFXClose();
    otherFn.AlienFXClose();
    return 0;
}

- (bool)ToggleKeyboardBrightness:(uint8)brightness
{
    _lastKeyboardBrightnessSave = (brightness * 0xFE) / 100.0;
    return keyboardFn.ToggleState(_lastKeyboardBrightnessSave);
}

- (bool)ToggleOtherBrightness:(uint8)brightness
{
    return otherFn.ToggleState((brightness * 0xF0) / 100.0);
}

- (bool)TurnOffOnScreenOff
{
    bool ret = keyboardFn.ToggleState(0);
    if (! ret) {
        [self initAlienFx];
        
        ret = keyboardFn.ToggleState(0);
    }
    return ret;
}

- (bool)RestoreOnScreenOn
{
    bool ret = keyboardFn.ToggleState(_lastKeyboardBrightnessSave);
    if (! ret) {
        [self initAlienFx];
        
        ret = keyboardFn.ToggleState(_lastKeyboardBrightnessSave);
    }
    return ret;
}

@end
