//
//  AppDelegate.h
//  BonjourMenu
//
//  Created by Ford Parsons on 11/21/17.
//  Copyright © 2017 Ford Parsons. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FPNetServiceBrowser.h"
#import "NSNetService+Additions.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate, FPNetServiceTypeBrowserDelegate, FPNetServiceBrowserDelegate>
@end
