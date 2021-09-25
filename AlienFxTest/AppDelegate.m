#import "AppDelegate.h"
#import "ScreenStateObserver.h"
#include "AlienFX_Bridge.hpp"

@interface AppDelegate () <ScreenStateObserverDelegate>

@property (strong, nonatomic) ScreenStateObserver * screenObserver;
@property (nonatomic,strong) NSStatusItem *statusItem;

@end

@implementation AppDelegate

-(void)applicationWillFinishLaunching:(NSNotification *)notification {
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.screenObserver = [ScreenStateObserver new];
    self.screenObserver.delegate = self;
    
    int ret = [[AlienFX_Bridge sharedManager] initAlienFx];
    if (!ret) {
        NSLog(@"AlienFx initialize failed: %d, check the permission of Accesibility!", ret);
    }

    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
    NSStatusItem *statusItem = [statusBar statusItemWithLength: NSSquareStatusItemLength];
    self.statusItem = statusItem;
    [statusItem setHighlightMode:YES];
    [statusItem setImage: [NSImage imageNamed:@"MenuIcon"]];
    
    NSMenu *subMenu = [[NSMenu alloc] initWithTitle:@"Load_TEXT"];

    [subMenu addItemWithTitle:@"Keyboard Backlight:" action:nil keyEquivalent:@""];
    NSSlider *keyboardSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(0, 0, 200, 30)];
    [keyboardSlider setTarget:self];
    [keyboardSlider setContinuous:NO];
    [keyboardSlider setMinValue:0];
    [keyboardSlider setMaxValue:100];
    keyboardSlider.intValue = 35;
    [keyboardSlider setAction:@selector(OnKeyboardSlider:)];
    NSMenuItem *kbSliderMenuItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
    kbSliderMenuItem.view = keyboardSlider;
    [subMenu addItem:kbSliderMenuItem];
    
    [subMenu addItemWithTitle:@"Other Backlight:" action:nil keyEquivalent:@""];
    NSSlider *otherSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(0, 0, 200, 30)];
    [otherSlider setTarget:self];
    [otherSlider setContinuous:NO];
    [otherSlider setMinValue:0];
    [otherSlider setMaxValue:100];
    otherSlider.intValue = 50;
    [otherSlider setAction:@selector(OnOtherSlider:)];
    NSMenuItem *otherSliderMenuItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
    otherSliderMenuItem.view = otherSlider;
    [subMenu addItem:otherSliderMenuItem];
    
    [subMenu addItemWithTitle:@"Exit" action:@selector(OnExit) keyEquivalent:@"Q"];

    statusItem.menu = subMenu;
}

- (void)OnKeyboardSlider:(NSSlider *)sender
{
    NSLog(@"toggle keyboard brightness: %d", [sender intValue]);
    [[AlienFX_Bridge sharedManager] ToggleKeyboardBrightness:[sender intValue]];
}

- (void)OnOtherSlider:(NSSlider *)sender
{
    NSLog(@"toggle other brightness: %d", [sender intValue]);
    [[AlienFX_Bridge sharedManager] ToggleOtherBrightness:[sender intValue]];
}

- (void)OnExit
{
    [[NSApplication sharedApplication] terminate:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

#pragma mark -
#pragma mark Screen state observer delegate


- (void)screenDidSleep{
    [[AlienFX_Bridge sharedManager] TurnOffOnScreenOff];
    
}

- (void)screenDidWake {
    [[AlienFX_Bridge sharedManager] RestoreOnScreenOn];
    
}

@end
