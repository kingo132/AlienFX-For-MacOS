//
//  RootViewController.h
//  MacOSHid
//
//  Created by Smile on 2019/3/18.
//  Copyright © 2019 mac. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RootViewController : NSViewController

@property (nonatomic, strong)NSWindow *mainWindow;

- (void)viewWillDisappear;

@end
