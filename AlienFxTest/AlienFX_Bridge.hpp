//
//  AlienFX_Bridge.hpp
//  MacOSHid
//
//  Created by jason on 2021/9/6.
//  Copyright © 2021 mac. All rights reserved.
//

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

@end

#endif /* AlienFX_Bridge_hpp */
