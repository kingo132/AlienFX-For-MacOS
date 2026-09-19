#import "AppDelegate.h"
#import "ScreenStateObserver.h"
#include "AlienFX_Bridge.hpp"

#import <IOKit/ps/IOPowerSources.h>
#import <IOKit/ps/IOPSKeys.h>
#import <Carbon/Carbon.h>
@import ServiceManagement;

static const NSTimeInterval kHIDWriteInterval = 0.080; // 12.5 Hz max while dragging.
static const NSInteger kMenuWidth = 360;
static const NSInteger kBrightnessStep = 10;
static const OSType kAFXHotKeySignature = 'AFXK';
static const UInt32 kAFXHotKeyBrightnessDown = 1;
static const UInt32 kAFXHotKeyBrightnessUp = 2;

static NSString * const kKeyboardBrightnessKey = @"KeyboardBrightness";
static NSString * const kChassisBrightnessKey = @"ChassisBrightness";
static NSString * const kActiveProfileKey = @"ActiveProfile";
static NSString * const kOffWithDisplayKey = @"OffWithDisplay";
static NSString * const kOffWhileLockedKey = @"OffWhileLocked";
static NSString * const kBatteryProfileEnabledKey = @"BatteryProfileEnabled";
static NSString * const kBatteryKeyboardBrightnessKey = @"BatteryKeyboardBrightness";
static NSString * const kBatteryChassisBrightnessKey = @"BatteryChassisBrightness";

static NSString * const kProfileDaily = @"Daily";
static NSString * const kProfileFocus = @"Focus";
static NSString * const kProfileNight = @"Night";
static NSString * const kProfileMovie = @"Movie";
static NSString * const kProfileOff = @"Lights Off";
static NSString * const kProfileCustom = @"Custom";

#pragma mark - Small menu views

@interface AFXHeaderView : NSView
@property (nonatomic, strong) NSTextField *titleLabel;
@property (nonatomic, strong) NSTextField *keyboardLabel;
@property (nonatomic, strong) NSTextField *chassisLabel;
@property (nonatomic, strong) NSTextField *colorsLabel;
@property (nonatomic, strong) NSTextField *modeLabel;
@end

@implementation AFXHeaderView

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        _titleLabel = [self labelWithFrame:NSMakeRect(18, 92, kMenuWidth - 36, 23)
                                       font:[NSFont systemFontOfSize:16 weight:NSFontWeightSemibold]
                                      color:NSColor.labelColor];
        _keyboardLabel = [self labelWithFrame:NSMakeRect(18, 68, kMenuWidth - 36, 19)
                                          font:[NSFont systemFontOfSize:13 weight:NSFontWeightRegular]
                                         color:NSColor.secondaryLabelColor];
        _chassisLabel = [self labelWithFrame:NSMakeRect(18, 47, kMenuWidth - 36, 19)
                                         font:[NSFont systemFontOfSize:13 weight:NSFontWeightRegular]
                                        color:NSColor.secondaryLabelColor];
        _colorsLabel = [self labelWithFrame:NSMakeRect(18, 26, kMenuWidth - 36, 19)
                                        font:[NSFont systemFontOfSize:13 weight:NSFontWeightRegular]
                                       color:NSColor.secondaryLabelColor];
        _modeLabel = [self labelWithFrame:NSMakeRect(18, 5, kMenuWidth - 36, 19)
                                      font:[NSFont systemFontOfSize:12.5 weight:NSFontWeightMedium]
                                     color:NSColor.secondaryLabelColor];

        [self addSubview:_titleLabel];
        [self addSubview:_keyboardLabel];
        [self addSubview:_chassisLabel];
        [self addSubview:_colorsLabel];
        [self addSubview:_modeLabel];
    }
    return self;
}

- (NSTextField *)labelWithFrame:(NSRect)frame font:(NSFont *)font color:(NSColor *)color
{
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    label.editable = NO;
    label.selectable = NO;
    label.bezeled = NO;
    label.drawsBackground = NO;
    label.font = font;
    label.textColor = color;
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    return label;
}

@end

@interface AFXBrightnessView : NSView
@property (nonatomic, strong) NSTextField *titleLabel;
@property (nonatomic, strong) NSTextField *valueLabel;
@property (nonatomic, strong) NSSlider *slider;
- (instancetype)initWithTitle:(NSString *)title target:(id)target action:(SEL)action;
- (void)setBrightness:(NSInteger)value;
@end

@implementation AFXBrightnessView

- (instancetype)initWithTitle:(NSString *)title target:(id)target action:(SEL)action
{
    self = [super initWithFrame:NSMakeRect(0, 0, kMenuWidth, 64)];
    if (self) {
        _titleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(18, 39, 250, 20)];
        _titleLabel.editable = NO;
        _titleLabel.selectable = NO;
        _titleLabel.bezeled = NO;
        _titleLabel.drawsBackground = NO;
        _titleLabel.font = [NSFont systemFontOfSize:13 weight:NSFontWeightMedium];
        _titleLabel.textColor = NSColor.labelColor;
        _titleLabel.stringValue = title;
        [self addSubview:_titleLabel];

        _valueLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(kMenuWidth - 92, 39, 74, 20)];
        _valueLabel.editable = NO;
        _valueLabel.selectable = NO;
        _valueLabel.bezeled = NO;
        _valueLabel.drawsBackground = NO;
        _valueLabel.alignment = NSTextAlignmentRight;
        _valueLabel.font = [NSFont monospacedDigitSystemFontOfSize:13 weight:NSFontWeightMedium];
        _valueLabel.textColor = NSColor.secondaryLabelColor;
        [self addSubview:_valueLabel];

        _slider = [[NSSlider alloc] initWithFrame:NSMakeRect(18, 8, kMenuWidth - 36, 28)];
        _slider.minValue = 0;
        _slider.maxValue = 100;
        _slider.numberOfTickMarks = 0;
        _slider.continuous = YES;
        _slider.target = target;
        _slider.action = action;
        [self addSubview:_slider];
    }
    return self;
}

