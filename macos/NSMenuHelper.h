#pragma once

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

namespace facebook::react {
class RNNSMenu;
}

@interface NSMenuHelper : NSObject <NSMenuDelegate>

@property(nonatomic, assign) facebook::react::RNNSMenu *module;

+ (instancetype)shared;
- (void)start;
- (void)stop;

@end
