#include "RNNSMenu.h"
#import <Foundation/Foundation.h>

namespace facebook::react {

RNNSMenu::RNNSMenu(std::shared_ptr<CallInvoker> jsInvoker)
    : NativeNSMenuCxxSpec(std::move(jsInvoker)) {
  jsInvoker_ = NativeNSMenuCxxSpec::jsInvoker_;
}

jsi::Value RNNSMenu::getMainMenu(jsi::Runtime &rt) {
  return createPromiseAsJSIValue(
      rt, [](jsi::Runtime &rt, std::shared_ptr<Promise> promise) {
        // TODO: implement
        promise->reject("not implemented");
      });
}

jsi::Value RNNSMenu::setMainMenu(jsi::Runtime &rt, jsi::Object menu) {
  return createPromiseAsJSIValue(
      rt, [](jsi::Runtime &rt, std::shared_ptr<Promise> promise) {
        // TODO: implement
        promise->reject("not implemented");
      });
}

jsi::Value RNNSMenu::addMenuItem(jsi::Runtime &rt, jsi::String parentId,
                                 jsi::Object item,
                                 std::optional<double> index) {
  return createPromiseAsJSIValue(
      rt, [](jsi::Runtime &rt, std::shared_ptr<Promise> promise) {
        // TODO: implement
        promise->reject("not implemented");
      });
}

jsi::Value RNNSMenu::updateMenuItem(jsi::Runtime &rt, jsi::String menuItemId,
                                    jsi::Object props) {
  return createPromiseAsJSIValue(
      rt, [](jsi::Runtime &rt, std::shared_ptr<Promise> promise) {
        // TODO: implement
        promise->reject("not implemented");
      });
}

jsi::Value RNNSMenu::removeMenuItem(jsi::Runtime &rt, jsi::String menuItemId) {
  return createPromiseAsJSIValue(
      rt, [](jsi::Runtime &rt, std::shared_ptr<Promise> promise) {
        // TODO: implement
        promise->reject("not implemented");
      });
}

} // namespace facebook::react
