//
//  FPNetServiceBrowser.h
//  BonjourMenu
//
//  Created by Ford Parsons on 12/12/17.
//  Copyright © 2017 Ford Parsons. All rights reserved.
//
// http://www.dns-sd.org/ServiceTypes.html

#import <Foundation/Foundation.h>
#import "NSNetService+Additions.h"

@protocol FPNetServiceBrowserDelegate
- (void)receivedServices:(NSArray<NSNetService *> *)services;
@end

@interface FPNetServiceBrowser : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate>
@property id<FPNetServiceBrowserDelegate> delegate;
@property NSMutableDictionary<NSString *, NSString *> *deviceMap;
- (void)searchForServicesOfTypes:(NSArray<NSString *> *)types;
- (void)stop;
@end

@protocol FPNetServiceTypeBrowserDelegate
- (void)receivedTypes:(NSArray<NSString *> *)types;
@end

@interface FPNetServiceTypeBrowser : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate>
@property id<FPNetServiceTypeBrowserDelegate> delegate;
- (void)searchForTypes;
- (void)stop;
@end