- (void)setBrightness:(NSInteger)value
{
    NSInteger clamped = MAX(0, MIN(100, value));
    self.slider.integerValue = clamped;
    self.valueLabel.stringValue = [NSString stringWithFormat:@"%ld%%", (long)clamped];
}

@end

#pragma mark - App delegate

@interface AppDelegate () <ScreenStateObserverDelegate, NSMenuDelegate>

@property (strong, nonatomic) ScreenStateObserver *screenObserver;
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSMenu *statusMenu;
@property (nonatomic, strong) AFXHeaderView *headerView;
@property (nonatomic, strong) AFXBrightnessView *keyboardBrightnessView;
@property (nonatomic, strong) AFXBrightnessView *chassisBrightnessView;
@property (nonatomic, strong) NSMenu *profilesMenu;
@property (nonatomic, strong) NSMenu *automationMenu;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMenuItem *> *profileItems;
@property (nonatomic, strong) NSMenuItem *offWithDisplayItem;
@property (nonatomic, strong) NSMenuItem *offWhileLockedItem;
@property (nonatomic, strong) NSMenuItem *batteryProfileItem;
@property (nonatomic, strong) NSMenuItem *batteryProfileDescriptionItem;
@property (nonatomic, strong) NSMenuItem *launchAtLoginItem;
@property (nonatomic, strong) NSMenuItem *diagnosticsItem;

@property (nonatomic) EventHotKeyRef brightnessDownHotKey;
@property (nonatomic) EventHotKeyRef brightnessUpHotKey;
@property (nonatomic) EventHandlerRef hotKeyEventHandler;

@property (nonatomic) NSInteger desiredKeyboardBrightness;
@property (nonatomic) NSInteger desiredChassisBrightness;
@property (nonatomic) NSInteger effectiveKeyboardBrightness;
@property (nonatomic) NSInteger effectiveChassisBrightness;
@property (nonatomic, copy) NSString *activeProfile;

@property (nonatomic) BOOL displaySleeping;
@property (nonatomic) BOOL sessionLocked;
@property (nonatomic) BOOL computerSleeping;
@property (nonatomic) BOOL onBattery;

@property (nonatomic) NSTimeInterval lastKeyboardWrite;
@property (nonatomic) NSTimeInterval lastChassisWrite;
@property (nonatomic) NSInteger pendingKeyboardBrightness;
@property (nonatomic) NSInteger pendingChassisBrightness;
@property (nonatomic) BOOL keyboardWriteScheduled;
@property (nonatomic) BOOL chassisWriteScheduled;

@property (nonatomic) NSUInteger reconnectGeneration;
@property (nonatomic) NSInteger reconnectAttempt;
@property (nonatomic) CFRunLoopSourceRef powerSourceRunLoopSource;

- (void)powerSourceDidChange;
- (void)adjustKeyboardBrightnessByDelta:(NSInteger)delta;
- (void)registerGlobalHotKeys;
- (void)unregisterGlobalHotKeys;
- (BOOL)isRunningFromApplicationsFolder;
- (NSString *)launchAtLoginStatusText;

@end

static void AFXPowerSourceChanged(void *context)
{
    AppDelegate *delegate = (__bridge AppDelegate *)context;
    dispatch_async(dispatch_get_main_queue(), ^{
        [delegate powerSourceDidChange];
    });
}

static OSStatus AFXHotKeyPressed(EventHandlerCallRef nextHandler, EventRef event, void *userData)
{
    EventHotKeyID hotKeyID = {0};
    OSStatus status = GetEventParameter(event,
                                        kEventParamDirectObject,
                                        typeEventHotKeyID,
                                        NULL,
                                        sizeof(hotKeyID),
                                        NULL,
                                        &hotKeyID);
    if (status != noErr || hotKeyID.signature != kAFXHotKeySignature) {
        return eventNotHandledErr;
    }

    AppDelegate *delegate = (__bridge AppDelegate *)userData;
    NSInteger delta = 0;
    if (hotKeyID.id == kAFXHotKeyBrightnessDown) {
        delta = -kBrightnessStep;
    } else if (hotKeyID.id == kAFXHotKeyBrightnessUp) {
        delta = kBrightnessStep;
    } else {
        return eventNotHandledErr;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [delegate adjustKeyboardBrightnessByDelta:delta];
    });
    return noErr;
}

@implementation AppDelegate

#pragma mark Lifecycle

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [self registerDefaults];
    [self loadSavedState];

    self.screenObserver = [ScreenStateObserver new];
    self.screenObserver.delegate = self;

    [self startPowerSourceMonitoring];
    [[AlienFX_Bridge sharedManager] initAlienFx];

    [self buildStatusMenu];
    [self registerGlobalHotKeys];
    [self refreshMenuState];
    [self applyEffectiveBrightnessImmediate:YES];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [self unregisterGlobalHotKeys];
    self.reconnectGeneration++;
    if (self.powerSourceRunLoopSource) {
        CFRunLoopRemoveSource(CFRunLoopGetMain(), self.powerSourceRunLoopSource, kCFRunLoopDefaultMode);
        CFRelease(self.powerSourceRunLoopSource);
        self.powerSourceRunLoopSource = NULL;
    }
    [[AlienFX_Bridge sharedManager] uninitAlienFx];
}

#pragma mark Defaults / profiles

