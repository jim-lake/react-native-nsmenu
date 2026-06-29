#pragma once

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <folly/dynamic.h>

namespace facebook::react {
class RNNSMenu;
}

@interface NSMenuHelper : NSObject <NSMenuDelegate>

@property(nonatomic, assign) facebook::react::RNNSMenu *module;

+ (instancetype)shared;
- (void)start;
- (void)stop;

// Tree lookup
- (NSMenu *)findMenuById:(NSString *)menuId;
- (NSMenuItem *)findMenuItemById:(NSString *)itemId;

// Construction from folly::dynamic
- (NSMenu *)buildMenuFromDynamic:(const folly::dynamic &)obj;
- (NSMenuItem *)buildMenuItemFromDynamic:(const folly::dynamic &)obj;
- (void)applyProps:(const folly::dynamic &)props toMenuItem:(NSMenuItem *)item;

// Delegate wiring
- (void)installDelegatesOnMenu:(NSMenu *)menu;
- (void)installDelegatesOnItem:(NSMenuItem *)item;

@end
