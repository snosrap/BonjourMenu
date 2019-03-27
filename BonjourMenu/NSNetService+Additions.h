//
//  NSNetService+Additions.h
//  BonjourMenu
//
//  Created by Ford Parsons on 12/22/17.
//  Copyright © 2017 Ford Parsons. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FPNetServiceTXTRecord : NSObject
@property NSNetService *netService;
- (NSString *)objectForKeyedSubscript:(NSString *)key;
@end

@interface NSNetService (FPNetServiceAddtions)
- (NSString *)fp_ipv4;
- (NSString *)fp_ipv6;
- (FPNetServiceTXTRecord *)fp_TXTRecord;
- (NSDictionary<NSString *, NSData *> *)fp_dictionaryFromTXTRecordData;
- (NSString *)fp_typeName;
- (NSURL *)fp_URL;
- (NSString *)fp_discoveredType;
@end

@interface NSNetService (FPMenuAddtions)
- (NSMenuItem *)fp_menuItem:(SEL)action;
- (NSMenu *)fp_submenuItems:(SEL)action;
@end

@interface NSMenuItem (FPMenuAddtions)
+ (NSMenuItem *)fp_itemWithTitle:(NSString *)title URL:(NSURL *)URL type:(NSString *)type action:(SEL)action;
@end

@interface NSData (FPMenuAddtions)
- (NSDictionary *)fp_parseTXTData;
@end
