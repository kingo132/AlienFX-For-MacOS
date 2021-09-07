//
//  AlienFX_Bridge.cpp
//  MacOSHid
//
//  Created by jason on 2021/9/6.
//  Copyright © 2021 mac. All rights reserved.
//

#include "AlienFX_Bridge.hpp"
#include "AlienFX_SDK.h"

@implementation AlienFX_Bridge

static AlienFX_Bridge *_sharedManager = nil;

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

- (int)uninitAlienFx
{
    keyboardFn.AlienFXClose();
    otherFn.AlienFXClose();
    return 0;
}

- (bool)ToggleKeyboardBrightness:(uint8)brightness
{
    return keyboardFn.ToggleState(brightness);
}

- (bool)ToggleOtherBrightness:(uint8)brightness
{
    return otherFn.ToggleState(brightness);
}

@end