- (void)registerDefaults
{
    NSDictionary *defaults = @{
        kKeyboardBrightnessKey: @35,
        kChassisBrightnessKey: @50,
        kActiveProfileKey: kProfileCustom,
        kOffWithDisplayKey: @YES,
        kOffWhileLockedKey: @YES,
        kBatteryProfileEnabledKey: @NO,
        kBatteryKeyboardBrightnessKey: @15,
        kBatteryChassisBrightnessKey: @0,

        [self keyboardKeyForProfile:kProfileDaily]: @35,
        [self chassisKeyForProfile:kProfileDaily]: @35,
        [self keyboardKeyForProfile:kProfileFocus]: @25,
        [self chassisKeyForProfile:kProfileFocus]: @0,
        [self keyboardKeyForProfile:kProfileNight]: @12,
        [self chassisKeyForProfile:kProfileNight]: @0,
        [self keyboardKeyForProfile:kProfileMovie]: @5,
        [self chassisKeyForProfile:kProfileMovie]: @0,
        [self keyboardKeyForProfile:kProfileOff]: @0,
        [self chassisKeyForProfile:kProfileOff]: @0,
    };
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (void)loadSavedState
{
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    self.desiredKeyboardBrightness = [defaults integerForKey:kKeyboardBrightnessKey];
    self.desiredChassisBrightness = [defaults integerForKey:kChassisBrightnessKey];
    self.activeProfile = [defaults stringForKey:kActiveProfileKey] ?: kProfileCustom;
    self.pendingKeyboardBrightness = self.desiredKeyboardBrightness;
    self.pendingChassisBrightness = self.desiredChassisBrightness;
}

- (NSString *)keyboardKeyForProfile:(NSString *)profile
{
    return [NSString stringWithFormat:@"Profile.%@.Keyboard", profile];
}

- (NSString *)chassisKeyForProfile:(NSString *)profile
{
    return [NSString stringWithFormat:@"Profile.%@.Chassis", profile];
}

- (NSArray<NSString *> *)profileNames
{
    return @[kProfileDaily, kProfileFocus, kProfileNight, kProfileMovie, kProfileOff];
}

#pragma mark Menu construction

- (void)buildStatusMenu
{
    self.statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.button.image = [NSImage imageNamed:@"MenuIcon"];
    self.statusItem.button.image.template = YES;
    self.statusItem.button.toolTip = @"AlienFX for macOS";

    self.statusMenu = [[NSMenu alloc] initWithTitle:@"AlienFX"];
    self.statusMenu.delegate = self;

    NSMenuItem *headerItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
    self.headerView = [[AFXHeaderView alloc] initWithFrame:NSMakeRect(0, 0, kMenuWidth, 120)];
    headerItem.view = self.headerView;
    [self.statusMenu addItem:headerItem];

    [self.statusMenu addItem:NSMenuItem.separatorItem];

    NSMenuItem *keyboardItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
    self.keyboardBrightnessView = [[AFXBrightnessView alloc] initWithTitle:@"Keyboard Brightness"
                                                                    target:self
                                                                    action:@selector(keyboardSliderChanged:)];
    keyboardItem.view = self.keyboardBrightnessView;
    [self.statusMenu addItem:keyboardItem];

    NSMenuItem *chassisItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
    self.chassisBrightnessView = [[AFXBrightnessView alloc] initWithTitle:@"Chassis / Logo Brightness"
                                                                   target:self
                                                                   action:@selector(chassisSliderChanged:)];
    chassisItem.view = self.chassisBrightnessView;
    [self.statusMenu addItem:chassisItem];

    [self.statusMenu addItem:NSMenuItem.separatorItem];

    self.profilesMenu = [[NSMenu alloc] initWithTitle:@"Presets"];
    self.profileItems = [NSMutableDictionary dictionary];
    for (NSString *profile in [self profileNames]) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:profile action:@selector(applyProfileFromMenu:) keyEquivalent:@""];
        item.target = self;
        item.representedObject = profile;
        [self.profilesMenu addItem:item];
        self.profileItems[profile] = item;
    }

    [self.profilesMenu addItem:NSMenuItem.separatorItem];

    NSString *f5Key = [NSString stringWithFormat:@"%C", NSF5FunctionKey];
    NSMenuItem *brightnessDownItem = [[NSMenuItem alloc] initWithTitle:@"Keyboard Brightness −10%"
                                                                  action:@selector(decreaseKeyboardBrightness:)
                                                           keyEquivalent:f5Key];
    brightnessDownItem.keyEquivalentModifierMask = NSEventModifierFlagControl | NSEventModifierFlagOption;
    brightnessDownItem.target = self;
    [self.profilesMenu addItem:brightnessDownItem];

    NSString *f6Key = [NSString stringWithFormat:@"%C", NSF6FunctionKey];
    NSMenuItem *brightnessUpItem = [[NSMenuItem alloc] initWithTitle:@"Keyboard Brightness +10%"
                                                                action:@selector(increaseKeyboardBrightness:)
                                                         keyEquivalent:f6Key];
    brightnessUpItem.keyEquivalentModifierMask = NSEventModifierFlagControl | NSEventModifierFlagOption;
    brightnessUpItem.target = self;
    [self.profilesMenu addItem:brightnessUpItem];

    [self.profilesMenu addItem:NSMenuItem.separatorItem];
    NSMenuItem *saveAsItem = [[NSMenuItem alloc] initWithTitle:@"Save Current As" action:nil keyEquivalent:@""];
    NSMenu *saveAsMenu = [[NSMenu alloc] initWithTitle:@"Save Current As"];
    for (NSString *profile in @[kProfileDaily, kProfileFocus, kProfileNight, kProfileMovie]) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:profile action:@selector(saveCurrentAsProfile:) keyEquivalent:@""];
        item.target = self;
        item.representedObject = profile;
        [saveAsMenu addItem:item];
    }
    saveAsItem.submenu = saveAsMenu;
    [self.profilesMenu addItem:saveAsItem];

    NSMenuItem *profilesItem = [[NSMenuItem alloc] initWithTitle:@"Brightness Presets" action:nil keyEquivalent:@""];
    profilesItem.submenu = self.profilesMenu;
    [self.statusMenu addItem:profilesItem];

    self.automationMenu = [[NSMenu alloc] initWithTitle:@"Automation"];

    self.offWithDisplayItem = [[NSMenuItem alloc] initWithTitle:@"Turn lights off with display"
                                                         action:@selector(toggleOffWithDisplay:)
                                                  keyEquivalent:@""];
    self.offWithDisplayItem.target = self;
    [self.automationMenu addItem:self.offWithDisplayItem];

    self.offWhileLockedItem = [[NSMenuItem alloc] initWithTitle:@"Turn lights off while locked"
                                                         action:@selector(toggleOffWhileLocked:)
                                                  keyEquivalent:@""];
    self.offWhileLockedItem.target = self;
    [self.automationMenu addItem:self.offWhileLockedItem];

    [self.automationMenu addItem:NSMenuItem.separatorItem];

    self.batteryProfileItem = [[NSMenuItem alloc] initWithTitle:@"Use Battery Saver"
                                                         action:@selector(toggleBatteryProfile:)
                                                  keyEquivalent:@""];
    self.batteryProfileItem.target = self;
    [self.automationMenu addItem:self.batteryProfileItem];

    self.batteryProfileDescriptionItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
    self.batteryProfileDescriptionItem.enabled = NO;
    [self.automationMenu addItem:self.batteryProfileDescriptionItem];

    NSMenuItem *saveBatteryItem = [[NSMenuItem alloc] initWithTitle:@"Save Current as Battery Saver"
                                                             action:@selector(saveCurrentAsBatteryProfile:)
                                                      keyEquivalent:@""];
    saveBatteryItem.target = self;
    [self.automationMenu addItem:saveBatteryItem];

    [self.automationMenu addItem:NSMenuItem.separatorItem];

    self.launchAtLoginItem = [[NSMenuItem alloc] initWithTitle:@"Launch at Login"
                                                        action:@selector(toggleLaunchAtLogin:)
                                                 keyEquivalent:@""];
    self.launchAtLoginItem.target = self;
    [self.automationMenu addItem:self.launchAtLoginItem];

    NSMenuItem *automationItem = [[NSMenuItem alloc] initWithTitle:@"Automation" action:nil keyEquivalent:@""];
    automationItem.submenu = self.automationMenu;
    [self.statusMenu addItem:automationItem];

    [self.statusMenu addItem:NSMenuItem.separatorItem];

    NSMenuItem *reconnectItem = [[NSMenuItem alloc] initWithTitle:@"Reconnect AlienFX"
                                                           action:@selector(reconnectAlienFX:)
                                                    keyEquivalent:@"r"];
    reconnectItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    reconnectItem.target = self;
    [self.statusMenu addItem:reconnectItem];

    self.diagnosticsItem = [[NSMenuItem alloc] initWithTitle:@"Copy Diagnostics"
                                                       action:@selector(copyDiagnostics:)
                                                keyEquivalent:@""];
    self.diagnosticsItem.target = self;
    [self.statusMenu addItem:self.diagnosticsItem];

    [self.statusMenu addItem:NSMenuItem.separatorItem];

    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit AlienFX"
                                                      action:@selector(quitApp:)
                                               keyEquivalent:@"q"];
    quitItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    quitItem.target = self;
    [self.statusMenu addItem:quitItem];

    self.statusItem.menu = self.statusMenu;
}

