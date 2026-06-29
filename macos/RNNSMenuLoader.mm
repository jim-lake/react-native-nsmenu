#include "RNNSMenu.h"
#import <Foundation/Foundation.h>
#include <ReactCommon/CxxTurboModuleUtils.h>

@interface RNNSMenuLoader : NSObject
@end

@implementation RNNSMenuLoader

+ (void)load {
  facebook::react::registerCxxModuleToGlobalModuleMap(
      "NSMenuModule",
      [](std::shared_ptr<facebook::react::CallInvoker> jsInvoker) {
        return std::make_shared<facebook::react::RNNSMenu>(
            std::move(jsInvoker));
      });
}

@end
