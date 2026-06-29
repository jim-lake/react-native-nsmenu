#pragma once

#include "RNNSMenuSpecJSI.h"
#include <ReactCommon/TurboModuleUtils.h>
#include <string>

namespace facebook::react {

class RNNSMenu : public NativeNSMenuCxxSpec<RNNSMenu> {
public:
  RNNSMenu(std::shared_ptr<CallInvoker> jsInvoker);

  jsi::Value getMainMenu(jsi::Runtime &rt);
  jsi::Value setMainMenu(jsi::Runtime &rt, jsi::Object menu);
  jsi::Value addMenuItem(jsi::Runtime &rt, jsi::String parentId,
                         jsi::Object item, std::optional<double> index);
  jsi::Value updateMenuItem(jsi::Runtime &rt, jsi::String menuItemId,
                            jsi::Object props);
  jsi::Value removeMenuItem(jsi::Runtime &rt, jsi::String menuItemId);

private:
  std::shared_ptr<CallInvoker> jsInvoker_;
};

} // namespace facebook::react
