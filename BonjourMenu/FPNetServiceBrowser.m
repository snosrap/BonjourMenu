//
//  FPNetServiceBrowser.m
//  BonjourMenu
//
//  Created by Ford Parsons on 12/12/17.
//  Copyright © 2017 Ford Parsons. All rights reserved.
//

#import "FPNetServiceBrowser.h"

@interface FPNetServiceBrowser () {
    NSMutableArray<NSNetServiceBrowser *> *browsers;
    NSMutableArray<NSNetService *> *services;
    NSTimer *timer;
}
@end

@implementation FPNetServiceBrowser

- (void)searchForServicesOfTypes:(NSArray<NSString *> *)types {
    [self stop];
    browsers = NSMutableArray.array;
    services = NSMutableArray.array;
    [types enumerateObjectsUsingBlock:^(NSString * _Nonnull type, NSUInteger idx, BOOL * _Nonnull stop) {
        NSNetServiceBrowser *browser = NSNetServiceBrowser.new;
        browser.delegate = self;
        [browser searchForServicesOfType:type inDomain:@""];
        [browsers addObject:browser];
    }];
}

- (void)stop {
    [browsers makeObjectsPerformSelector:@selector(stop)];
    [services makeObjectsPerformSelector:@selector(stop)];
    browsers = nil;
    services = nil;
}

#pragma mark NSNetServiceBrowserDelegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing {
    [services addObject:service];
    service.delegate = self;
    [service resolveWithTimeout:5];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing {
    [services removeObject:service];
    if(!moreComing) { [self.delegate receivedServices:services]; }
}

#pragma mark NSNetServiceDelegate

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    if(timer != nil) { return; }
    timer = [NSTimer timerWithTimeInterval:1 repeats:NO block:^(NSTimer * _Nonnull _timer) {
        [self.delegate receivedServices:services];
        [timer invalidate];
        timer = nil;
    }];
    [NSRunLoop.mainRunLoop addTimer:timer forMode:NSRunLoopCommonModes];
}

@end

@interface FPNetServiceTypeBrowser () {
    NSNetServiceBrowser *browser;
    NSMutableSet<NSString *> *types;
}
@end

@implementation FPNetServiceTypeBrowser
- (void)searchForTypes {
    if(!!browser) return;
    [self stop];
    types = NSMutableSet.set;
    browser = NSNetServiceBrowser.new;
    browser.includesPeerToPeer = YES;
    browser.delegate = self;
    [browser searchForServicesOfType:@"_services._dns-sd._udp." inDomain:@""];
}

- (void)stop {
    [browser stop];
    types = nil;
    browser = nil;
}

#pragma mark NSNetServiceBrowserDelegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing {
    [types addObject:service.fp_discoveredType];
    if(!moreComing) { [self.delegate receivedTypes:types.allObjects]; }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing {
    [types removeObject:service.fp_discoveredType];
    if(!moreComing) { [self.delegate receivedTypes:types.allObjects]; }
}
@end