- (void)menuWillOpen:(NSMenu *)menu
{
    if (menu == self.statusMenu) {
        [self refreshMenuState];
        AlienFX_Bridge *bridge = AlienFX_Bridge.sharedManager;
        if (!self.computerSleeping && (![bridge keyboardConnected] || ![bridge chassisConnected])) {
            [self scheduleReconnectStartingAtAttempt:0 delay:0.15];
        }
    }
}

#pragma mark Slider handling / HID throttling

- (void)keyboardSliderChanged:(NSSlider *)sender
{
    self.desiredKeyboardBrightness = sender.integerValue;
    self.activeProfile = kProfileCustom;
    [self persistDesiredState];
    [self.keyboardBrightnessView setBrightness:self.desiredKeyboardBrightness];
    [self updateHeader];
    [self applyEffectiveBrightnessImmediate:NO];
}

- (void)chassisSliderChanged:(NSSlider *)sender
{
    self.desiredChassisBrightness = sender.integerValue;
    self.activeProfile = kProfileCustom;
    [self persistDesiredState];
    [self.chassisBrightnessView setBrightness:self.desiredChassisBrightness];
    [self updateHeader];
    [self applyEffectiveBrightnessImmediate:NO];
}

- (void)persistDesiredState
{
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setInteger:self.desiredKeyboardBrightness forKey:kKeyboardBrightnessKey];
    [defaults setInteger:self.desiredChassisBrightness forKey:kChassisBrightnessKey];
    [defaults setObject:self.activeProfile forKey:kActiveProfileKey];
}

