//
//  NSNetService+Additions.m
//  BonjourMenu
//
//  Created by Ford Parsons on 12/22/17.
//  Copyright © 2017 Ford Parsons. All rights reserved.
//

#import "NSNetService+Additions.h"
#include <arpa/inet.h>
#import <objc/runtime.h>

@implementation FPNetServiceTXTRecord
- (NSString *)objectForKeyedSubscript:(NSString *)key {
    NSData *data = [NSNetService dictionaryFromTXTRecordData:self.netService.TXTRecordData][key];
    return (data != nil) ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;
}
@end

@implementation NSNetService (FPNetServiceAddtions)
- (NSString *)fp_ipv4 {
    for(NSData *data in self.addresses) {
        struct sockaddr *addr = (struct sockaddr *)data.bytes;
        if(addr->sa_family == AF_INET) {
            struct sockaddr_in *ip4 = (struct sockaddr_in *)data.bytes;
            char dest[INET_ADDRSTRLEN];
            return [NSString stringWithFormat:@"%s", inet_ntop(AF_INET, &ip4->sin_addr, dest, sizeof dest)];
        }
    }
    return nil;
}
- (NSString *)fp_ipv6 {
    for(NSData *data in self.addresses) {
        struct sockaddr *addr = (struct sockaddr *)data.bytes;
        if(addr->sa_family == AF_INET6) {
            struct sockaddr_in6 *ip6 = (struct sockaddr_in6 *)data.bytes;
            char dest[INET6_ADDRSTRLEN];
            return [NSString stringWithFormat:@"%s", inet_ntop(AF_INET6, &ip6->sin6_addr, dest, sizeof dest)];
        }
    }
    return nil;
}
- (FPNetServiceTXTRecord *)fp_TXTRecord {
    FPNetServiceTXTRecord *txtRecord = objc_getAssociatedObject(self, @selector(fp_TXTRecord));
    if(!txtRecord) {
        txtRecord = FPNetServiceTXTRecord.new;
        txtRecord.netService = self;
        objc_setAssociatedObject(self, @selector(fp_TXTRecord), txtRecord, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return txtRecord;
}
- (NSDictionary<NSString *, NSData *> *)fp_dictionaryFromTXTRecordData {
    return [NSNetService dictionaryFromTXTRecordData:self.TXTRecordData];
}
- (NSString *)fp_typeName {
    NSDictionary *dict = [NSUserDefaults.standardUserDefaults objectForKey:@"types"][self.type];
    return dict[@"typeName"] ?: [[self.type componentsSeparatedByString:@"."].firstObject stringByReplacingOccurrencesOfString:@"_" withString:@""];
}
- (NSURL *)fp_URL {
    NSDictionary *dict = [NSUserDefaults.standardUserDefaults objectForKey:@"types"][self.type];
    NSURLComponents *url = NSURLComponents.new;
    url.scheme = dict[@"scheme"] ?: @"http";
    url.user = self.fp_TXTRecord[@"u"];
    url.password = self.fp_TXTRecord[@"p"];
    url.host = self.hostName;
    if(self.port >= 0) { url.port = @(self.port); }
    url.path = self.fp_TXTRecord[@"path"] ?: dict[@"path"];
    return url.URL;
}
- (NSString *)fp_discoveredType {
    return [NSString stringWithFormat:@"%@.%@.", self.name, [self.type componentsSeparatedByString:@"."].firstObject];
}
@end

@implementation NSNetService (FPMenuAddtions)
- (NSMenuItem *)fp_menuItem:(SEL)action {
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@)", self.name, self.fp_typeName] action:action keyEquivalent:@""];
    NSString *image = [NSUserDefaults.standardUserDefaults objectForKey:@"types"][self.type][@"image"];
    menuItem.image = [NSImage imageNamed:image] ?: [NSFileManager.defaultManager fileExistsAtPath:image] ? [[NSImage alloc] initWithContentsOfFile:image] : [NSFileManager.defaultManager fileExistsAtPath:[NSWorkspace.sharedWorkspace absolutePathForAppBundleWithIdentifier:image]] ? [NSWorkspace.sharedWorkspace iconForFile:[NSWorkspace.sharedWorkspace absolutePathForAppBundleWithIdentifier:image]] : [NSImage imageNamed:NSImageNameNetwork];
    menuItem.image.size = NSMakeSize(16, 16);
    menuItem.representedObject = self;
    menuItem.toolTip = [NSString stringWithFormat:@"%@ (%i)\n%@\n%@\n%@\n%@", self.type, (int)self.port, self.hostName, self.fp_ipv4?:@"n/a", self.fp_ipv6?:@"n/a", self.fp_URL];//, [NSNetService dictionaryFromTXTRecordData:self.TXTRecordData]];
    return menuItem;
}
@end
