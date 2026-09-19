#import "ScreenStateObserver.h"

@implementation ScreenStateObserver

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSNotificationCenter *center = [NSWorkspace sharedWorkspace].notificationCenter;
        [center addObserver:self selector:@selector(screensDidWake:) name:NSWorkspaceScreensDidWakeNotification object:nil];
        [center addObserver:self selector:@selector(screensDidSleep:) name:NSWorkspaceScreensDidSleepNotification object:nil];
        [center addObserver:self selector:@selector(computerSleep:) name:NSWorkspaceWillSleepNotification object:nil];
        [center addObserver:self selector:@selector(computerWake:) name:NSWorkspaceDidWakeNotification object:nil];
        [center addObserver:self selector:@selector(sessionDidLockNotification:) name:NSWorkspaceSessionDidResignActiveNotification object:nil];
        [center addObserver:self selector:@selector(sessionDidUnlockNotification:) name:NSWorkspaceSessionDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSWorkspace sharedWorkspace].notificationCenter removeObserver:self];
}

- (void)screensDidWake:(NSNotification *)note
{
    [self.delegate screenDidWake];
}

- (void)screensDidSleep:(NSNotification *)note
{
    [self.delegate screenDidSleep];
}

- (void)computerSleep:(NSNotification *)note
{
    [self.delegate computerSleep];
}

- (void)computerWake:(NSNotification *)note
{
    [self.delegate computerWake];
}

- (void)sessionDidLockNotification:(NSNotification *)note
{
    [self.delegate sessionDidLock];
}

- (void)sessionDidUnlockNotification:(NSNotification *)note
{
    [self.delegate sessionDidUnlock];
}

@end