- (void)sendKeyboardBrightnessThrottled:(NSInteger)value immediate:(BOOL)immediate
{
    self.pendingKeyboardBrightness = value;
    if (self.computerSleeping) return;

    NSTimeInterval now = NSProcessInfo.processInfo.systemUptime;
    NSTimeInterval elapsed = now - self.lastKeyboardWrite;
    if (immediate || elapsed >= kHIDWriteInterval) {
        self.keyboardWriteScheduled = NO;
        self.lastKeyboardWrite = now;
        [[AlienFX_Bridge sharedManager] setKeyboardBrightness:(uint8_t)value];
        return;
    }

    if (self.keyboardWriteScheduled) return;
    self.keyboardWriteScheduled = YES;
    NSTimeInterval delay = MAX(0.001, kHIDWriteInterval - elapsed);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.keyboardWriteScheduled = NO;
        if (self.computerSleeping) return;
        self.lastKeyboardWrite = NSProcessInfo.processInfo.systemUptime;
        [[AlienFX_Bridge sharedManager] setKeyboardBrightness:(uint8_t)self.pendingKeyboardBrightness];
    });
}

- (void)sendChassisBrightnessThrottled:(NSInteger)value immediate:(BOOL)immediate
{
    self.pendingChassisBrightness = value;
    if (self.computerSleeping) return;

    NSTimeInterval now = NSProcessInfo.processInfo.systemUptime;
    NSTimeInterval elapsed = now - self.lastChassisWrite;
    if (immediate || elapsed >= kHIDWriteInterval) {
        self.chassisWriteScheduled = NO;
        self.lastChassisWrite = now;
        [[AlienFX_Bridge sharedManager] setChassisBrightness:(uint8_t)value];
        return;
    }

    if (self.chassisWriteScheduled) return;
    self.chassisWriteScheduled = YES;
    NSTimeInterval delay = MAX(0.001, kHIDWriteInterval - elapsed);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.chassisWriteScheduled = NO;
        if (self.computerSleeping) return;
        self.lastChassisWrite = NSProcessInfo.processInfo.systemUptime;
        [[AlienFX_Bridge sharedManager] setChassisBrightness:(uint8_t)self.pendingChassisBrightness];
    });
}

#pragma mark Effective state

- (BOOL)shouldForceLightsOff
{
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    BOOL displayReason = self.displaySleeping && [defaults boolForKey:kOffWithDisplayKey];
    BOOL lockReason = self.sessionLocked && [defaults boolForKey:kOffWhileLockedKey];
    return displayReason || lockReason;
}

- (void)calculateEffectiveKeyboard:(NSInteger *)keyboard chassis:(NSInteger *)chassis
{
    if ([self shouldForceLightsOff]) {
        *keyboard = 0;
        *chassis = 0;
        return;
    }

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if (self.onBattery && [defaults boolForKey:kBatteryProfileEnabledKey]) {
        *keyboard = [defaults integerForKey:kBatteryKeyboardBrightnessKey];
        *chassis = [defaults integerForKey:kBatteryChassisBrightnessKey];
        return;
    }

    *keyboard = self.desiredKeyboardBrightness;
    *chassis = self.desiredChassisBrightness;
}

- (void)applyEffectiveBrightnessImmediate:(BOOL)immediate
{
    NSInteger keyboard = 0;
    NSInteger chassis = 0;
    [self calculateEffectiveKeyboard:&keyboard chassis:&chassis];
    self.effectiveKeyboardBrightness = keyboard;
    self.effectiveChassisBrightness = chassis;

    AlienFX_Bridge *bridge = AlienFX_Bridge.sharedManager;
    if ([bridge keyboardConnected]) {
        [self sendKeyboardBrightnessThrottled:keyboard immediate:immediate];
    }
    if ([bridge chassisConnected]) {
        [self sendChassisBrightnessThrottled:chassis immediate:immediate];
    }

    if (!self.computerSleeping && (![bridge keyboardConnected] || ![bridge chassisConnected])) {
        [self scheduleReconnectStartingAtAttempt:0 delay:0.25];
    }

    [self updateHeader];
}

#pragma mark Presets

- (void)applyProfileFromMenu:(NSMenuItem *)sender
{
    NSString *profile = sender.representedObject;
    if (![profile isKindOfClass:NSString.class]) return;

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    self.desiredKeyboardBrightness = [defaults integerForKey:[self keyboardKeyForProfile:profile]];
    self.desiredChassisBrightness = [defaults integerForKey:[self chassisKeyForProfile:profile]];
    self.activeProfile = profile;
    [self persistDesiredState];
    [self refreshSliderValues];
    [self applyEffectiveBrightnessImmediate:YES];
    [self refreshMenuState];
}

- (void)saveCurrentAsProfile:(NSMenuItem *)sender
{
    NSString *profile = sender.representedObject;
    if (![profile isKindOfClass:NSString.class]) return;

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setInteger:self.desiredKeyboardBrightness forKey:[self keyboardKeyForProfile:profile]];
    [defaults setInteger:self.desiredChassisBrightness forKey:[self chassisKeyForProfile:profile]];
    self.activeProfile = profile;
    [self persistDesiredState];
    [self refreshMenuState];
}

#pragma mark Automation actions

- (void)toggleOffWithDisplay:(NSMenuItem *)sender
{
    BOOL enabled = ![NSUserDefaults.standardUserDefaults boolForKey:kOffWithDisplayKey];
    [NSUserDefaults.standardUserDefaults setBool:enabled forKey:kOffWithDisplayKey];
    [self applyEffectiveBrightnessImmediate:YES];
    [self refreshAutomationMenu];
}

- (void)toggleOffWhileLocked:(NSMenuItem *)sender
{
    BOOL enabled = ![NSUserDefaults.standardUserDefaults boolForKey:kOffWhileLockedKey];
    [NSUserDefaults.standardUserDefaults setBool:enabled forKey:kOffWhileLockedKey];
    [self applyEffectiveBrightnessImmediate:YES];
    [self refreshAutomationMenu];
}

