#include "RNNSMenu.h"
#import "NSMenuHelper.h"
#import <AppKit/AppKit.h>

namespace facebook::react {

static std::string menuIdForMenu(NSMenu *menu) {
  return std::to_string((uintptr_t)menu);
}

static std::string menuItemIdForItem(NSMenuItem *item) {
  return std::to_string((uintptr_t)item);
}

static std::optional<std::vector<std::string>>
keyModifiersFromMask(NSEventModifierFlags mask) {
  std::vector<std::string> mods;
  if (mask & NSEventModifierFlagShift) {
    mods.push_back("shift");
  }
  if (mask & NSEventModifierFlagControl) {
    mods.push_back("control");
  }
  if (mask & NSEventModifierFlagOption) {
    mods.push_back("option");
  }
  if (mask & NSEventModifierFlagCommand) {
    mods.push_back("command");
  }
  if (mods.empty()) {
    return std::nullopt;
  }
  return mods;
}

static std::optional<std::string> stateString(NSControlStateValue state) {
  switch (state) {
  case NSControlStateValueOn:
    return "on";
  case NSControlStateValueMixed:
    return "mixed";
  default:
    return std::nullopt;
  }
}

static folly::dynamic serializeMenuDynamic(NSMenu *nsMenu);

static std::optional<std::string> imageNameForItem(NSMenuItem *nsItem) {
  NSImage *img = nsItem.image;
  if (!img) {
    return std::nullopt;
  }
  NSImageName name = [img name];
  if (name) {
    return std::string(name.UTF8String);
  }
  return std::nullopt;
}

static std::optional<std::string> symbolNameForItem(NSMenuItem *nsItem) {
  NSImage *img = nsItem.image;
  if (!img) {
    return std::nullopt;
  }
  if (img.symbolConfiguration != nil) {
    // It's a symbol image — the name is the SF Symbol name
    NSImageName name = [img name];
    if (name) {
      return std::string(name.UTF8String);
    }
  }
  return std::nullopt;
}

static MenuItemStruct serializeMenuItem(NSMenuItem *nsItem) {
  bool isSep = [nsItem isSeparatorItem];

  std::optional<std::string> image = std::nullopt;
  std::optional<std::string> symbol = std::nullopt;
  if (!isSep) {
    symbol = symbolNameForItem(nsItem);
    if (!symbol) {
      image = imageNameForItem(nsItem);
    }
  }

  std::optional<folly::dynamic> submenu = std::nullopt;
  if (nsItem.submenu) {
    submenu = serializeMenuDynamic(nsItem.submenu);
  }

  return MenuItemStruct{
      isSep ? std::nullopt
            : std::optional<std::string>(nsItem.title.UTF8String),
      nsItem.keyEquivalent.length > 0
          ? std::optional<std::string>(nsItem.keyEquivalent.UTF8String)
          : std::nullopt,
      keyModifiersFromMask(nsItem.keyEquivalentModifierMask),
      isSep ? std::nullopt : std::optional<bool>(nsItem.enabled),
      nsItem.hidden ? std::optional<bool>(true) : std::nullopt,
      stateString(nsItem.state),
      isSep ? std::optional<bool>(true) : std::nullopt,
      image,
      symbol,
      nsItem.toolTip ? std::optional<std::string>(nsItem.toolTip.UTF8String)
                     : std::nullopt,
      nsItem.indentationLevel > 0
          ? std::optional<double>(nsItem.indentationLevel)
          : std::nullopt,
      nsItem.alternate ? std::optional<bool>(true) : std::nullopt,
      submenu,
      menuItemIdForItem(nsItem)};
}

static MenuStruct serializeMenu(NSMenu *nsMenu) {
  std::vector<MenuItemStruct> items;
  for (NSMenuItem *nsItem in nsMenu.itemArray) {
    items.push_back(serializeMenuItem(nsItem));
  }
  return MenuStruct{menuIdForMenu(nsMenu), std::string(nsMenu.title.UTF8String),
                    items};
}

static folly::dynamic serializeMenuItemDynamic(NSMenuItem *nsItem) {
  bool isSep = [nsItem isSeparatorItem];
  folly::dynamic obj = folly::dynamic::object;
  obj["menuItemId"] = menuItemIdForItem(nsItem);
  if (isSep) {
    obj["separator"] = true;
  } else {
    obj["title"] = std::string(nsItem.title.UTF8String);
    obj["enabled"] = (bool)nsItem.enabled;
  }
  if (nsItem.keyEquivalent.length > 0) {
    obj["key"] = std::string(nsItem.keyEquivalent.UTF8String);
  }
  auto mods = keyModifiersFromMask(nsItem.keyEquivalentModifierMask);
  if (mods) {
    folly::dynamic arr = folly::dynamic::array;
    for (auto &m : *mods) {
      arr.push_back(m);
    }
    obj["keyModifiers"] = arr;
  }
  if (nsItem.hidden) {
    obj["hidden"] = true;
  }
  auto st = stateString(nsItem.state);
  if (st) {
    obj["state"] = *st;
  }
  if (nsItem.toolTip) {
    obj["toolTip"] = std::string(nsItem.toolTip.UTF8String);
  }
  if (nsItem.indentationLevel > 0) {
    obj["indentationLevel"] = (double)nsItem.indentationLevel;
  }
  if (nsItem.alternate) {
    obj["alternate"] = true;
  }
  if (!isSep && nsItem.image) {
    if (nsItem.image.symbolConfiguration != nil) {
      NSImageName name = [nsItem.image name];
      if (name) {
        obj["symbol"] = std::string(name.UTF8String);
      }
    } else {
      NSImageName name = [nsItem.image name];
      if (name) {
        obj["image"] = std::string(name.UTF8String);
      }
    }
  }
  if (nsItem.submenu) {
    obj["submenu"] = serializeMenuDynamic(nsItem.submenu);
  }
  return obj;
}

static folly::dynamic serializeMenuDynamic(NSMenu *nsMenu) {
  folly::dynamic obj = folly::dynamic::object;
  obj["menuId"] = menuIdForMenu(nsMenu);
  obj["title"] = std::string(nsMenu.title.UTF8String);
  folly::dynamic items = folly::dynamic::array;
  for (NSMenuItem *nsItem in nsMenu.itemArray) {
    items.push_back(serializeMenuItemDynamic(nsItem));
  }
  obj["items"] = items;
  return obj;
}

RNNSMenu::RNNSMenu(std::shared_ptr<CallInvoker> jsInvoker)
    : NativeNSMenuCxxSpec(std::move(jsInvoker)) {
  jsInvoker_ = NativeNSMenuCxxSpec::jsInvoker_;
  dispatch_async(dispatch_get_main_queue(), ^{
    [NSMenuHelper shared].module = this;
    [[NSMenuHelper shared] start];
  });
}

RNNSMenu::~RNNSMenu() {
  auto *ptr = this;
  dispatch_async(dispatch_get_main_queue(), ^{
    if ([NSMenuHelper shared].module == ptr) {
      [[NSMenuHelper shared] stop];
      [NSMenuHelper shared].module = nullptr;
    }
  });
}

jsi::Value RNNSMenu::getMainMenu(jsi::Runtime &rt) {
  return createPromiseAsJSIValue(
      rt, [this](jsi::Runtime &rt, std::shared_ptr<Promise> promise) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSMenu *mainMenu = NSApp.mainMenu;
          if (!mainMenu) {
            this->jsInvoker_->invokeAsync(
                [promise]() { promise->reject("No main menu"); });
            return;
          }
          MenuStruct menu = serializeMenu(mainMenu);
          this->jsInvoker_->invokeAsync([promise, menu = std::move(menu),
                                         jsInvoker = this->jsInvoker_, &rt]() {
            auto result = bridging::toJs(rt, menu, jsInvoker);
            promise->resolve(std::move(result));
          });
        });
      });
}

