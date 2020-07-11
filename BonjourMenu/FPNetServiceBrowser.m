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
    NSMutableArray<NSNetService *> *devices;
    NSTimer *timer;
}
@end

@implementation FPNetServiceBrowser

- (void)searchForServicesOfTypes:(NSArray<NSString *> *)types {
    [self stop];
    browsers = NSMutableArray.array;
    services = NSMutableArray.array;
    devices = NSMutableArray.array;
    self.deviceMap = NSMutableDictionary.dictionary;
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
    // https://stackoverflow.com/questions/4309740/how-do-i-obtain-model-name-for-a-networked-device-potentially-using-bonjour/5294662#5294662
    if(![[devices valueForKeyPath:@"@distinctUnionOfObjects.name"] containsObject:service.name]) {
        NSNetService *device = [[NSNetService alloc] initWithDomain:@"local" type:@"_device-info._tcp" name:service.name];
        device.delegate = self;
        [device startMonitoring];
        [devices addObject:device];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing {
    [services removeObject:service];
    if(!moreComing) { [self.delegate receivedServices:services]; }
}

#pragma mark NSNetServiceDelegate

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    if(timer != nil) { return; }
    timer = [NSTimer timerWithTimeInterval:1 repeats:NO block:^(NSTimer * _Nonnull _timer) {
        [self.delegate receivedServices:self->services];
        [self->timer invalidate];
        self->timer = nil;
    }];
    [NSRunLoop.mainRunLoop addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data {
    [self.deviceMap setObject:sender.fp_model forKey:sender.name];
    [sender stopMonitoring];
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