- (void)toggleBatteryProfile:(NSMenuItem *)sender
{
    BOOL enabled = ![NSUserDefaults.standardUserDefaults boolForKey:kBatteryProfileEnabledKey];
    [NSUserDefaults.standardUserDefaults setBool:enabled forKey:kBatteryProfileEnabledKey];
    [self applyEffectiveBrightnessImmediate:YES];
    [self refreshAutomationMenu];
}

- (void)saveCurrentAsBatteryProfile:(NSMenuItem *)sender
{
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setInteger:self.desiredKeyboardBrightness forKey:kBatteryKeyboardBrightnessKey];
    [defaults setInteger:self.desiredChassisBrightness forKey:kBatteryChassisBrightnessKey];
    if (self.onBattery && [defaults boolForKey:kBatteryProfileEnabledKey]) {
        [self applyEffectiveBrightnessImmediate:YES];
    }
    [self refreshAutomationMenu];
}

- (void)toggleLaunchAtLogin:(NSMenuItem *)sender
{
    SMAppService *service = SMAppService.mainAppService;
    NSError *error = nil;

    BOOL currentlyEnabled = service.status == SMAppServiceStatusEnabled || service.status == SMAppServiceStatusRequiresApproval;
    if (!currentlyEnabled && ![self isRunningFromApplicationsFolder]) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Move AlienFX to Applications first";
        alert.informativeText = @"Launch at Login is most reliable when AlienFX.app is installed in /Applications (or ~/Applications). Move the app there, reopen it, then enable this option.";
        [alert addButtonWithTitle:@"OK"];
        [alert addButtonWithTitle:@"Open Applications"];
        NSModalResponse response = [alert runModal];
        if (response == NSAlertSecondButtonReturn) {
            [NSWorkspace.sharedWorkspace openURL:[NSURL fileURLWithPath:@"/Applications" isDirectory:YES]];
        }
        [self refreshAutomationMenu];
        return;
    }

    BOOL success = currentlyEnabled ? [service unregisterAndReturnError:&error] : [service registerAndReturnError:&error];

    if (!success && error) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Could not change Launch at Login";
        alert.informativeText = error.localizedDescription ?: @"Unknown ServiceManagement error.";
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    } else if (service.status == SMAppServiceStatusRequiresApproval) {
        [SMAppService openSystemSettingsLoginItems];
    }
    [self refreshAutomationMenu];
}

- (BOOL)isRunningFromApplicationsFolder
{
    NSString *bundlePath = NSBundle.mainBundle.bundlePath.stringByStandardizingPath;
    NSString *userApplications = [[NSHomeDirectory() stringByAppendingPathComponent:@"Applications"] stringByStandardizingPath];
    return [bundlePath hasPrefix:@"/Applications/"] ||
           [bundlePath hasPrefix:[userApplications stringByAppendingString:@"/"]];
}

- (NSString *)launchAtLoginStatusText
{
    SMAppServiceStatus status = SMAppService.mainAppService.status;
    if (status == SMAppServiceStatusEnabled) return @"On";
    if (status == SMAppServiceStatusRequiresApproval) return @"Needs approval";
    if (![self isRunningFromApplicationsFolder]) return @"Off (app not in Applications)";
    return @"Off";
}

#pragma mark Keyboard brightness shortcuts

- (void)decreaseKeyboardBrightness:(id)sender
{
    [self adjustKeyboardBrightnessByDelta:-kBrightnessStep];
}

- (void)increaseKeyboardBrightness:(id)sender
{
    [self adjustKeyboardBrightnessByDelta:kBrightnessStep];
}

- (void)adjustKeyboardBrightnessByDelta:(NSInteger)delta
{
    NSInteger newValue = MAX(0, MIN(100, self.desiredKeyboardBrightness + delta));
    if (newValue == self.desiredKeyboardBrightness) return;

    self.desiredKeyboardBrightness = newValue;
    self.activeProfile = kProfileCustom;
    [self persistDesiredState];
    [self.keyboardBrightnessView setBrightness:newValue];
    [self applyEffectiveBrightnessImmediate:YES];
    [self refreshProfileMenu];
}

- (void)registerGlobalHotKeys
{
    EventTypeSpec hotKeyEvent = {kEventClassKeyboard, kEventHotKeyPressed};
    OSStatus handlerStatus = InstallApplicationEventHandler(&AFXHotKeyPressed,
                                                            1,
                                                            &hotKeyEvent,
                                                            (__bridge void *)self,
                                                            &_hotKeyEventHandler);
    if (handlerStatus != noErr) {
        self.hotKeyEventHandler = NULL;
        return;
    }

    EventHotKeyID downID = {kAFXHotKeySignature, kAFXHotKeyBrightnessDown};
    EventHotKeyID upID = {kAFXHotKeySignature, kAFXHotKeyBrightnessUp};

    OSStatus downStatus = RegisterEventHotKey(kVK_F5,
                                               controlKey | optionKey,
                                               downID,
                                               GetApplicationEventTarget(),
                                               0,
                                               &_brightnessDownHotKey);
    OSStatus upStatus = RegisterEventHotKey(kVK_F6,
                                             controlKey | optionKey,
                                             upID,
                                             GetApplicationEventTarget(),
                                             0,
                                             &_brightnessUpHotKey);

    if (downStatus != noErr) self.brightnessDownHotKey = NULL;
    if (upStatus != noErr) self.brightnessUpHotKey = NULL;
}

- (void)unregisterGlobalHotKeys
{
    if (self.brightnessDownHotKey) {
        UnregisterEventHotKey(self.brightnessDownHotKey);
        self.brightnessDownHotKey = NULL;
    }
    if (self.brightnessUpHotKey) {
        UnregisterEventHotKey(self.brightnessUpHotKey);
        self.brightnessUpHotKey = NULL;
    }
    if (self.hotKeyEventHandler) {
        RemoveEventHandler(self.hotKeyEventHandler);
        self.hotKeyEventHandler = NULL;
    }
}

