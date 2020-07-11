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
// http://cocoadev.github.io/GettingTheIconOfNetworkMachinesTypes/
- (NSString *)fp_model {
    // Uses undocumented _LSIconPath. kUTTypeIconFileKey doesn't seem to exist any more and when it does, it lacks `/Contents/Resources/` and isn't found in CoreTypes
    NSString *model = self.fp_TXTRecord[@"model"];
    if(!model) return nil;
    CFStringRef uti = CFAutorelease(UTTypeCreatePreferredIdentifierForTag((__bridge CFStringRef)@"com.apple.device-model-code", (__bridge CFStringRef)model, nil));
    if(!uti) return nil;
    CFDictionaryRef decl = CFAutorelease(UTTypeCopyDeclaration(uti));
    if(!decl) return nil;
    CFStringRef icon = CFDictionaryGetValue(decl, @"_LSIconPath");
    while(icon == nil && uti != nil) {
        CFArrayRef utis = CFDictionaryGetValue(decl, kUTTypeConformsToKey);
        for(CFIndex i = 0; i<CFArrayGetCount(utis); i++) {
            uti = CFArrayGetValueAtIndex(utis, i);
            decl = CFAutorelease(UTTypeCopyDeclaration(uti));
            icon = CFDictionaryGetValue(decl, @"_LSIconPath");
            if(icon != nil) break;
        }
    }
    if(!uti) return nil;
    CFURLRef url = CFAutorelease(UTTypeCopyDeclaringBundleURL(uti));
    CFStringRef path = CFAutorelease(CFURLCopyPath(url));
    NSString *iconPath = [(__bridge NSString *)path stringByAppendingPathComponent:(__bridge NSString *)icon];
    return iconPath;
}
@end

@implementation NSNetService (FPMenuAddtions)
- (NSMenuItem *)fp_menuItem:(SEL)action {
    NSMenuItem *menuItem = [NSMenuItem fp_itemWithTitle:self.name URL:self.fp_URL type:self.type action:action];
    if([self.type isEqualToString:@"_adisk._tcp."]) {
        menuItem.submenu = [self fp_submenuItems:action];
    }
    return menuItem;
}
- (NSMenu *)fp_submenuItems:(SEL)action {
    NSMenu *submenu = NSMenu.new;
    [self.fp_dictionaryFromTXTRecordData enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSData * _Nonnull obj, BOOL * _Nonnull stop) {
        if([key hasPrefix:@"dk"]) {
            NSDictionary *txtDict = obj.fp_parseTXTData;
            NSString *name = txtDict[@"adVN"];
            NSUInteger flags = [txtDict[@"adVF"] unsignedIntegerValue];
            [@{@"_afpovertcp._tcp.":@(1), @"_smb._tcp.":@(2)} enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
                if(flags & obj.unsignedIntegerValue) {
                    NSURLComponents *uc = [NSURLComponents componentsWithURL:self.fp_URL resolvingAgainstBaseURL:NO];
                    uc.scheme = [NSUserDefaults.standardUserDefaults objectForKey:@"types"][key][@"scheme"];;
                    uc.path = [NSString stringWithFormat:@"/%@", name];
                    uc.port = 0;
                    [submenu addItem:[NSMenuItem fp_itemWithTitle:name URL:uc.URL type:key action:action]];
                }
            }];
        }
    }];
    return submenu;
}
@end

@implementation NSMenuItem (FPMenuAddtions)
+ (NSMenuItem *)fp_itemWithTitle:(NSString *)title URL:(NSURL *)URL type:(NSString *)type action:(SEL)action {
    NSString *typeName = [NSUserDefaults.standardUserDefaults objectForKey:@"types"][type][@"typeName"] ?: type;
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@)", title, typeName] action:action keyEquivalent:@""];
    NSString *image = [NSUserDefaults.standardUserDefaults objectForKey:@"types"][type][@"image"];
    [menuItem fp_imageString:image];
    menuItem.representedObject = URL;
    return menuItem;
}
- (void)fp_imageString:(NSString *)image {
    self.image = [NSImage imageNamed:image] ?: [NSFileManager.defaultManager fileExistsAtPath:image] ? [[NSImage alloc] initWithContentsOfFile:image] : [NSFileManager.defaultManager fileExistsAtPath:[NSWorkspace.sharedWorkspace absolutePathForAppBundleWithIdentifier:image]] ? [NSWorkspace.sharedWorkspace iconForFile:[NSWorkspace.sharedWorkspace absolutePathForAppBundleWithIdentifier:image]] : [NSImage imageNamed:NSImageNameNetwork];
    self.image.size = NSMakeSize(16, 16);
}
@end

@implementation NSData (FPMenuAddtions)
- (NSDictionary *)fp_parseTXTData { // http://netatalk.sourceforge.net/wiki/index.php/Bonjour_record_adisk_adVF_values
    NSScanner *scanner = [NSScanner scannerWithString:[[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding]];
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    NSString *key;
    id value;
    while([scanner scanUpToString:@"=" intoString:&key]) {
        [scanner scanString:@"=" intoString:nil];
        if([key isEqualToString:@"adVF"]) {
            unsigned int flags = 0;
            [scanner scanHexInt:&flags];
            d[key] = @(flags);
        } else {
            [scanner scanUpToString:@"," intoString:&value];
            d[key] = value;
        }
        [scanner scanString:@"," intoString:nil];
    }
    return d;
}
@end
