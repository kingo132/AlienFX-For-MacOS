//
//  ScreenStateObserver.m
//  AutoMute
//
//  Created by Zac Cohan on 23/8/19.
//  Copyright © 2019 Zac Cohan. All rights reserved.
//

#import "ScreenStateObserver.h"

@implementation ScreenStateObserver

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [[NSWorkspace sharedWorkspace].notificationCenter addObserver:self selector:@selector(screensDidWake:) name:NSWorkspaceScreensDidWakeNotification object:nil];

        [[NSWorkspace sharedWorkspace].notificationCenter addObserver:self selector:@selector(screensDidSleep:) name:NSWorkspaceScreensDidSleepNotification object:nil];
        
        [[NSWorkspace sharedWorkspace].notificationCenter addObserver:self selector:@selector(computerSleep:) name:NSWorkspaceWillSleepNotification object:nil];
        
        [[NSWorkspace sharedWorkspace].notificationCenter addObserver:self selector:@selector(computerWake:) name:NSWorkspaceDidWakeNotification object:nil];

    }
    return self;
}

- (void)screensDidWake:(NSNotification *)note {
    
    [self.delegate screenDidWake];
    printf("screensDidWake\n");
    
}
- (void)screensDidSleep:(NSNotification *)note {
    
    [self.delegate screenDidSleep];
    printf("screensDidSleep\n");
}
- (void)computerSleep:(NSNotification *)note {
    
    [self.delegate computerSleep];
    printf("computerSleep\n");
}
- (void)computerWake:(NSNotification *)note {
    printf("computerWake\n");
    [self.delegate computerWake];
    
}

@end
