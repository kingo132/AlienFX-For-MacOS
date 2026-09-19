#ifndef AlienFX_Bridge_hpp
#define AlienFX_Bridge_hpp

#import <Foundation/Foundation.h>
#include <stdint.h>

/// Thin, brightness-only bridge used by the macOS UI.
///
/// IMPORTANT: this public bridge deliberately does not expose per-key RGB or
/// global-effect APIs.  The Windows/AWCC per-key colour layout is treated as
/// the protected hardware baseline and this app only changes brightness.
@interface AlienFX_Bridge : NSObject

+ (AlienFX_Bridge *)sharedManager;

/// Initialize both internal AlienFX controllers.
/// Returns YES when both are present.  Individual device state can be queried
/// with keyboardConnected/chassisConnected.
- (BOOL)initAlienFx;

/// Close all IOKit/HID resources. Returns YES when cleanup succeeded.
- (BOOL)uninitAlienFx;

- (BOOL)keyboardConnected;
- (BOOL)chassisConnected;
- (int)keyboardInitStatus;
- (int)chassisInitStatus;

/// Brightness only (0...100). These calls do not intentionally modify RGB.
- (BOOL)setKeyboardBrightness:(uint8_t)brightness;
- (BOOL)setChassisBrightness:(uint8_t)brightness;

@end

#endif /* AlienFX_Bridge_hpp */