#pragma mark Power source

- (void)startPowerSourceMonitoring
{
    self.onBattery = [self queryOnBattery];
    self.powerSourceRunLoopSource = IOPSNotificationCreateRunLoopSource(AFXPowerSourceChanged, (__bridge void *)self);
    if (self.powerSourceRunLoopSource) {
        CFRunLoopAddSource(CFRunLoopGetMain(), self.powerSourceRunLoopSource, kCFRunLoopDefaultMode);
    }
}

- (BOOL)queryOnBattery
{
    CFTypeRef snapshot = IOPSCopyPowerSourcesInfo();
    if (!snapshot) return NO;
    CFStringRef type = IOPSGetProvidingPowerSourceType(snapshot);
    BOOL battery = type && CFStringCompare(type, CFSTR(kIOPSBatteryPowerValue), 0) == kCFCompareEqualTo;
    CFRelease(snapshot);
    return battery;
}

- (void)powerSourceDidChange
{
    BOOL newOnBattery = [self queryOnBattery];
    if (newOnBattery == self.onBattery) return;
    self.onBattery = newOnBattery;
    [self applyEffectiveBrightnessImmediate:YES];
    [self refreshMenuState];
}

#pragma mark Sleep / lock state machine

- (void)screenDidSleep
{
    self.displaySleeping = YES;
    [self applyEffectiveBrightnessImmediate:YES];
}

- (void)screenDidWake
{
    self.displaySleeping = NO;
    [self applyEffectiveBrightnessImmediate:YES];
}

- (void)sessionDidLock
{
    self.sessionLocked = YES;
    [self applyEffectiveBrightnessImmediate:YES];
}

- (void)sessionDidUnlock
{
    self.sessionLocked = NO;
    [self applyEffectiveBrightnessImmediate:YES];
}

- (void)computerSleep
{
    self.computerSleeping = YES;
    self.reconnectGeneration++;
    [[AlienFX_Bridge sharedManager] uninitAlienFx];
    [self updateHeader];
}

- (void)computerWake
{
    self.computerSleeping = NO;
    [self scheduleReconnectStartingAtAttempt:0 delay:1.0];
}

#pragma mark Reconnect

- (void)reconnectAlienFX:(id)sender
{
    [self scheduleReconnectStartingAtAttempt:0 delay:0.0];
}

- (void)scheduleReconnectStartingAtAttempt:(NSInteger)attempt delay:(NSTimeInterval)delay
{
    if (self.computerSleeping) return;
    NSUInteger generation = ++self.reconnectGeneration;
    self.reconnectAttempt = attempt;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (generation != self.reconnectGeneration || self.computerSleeping) return;
        [self performReconnectAttempt:attempt generation:generation];
    });
}

- (void)performReconnectAttempt:(NSInteger)attempt generation:(NSUInteger)generation
{
    if (generation != self.reconnectGeneration || self.computerSleeping) return;

    [[AlienFX_Bridge sharedManager] initAlienFx];
    [self refreshMenuState];

    AlienFX_Bridge *bridge = AlienFX_Bridge.sharedManager;
    if ([bridge keyboardConnected] && [bridge chassisConnected]) {
        self.reconnectAttempt = attempt;
        [self applyEffectiveBrightnessImmediate:YES];
        return;
    }

    if (attempt >= 4) return;
    static const NSTimeInterval delays[] = {1.0, 2.0, 3.0, 5.0, 8.0};
    NSTimeInterval nextDelay = delays[MIN((NSInteger)4, attempt + 1)];
    self.reconnectAttempt = attempt + 1;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(nextDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (generation != self.reconnectGeneration || self.computerSleeping) return;
        [self performReconnectAttempt:attempt + 1 generation:generation];
    });
}

#pragma mark Menu refresh

- (void)refreshSliderValues
{
    [self.keyboardBrightnessView setBrightness:self.desiredKeyboardBrightness];
    [self.chassisBrightnessView setBrightness:self.desiredChassisBrightness];
}

- (void)refreshMenuState
{
    [self refreshSliderValues];
    [self updateHeader];
    [self refreshProfileMenu];
    [self refreshAutomationMenu];
}

- (void)refreshProfileMenu
{
    for (NSString *profile in self.profileItems) {
        self.profileItems[profile].state = [self.activeProfile isEqualToString:profile] ? NSControlStateValueOn : NSControlStateValueOff;
    }
}

- (void)refreshAutomationMenu
{
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    self.offWithDisplayItem.state = [defaults boolForKey:kOffWithDisplayKey] ? NSControlStateValueOn : NSControlStateValueOff;
    self.offWhileLockedItem.state = [defaults boolForKey:kOffWhileLockedKey] ? NSControlStateValueOn : NSControlStateValueOff;
    self.batteryProfileItem.state = [defaults boolForKey:kBatteryProfileEnabledKey] ? NSControlStateValueOn : NSControlStateValueOff;

    NSInteger batteryKeyboard = [defaults integerForKey:kBatteryKeyboardBrightnessKey];
    NSInteger batteryChassis = [defaults integerForKey:kBatteryChassisBrightnessKey];
    self.batteryProfileDescriptionItem.title = [NSString stringWithFormat:@"Battery Saver: keyboard %ld%% • chassis %ld%%",
                                                 (long)batteryKeyboard, (long)batteryChassis];

    SMAppServiceStatus status = SMAppService.mainAppService.status;
    self.launchAtLoginItem.state = (status == SMAppServiceStatusEnabled || status == SMAppServiceStatusRequiresApproval)
        ? NSControlStateValueOn : NSControlStateValueOff;
    if (status == SMAppServiceStatusRequiresApproval) {
        self.launchAtLoginItem.title = @"Launch at Login (approval needed)";
    } else if (![self isRunningFromApplicationsFolder] && status != SMAppServiceStatusEnabled) {
        self.launchAtLoginItem.title = @"Launch at Login (move app to Applications)";
    } else {
        self.launchAtLoginItem.title = @"Launch at Login";
    }
}

