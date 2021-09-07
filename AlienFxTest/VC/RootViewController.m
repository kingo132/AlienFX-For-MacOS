#import "RootViewController.h"
#include <IOKit/hid/IOHIDLib.h>
#include <IOKit/hid/IOHIDKeys.h>
#include "AlienFX_Bridge.hpp"

@interface RootViewController ()
{
}
@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    int ret = [[AlienFX_Bridge sharedManager] initAlienFx];
    NSLog(@"initAlienFx ret: %d", ret);
    if (ret) {
        NSLog(@"AlienFx initialize failed: %d, check the permission of Accesibility!", ret);
    }
}

- (IBAction)SliderCtl:(NSSlider *)sender
{
    switch (sender.tag) {
        case 11:
            NSLog(@"toggle keyboard brightness: %d", [sender intValue]);
            [[AlienFX_Bridge sharedManager] ToggleKeyboardBrightness:[sender intValue]];
            break;
        case 12:
            NSLog(@"toggle other brightness: %d", [sender intValue]);
            [[AlienFX_Bridge sharedManager] ToggleOtherBrightness:[sender intValue]];
            break;
    }
    return;
}

- (void)viewWillDisappear
{
    NSLog(@"bye bye");
    [[NSApplication sharedApplication] terminate:nil];
}

@end