jsi::Value RNNSMenu::setMainMenu(jsi::Runtime &rt, jsi::Object menu) {
  return createPromiseAsJSIValue(
      rt, [](jsi::Runtime &rt, std::shared_ptr<Promise> promise) {
        promise->reject("not implemented");
      });
}

jsi::Value RNNSMenu::updateMenu(jsi::Runtime &rt, jsi::String menuId,
                                jsi::Object props) {
  return createPromiseAsJSIValue(
      rt, [](jsi::Runtime &rt, std::shared_ptr<Promise> promise) {
        promise->reject("not implemented");
      });
}

jsi::Value RNNSMenu::addMenuItem(jsi::Runtime &rt, jsi::String parentId,
                                 jsi::Object item,
                                 std::optional<double> index) {
  return createPromiseAsJSIValue(
      rt, [](jsi::Runtime &rt, std::shared_ptr<Promise> promise) {
        promise->reject("not implemented");
      });
}

jsi::Value RNNSMenu::updateMenuItem(jsi::Runtime &rt, jsi::String menuItemId,
                                    jsi::Object props) {
  return createPromiseAsJSIValue(
      rt, [](jsi::Runtime &rt, std::shared_ptr<Promise> promise) {
        promise->reject("not implemented");
      });
}

jsi::Value RNNSMenu::removeMenuItem(jsi::Runtime &rt, jsi::String menuItemId) {
  return createPromiseAsJSIValue(
      rt, [](jsi::Runtime &rt, std::shared_ptr<Promise> promise) {
        promise->reject("not implemented");
      });
}

} // namespace facebook::react
