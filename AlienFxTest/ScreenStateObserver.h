//
//  ScreenStateObserver.h
//  AutoMute
//
//  Created by Zac Cohan on 23/8/19.
//  Copyright © 2019 Zac Cohan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ScreenStateObserverDelegate <NSObject>

- (void)screenDidWake;
- (void)screenDidSleep;

@end

@interface ScreenStateObserver : NSObject

@property (weak, nonatomic) id <ScreenStateObserverDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