- (void)updateHeader
{
    AlienFX_Bridge *bridge = AlienFX_Bridge.sharedManager;
    self.headerView.titleLabel.stringValue = @"AlienFX · Area-51m R2";
    self.headerView.keyboardLabel.stringValue = [NSString stringWithFormat:@"Keyboard: %@ · API v5",
                                                  [bridge keyboardConnected] ? @"Connected" : @"Disconnected"];
    self.headerView.chassisLabel.stringValue = [NSString stringWithFormat:@"Chassis: %@ · API v4",
                                                 [bridge chassisConnected] ? @"Connected" : @"Disconnected"];
    self.headerView.colorsLabel.stringValue = @"Colors: Windows/AWCC · preserved";

    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    [parts addObject:[NSString stringWithFormat:@"%@", self.activeProfile ?: kProfileCustom]];
    if ([self shouldForceLightsOff]) {
        [parts addObject:@"temporarily off"];
    } else if (self.onBattery && [NSUserDefaults.standardUserDefaults boolForKey:kBatteryProfileEnabledKey]) {
        [parts addObject:[NSString stringWithFormat:@"battery %ld%% / %ld%%",
                          (long)self.effectiveKeyboardBrightness, (long)self.effectiveChassisBrightness]];
    } else {
        [parts addObject:[NSString stringWithFormat:@"effective %ld%% / %ld%%",
                          (long)self.effectiveKeyboardBrightness, (long)self.effectiveChassisBrightness]];
    }
    self.headerView.modeLabel.stringValue = [NSString stringWithFormat:@"Profile: %@", [parts componentsJoinedByString:@" · "]];
}

#pragma mark Diagnostics / quit

- (void)copyDiagnostics:(id)sender
{
    AlienFX_Bridge *bridge = AlienFX_Bridge.sharedManager;
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSString *loginText = [self launchAtLoginStatusText];
    NSString *version = [NSString stringWithFormat:@"%@ (%@)",
                         [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"unknown",
                         [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"unknown"];

    NSString *diagnostics = [NSString stringWithFormat:
        @"AlienFX for macOS Diagnostics\n"
         "Version: %@\n\n"
         "Keyboard: %@ (VID 0x0D62, PID 0x1A1C, API v5, init=%d)\n"
         "Chassis: %@ (VID 0x187C, PID 0x0550, API v4, init=%d)\n\n"
         "Windows/AWCC per-key RGB writes: DISABLED\n"
         "Global RGB effects: DISABLED\n"
         "Color baseline: hardware/Windows profile is intentionally untouched\n\n"
         "Base keyboard brightness: %ld%%\n"
         "Base chassis brightness: %ld%%\n"
         "Effective keyboard brightness: %ld%%\n"
         "Effective chassis brightness: %ld%%\n"
         "Brightness preview: live, HID writes throttled to %.0f ms\n"
         "Active profile: %@\n\n"
         "Display sleeping: %@\n"
         "Session locked: %@\n"
         "Computer sleeping: %@\n"
         "Power source: %@\n"
         "Battery Saver: %@ (%ld%% / %ld%%)\n"
         "Off with display: %@\n"
         "Off while locked: %@\n"
         "Launch at Login: %@\n"
         "Global keyboard shortcuts: %@ · Ctrl+Option+F5 / Ctrl+Option+F6 (−/+ %ld%%)\n"
         "Reconnect attempt: %ld\n",
        version,
        [bridge keyboardConnected] ? @"Connected" : @"Disconnected", [bridge keyboardInitStatus],
        [bridge chassisConnected] ? @"Connected" : @"Disconnected", [bridge chassisInitStatus],
        (long)self.desiredKeyboardBrightness,
        (long)self.desiredChassisBrightness,
        (long)self.effectiveKeyboardBrightness,
        (long)self.effectiveChassisBrightness,
        kHIDWriteInterval * 1000.0,
        self.activeProfile ?: kProfileCustom,
        self.displaySleeping ? @"yes" : @"no",
        self.sessionLocked ? @"yes" : @"no",
        self.computerSleeping ? @"yes" : @"no",
        self.onBattery ? @"Battery" : @"AC",
        [defaults boolForKey:kBatteryProfileEnabledKey] ? @"enabled" : @"disabled",
        (long)[defaults integerForKey:kBatteryKeyboardBrightnessKey],
        (long)[defaults integerForKey:kBatteryChassisBrightnessKey],
        [defaults boolForKey:kOffWithDisplayKey] ? @"enabled" : @"disabled",
        [defaults boolForKey:kOffWhileLockedKey] ? @"enabled" : @"disabled",
        loginText,
        (self.brightnessDownHotKey && self.brightnessUpHotKey) ? @"registered" : @"unavailable",
        (long)kBrightnessStep,
        (long)self.reconnectAttempt];

    NSPasteboard *pasteboard = NSPasteboard.generalPasteboard;
    [pasteboard clearContents];
    [pasteboard setString:diagnostics forType:NSPasteboardTypeString];

    self.diagnosticsItem.title = @"Diagnostics Copied ✓";
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.diagnosticsItem.title = @"Copy Diagnostics";
    });
}

- (void)quitApp:(id)sender
{
    [NSApp terminate:nil];
}

@end
