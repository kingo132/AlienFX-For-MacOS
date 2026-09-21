#include "AlienFX_Bridge.hpp"
#include "AlienFX_SDK.h"

@implementation AlienFX_Bridge

static AlienFX_Bridge *_sharedManager = nil;
static AlienFX_SDK::Functions keyboardFn;
static AlienFX_SDK::Functions chassisFn;
static int keyboardInitResult = -999;
static int chassisInitResult = -999;

+ (AlienFX_Bridge *)sharedManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
}

- (BOOL)initAlienFx
{
    // Make repeated wake/reconnect calls idempotent and avoid duplicate
    // IOHIDManager instances on the main run loop.
    keyboardFn.AlienFXClose();
    chassisFn.AlienFXClose();

    // Area-51m R2 keyboard: API v5, 64-byte HID report.
    keyboardInitResult = keyboardFn.AlienFXInitialize(0x0d62, 0x1a1c, 64);
    // Area-51m R2 chassis / logo / Tron lights: API v4, 34-byte report.
    chassisInitResult = chassisFn.AlienFXInitialize(0x187c, 0x0550, 34);

    return keyboardInitResult == 0 && chassisInitResult == 0;
}

- (BOOL)uninitAlienFx
{
    BOOL keyboardOK = keyboardFn.AlienFXClose();
    BOOL chassisOK = chassisFn.AlienFXClose();
    return keyboardOK && chassisOK;
}

- (BOOL)keyboardConnected
{
    return keyboardFn.IsConnected();
}

- (BOOL)chassisConnected
{
    return chassisFn.IsConnected();
}

- (int)keyboardInitStatus
{
    return keyboardInitResult;
}

- (int)chassisInitStatus
{
    return chassisInitResult;
}

- (BOOL)setKeyboardBrightness:(uint8_t)brightness
{
    brightness = MIN((uint8_t)100, brightness);
    // API v5 uses 00..FE here in the proven Area-51m R2 path.
    const uint8_t hardwareBrightness = (uint8_t)((brightness * 0xFEu) / 100u);
    return keyboardFn.ToggleState(hardwareBrightness);
}

static uint8_t AFXChassisHardwareBrightness(uint8_t brightness)
{
    brightness = MIN((uint8_t)100, brightness);
    return (uint8_t)((brightness * 0xF0u) / 100u);
}

- (BOOL)setChassisBrightness:(uint8_t)brightness
{
    const uint8_t hardwareBrightness = AFXChassisHardwareBrightness(brightness);
    // Area-51m R2 API v4 chassis mapping:
    // 0 Alien Head, 1 Touchpad, 2 Power Button, 3 Ring Top, 4 Ring Bottom.
    const AlienFX_SDK::UCHAR lights[] = {0, 1, 2, 3, 4};
    return chassisFn.SetBrightnessForLights(hardwareBrightness, lights, 5);
}

- (BOOL)setChassisSleepStateWithPowerBrightness:(uint8_t)powerBrightness
{
    // Do NOT send an off command to light ID 2. The firmware uses the power
    // button / Alien-head light as the visible sleep indicator.
    const AlienFX_SDK::UCHAR nonPowerLights[] = {0, 1, 3, 4};
    const AlienFX_SDK::UCHAR powerButton[] = {2};

    BOOL zonesOK = chassisFn.SetBrightnessForLights(0, nonPowerLights, 4);
    BOOL powerOK = chassisFn.SetBrightnessForLights(AFXChassisHardwareBrightness(powerBrightness),
                                                    powerButton,
                                                    1);
    return zonesOK && powerOK;
}

- (BOOL)setPowerButtonBrightness:(uint8_t)brightness
{
    const AlienFX_SDK::UCHAR powerButton[] = {2};
    return chassisFn.SetBrightnessForLights(AFXChassisHardwareBrightness(brightness), powerButton, 1);
}

@end
