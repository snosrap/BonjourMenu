//
//  AppDelegate.m
//  BonjourMenu
//
//  Created by Ford Parsons on 11/21/17.
//  Copyright © 2017 Ford Parsons. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate () {
    FPNetServiceTypeBrowser *typeBrowser;
    FPNetServiceBrowser *browser;
    NSStatusItem *mainStatusItem;
}
@end

@implementation AppDelegate

- (NSDictionary<NSString *, NSDictionary *> *)types {
    return [NSUserDefaults.standardUserDefaults objectForKey:NSStringFromSelector(_cmd)];
}

#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [NSUserDefaults.standardUserDefaults registerDefaults:[NSDictionary dictionaryWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"types" ofType:@"plist"]]];

    mainStatusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSSquareStatusItemLength];
    mainStatusItem.button.image = [NSImage imageNamed:NSImageNameBonjour];
    mainStatusItem.button.image.template = YES;
    mainStatusItem.button.image.size = NSMakeSize(16, 16);
    mainStatusItem.menu = NSMenu.new;
    mainStatusItem.menu.delegate = self;

    typeBrowser = FPNetServiceTypeBrowser.new;
    typeBrowser.delegate = self;
    [typeBrowser searchForTypes];

    browser = FPNetServiceBrowser.new;
    browser.delegate = self;
}

#pragma mark NSMenuDelegate

- (void)menuWillOpen:(NSMenu *)menu {
    [typeBrowser searchForTypes];
}

- (void)menuDidClose:(NSMenu *)menu {
    [typeBrowser stop];
    [browser stop];
}

#pragma mark FPNetServiceTypeBrowserDelegate

- (void)receivedTypes:(NSArray<NSString *> *)types {
    [browser searchForServicesOfTypes:types];
}

#pragma mark FPNetServiceBrowserDelegate

- (void)receivedServices:(NSArray<NSNetService *> *)services {
    [mainStatusItem.menu removeAllItems];

    NSArray<NSString *> *types = [[services valueForKeyPath:@"@distinctUnionOfObjects.type"] sortedArrayUsingSelector:@selector(compare:)];
    NSArray<NSString *> *hostNames = [[services valueForKeyPath:@"@distinctUnionOfObjects.hostName"] sortedArrayUsingSelector:@selector(compare:)];

    [types enumerateObjectsUsingBlock:^(NSString * _Nonnull type, NSUInteger idx_type, BOOL * _Nonnull stop_type) {
        if(![self.types.allKeys containsObject:type]) return; // continue;
        [[[services filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSNetService *service, NSDictionary<NSString *,id> * _Nullable bindings) { return [service.type isEqualToString:type]; }]] sortedArrayUsingComparator:^NSComparisonResult(NSNetService *obj1, NSNetService *obj2) { return [obj1.name compare:obj2.name]; }] enumerateObjectsUsingBlock:^(NSNetService * _Nonnull service, NSUInteger idx_service, BOOL * _Nonnull stop_service) {
            [mainStatusItem.menu addItem:[service fp_menuItem:@selector(statusItemAction:)]];
        }];
        [mainStatusItem.menu addItem:NSMenuItem.separatorItem];
    }];
    [hostNames enumerateObjectsUsingBlock:^(NSString * _Nonnull hostName, NSUInteger idx_hostName, BOOL * _Nonnull stop_hostName) {
        NSMenuItem *menuItem = [mainStatusItem.menu addItemWithTitle:hostName action:nil keyEquivalent:@""];
        menuItem.submenu = NSMenu.new;
        [[[services filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSNetService *service, NSDictionary<NSString *,id> * _Nullable bindings) { return [service.hostName isEqualToString:hostName]; }]] sortedArrayUsingComparator:^NSComparisonResult(NSNetService *obj1, NSNetService *obj2) { return [obj1.type compare:obj2.type] ?: [obj1.name compare:obj2.name]; }] enumerateObjectsUsingBlock:^(NSNetService * _Nonnull service, NSUInteger idx_service, BOOL * _Nonnull stop_service) {
            [mainStatusItem.menu.itemArray.lastObject.submenu addItem:[service fp_menuItem:@selector(statusItemAction:)]];
        }];
    }];
    [mainStatusItem.menu addItem:NSMenuItem.separatorItem];
    [types enumerateObjectsUsingBlock:^(NSString * _Nonnull type, NSUInteger idx_type, BOOL * _Nonnull stop_type) {
        NSMenuItem *menuItem = [mainStatusItem.menu addItemWithTitle:type action:nil keyEquivalent:@""];
        menuItem.submenu = NSMenu.new;
        [[[services filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSNetService *service, NSDictionary<NSString *,id> * _Nullable bindings) { return [service.type isEqualToString:type]; }]] sortedArrayUsingComparator:^NSComparisonResult(NSNetService *obj1, NSNetService *obj2) { return [obj1.name compare:obj2.name]; }] enumerateObjectsUsingBlock:^(NSNetService * _Nonnull service, NSUInteger idx_service, BOOL * _Nonnull stop_service) {
            [mainStatusItem.menu.itemArray.lastObject.submenu addItem:[service fp_menuItem:@selector(statusItemAction:)]];
        }];
    }];
    [mainStatusItem.menu addItem:NSMenuItem.separatorItem];
    [mainStatusItem.menu addItemWithTitle:@"Quit" action:@selector(quit:) keyEquivalent:@"q"];
}

#pragma mark IBAction

- (IBAction)quit:(id)sender {
    [NSApplication.sharedApplication terminate:sender];
}

- (IBAction)statusItemAction:(NSMenuItem *)sender {
    [NSWorkspace.sharedWorkspace openURL:sender.representedObject];
}

@end
