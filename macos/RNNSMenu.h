#pragma once

#include "RNNSMenuSpecJSI.h"
#include <ReactCommon/TurboModuleUtils.h>
#include <string>

namespace facebook::react {

// Concrete type aliases for codegen structs
using MenuItemStruct = NativeNSMenuMenuItem<
    std::optional<std::string>,              // title
    std::optional<std::string>,              // key
    std::optional<std::vector<std::string>>, // keyModifiers
    std::optional<bool>,                     // enabled
    std::optional<bool>,                     // hidden
    std::optional<std::string>,              // state
    std::optional<bool>,                     // separator
    std::optional<std::string>,              // image
    std::optional<std::string>,              // symbol
    std::optional<std::string>,              // toolTip
    std::optional<double>,                   // indentationLevel
    std::optional<bool>,                     // alternate
    std::optional<folly::dynamic>,           // submenu
    std::string>;                            // menuItemId

using MenuStruct = NativeNSMenuMenu<std::string,                  // menuId
                                    std::string,                  // title
                                    std::vector<MenuItemStruct>>; // items

using MenuItemActionPayloadStruct =
    NativeNSMenuMenuItemActionPayload<std::string, std::string>;

// Bridging for MenuItemStruct
template <> struct Bridging<MenuItemStruct> {
  static MenuItemStruct fromJs(jsi::Runtime &rt, const jsi::Object &value,
                               const std::shared_ptr<CallInvoker> &jsInvoker) {
    return NativeNSMenuMenuItemBridging<MenuItemStruct>::fromJs(rt, value,
                                                                jsInvoker);
  }
  static jsi::Object toJs(jsi::Runtime &rt, const MenuItemStruct &value,
                          const std::shared_ptr<CallInvoker> &jsInvoker) {
    return NativeNSMenuMenuItemBridging<MenuItemStruct>::toJs(rt, value,
                                                              jsInvoker);
  }
};

// Bridging for MenuStruct
template <> struct Bridging<MenuStruct> {
  static MenuStruct fromJs(jsi::Runtime &rt, const jsi::Object &value,
                           const std::shared_ptr<CallInvoker> &jsInvoker) {
    return NativeNSMenuMenuBridging<MenuStruct>::fromJs(rt, value, jsInvoker);
  }
  static jsi::Object toJs(jsi::Runtime &rt, const MenuStruct &value,
                          const std::shared_ptr<CallInvoker> &jsInvoker) {
    return NativeNSMenuMenuBridging<MenuStruct>::toJs(rt, value, jsInvoker);
  }
};

// Bridging for MenuItemActionPayloadStruct
template <> struct Bridging<MenuItemActionPayloadStruct> {
  static MenuItemActionPayloadStruct
  fromJs(jsi::Runtime &rt, const jsi::Object &value,
         const std::shared_ptr<CallInvoker> &jsInvoker) {
    return NativeNSMenuMenuItemActionPayloadBridging<
        MenuItemActionPayloadStruct>::fromJs(rt, value, jsInvoker);
  }
  static jsi::Object toJs(jsi::Runtime &rt,
                          const MenuItemActionPayloadStruct &value,
                          const std::shared_ptr<CallInvoker> &jsInvoker) {
    return NativeNSMenuMenuItemActionPayloadBridging<
        MenuItemActionPayloadStruct>::toJs(rt, value, jsInvoker);
  }
};

class RNNSMenu : public NativeNSMenuCxxSpec<RNNSMenu> {
public:
  RNNSMenu(std::shared_ptr<CallInvoker> jsInvoker);
  ~RNNSMenu();

  using NativeNSMenuCxxSpec<RNNSMenu>::emitOnMenuItemAction;
  using NativeNSMenuCxxSpec<RNNSMenu>::emitOnMenuWillOpen;
  using NativeNSMenuCxxSpec<RNNSMenu>::emitOnMenuDidClose;
  using NativeNSMenuCxxSpec<RNNSMenu>::emitOnMenuWillHighlightItem;

  jsi::Value getMainMenu(jsi::Runtime &rt);
  jsi::Value setMainMenu(jsi::Runtime &rt, jsi::Object menu);
  jsi::Value updateMenu(jsi::Runtime &rt, jsi::String menuId,
                        jsi::Object props);
  jsi::Value addMenuItem(jsi::Runtime &rt, jsi::String parentId,
                         jsi::Object item, std::optional<double> index);
  jsi::Value updateMenuItem(jsi::Runtime &rt, jsi::String menuItemId,
                            jsi::Object props);
  jsi::Value removeMenuItem(jsi::Runtime &rt, jsi::String menuItemId);

  std::shared_ptr<CallInvoker> jsInvoker_;
};

} // namespace facebook::react
