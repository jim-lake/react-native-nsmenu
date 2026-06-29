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
  return mods.empty() ? std::nullopt
                      : std::optional<std::vector<std::string>>(mods);
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
  return name ? std::optional<std::string>(name.UTF8String) : std::nullopt;
}

static std::optional<std::string> symbolNameForItem(NSMenuItem *nsItem) {
  NSImage *img = nsItem.image;
  if (!img || !img.symbolConfiguration) {
    return std::nullopt;
  }
  NSImageName name = [img name];
  return name ? std::optional<std::string>(name.UTF8String) : std::nullopt;
}

static MenuItemStruct serializeMenuItem(NSMenuItem *nsItem) {
  bool isSep = [nsItem isSeparatorItem];
  std::optional<std::string> symbol =
      isSep ? std::nullopt : symbolNameForItem(nsItem);
  std::optional<std::string> image =
      (!isSep && !symbol) ? imageNameForItem(nsItem) : std::nullopt;
  std::optional<folly::dynamic> submenu =
      nsItem.submenu
          ? std::optional<folly::dynamic>(serializeMenuDynamic(nsItem.submenu))
          : std::nullopt;

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
    if (nsItem.image.symbolConfiguration) {
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

// MARK: - Module lifecycle

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

// MARK: - API methods

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
            promise->resolve(bridging::toJs(rt, menu, jsInvoker));
          });
        });
      });
}

jsi::Value RNNSMenu::setMainMenu(jsi::Runtime &rt, jsi::Object menu) {
  folly::dynamic menuDyn =
      bridging::fromJs<folly::dynamic>(rt, jsi::Value(rt, menu), jsInvoker_);
  return createPromiseAsJSIValue(
      rt, [this, menuDyn = std::move(menuDyn)](
              jsi::Runtime &, std::shared_ptr<Promise> promise) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [[NSMenuHelper shared] stop];
          NSMenu *nsMenu = [[NSMenuHelper shared] buildMenuFromDynamic:menuDyn];
          nsMenu.autoenablesItems = NO;
          [NSApp setMainMenu:nsMenu];
          [[NSMenuHelper shared] installDelegatesOnMenu:nsMenu];
          this->jsInvoker_->invokeAsync(
              [promise]() { promise->resolve(jsi::Value::undefined()); });
        });
      });
}

jsi::Value RNNSMenu::updateMenu(jsi::Runtime &rt, jsi::String menuId,
                                jsi::Object props) {
  std::string mid = menuId.utf8(rt);
  folly::dynamic propsDyn =
      bridging::fromJs<folly::dynamic>(rt, jsi::Value(rt, props), jsInvoker_);
  return createPromiseAsJSIValue(
      rt, [this, mid = std::move(mid), propsDyn = std::move(propsDyn)](
              jsi::Runtime &, std::shared_ptr<Promise> promise) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSMenu *menu = [[NSMenuHelper shared] findMenuById:@(mid.c_str())];
          if (!menu) {
            this->jsInvoker_->invokeAsync(
                [promise]() { promise->reject("Menu not found"); });
            return;
          }
          if (propsDyn.count("title") && propsDyn["title"].isString()) {
            menu.title = @(propsDyn["title"].getString().c_str());
          }
          if (propsDyn.count("items") && propsDyn["items"].isArray()) {
            [menu removeAllItems];
            for (auto &itemObj : propsDyn["items"]) {
              NSMenuItem *item =
                  [[NSMenuHelper shared] buildMenuItemFromDynamic:itemObj];
              if (item) {
                [menu addItem:item];
                [[NSMenuHelper shared] installDelegatesOnItem:item];
              }
            }
          }
          this->jsInvoker_->invokeAsync(
              [promise]() { promise->resolve(jsi::Value::undefined()); });
        });
      });
}

jsi::Value RNNSMenu::addMenuItem(jsi::Runtime &rt, jsi::String parentId,
                                 jsi::Object item,
                                 std::optional<double> index) {
  std::string pid = parentId.utf8(rt);
  folly::dynamic itemDyn =
      bridging::fromJs<folly::dynamic>(rt, jsi::Value(rt, item), jsInvoker_);
  return createPromiseAsJSIValue(
      rt, [this, pid = std::move(pid), itemDyn = std::move(itemDyn),
           index](jsi::Runtime &, std::shared_ptr<Promise> promise) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSMenu *menu = [[NSMenuHelper shared] findMenuById:@(pid.c_str())];
          if (!menu) {
            this->jsInvoker_->invokeAsync(
                [promise]() { promise->reject("Parent menu not found"); });
            return;
          }
          NSMenuItem *nsItem =
              [[NSMenuHelper shared] buildMenuItemFromDynamic:itemDyn];
          if (!nsItem) {
            this->jsInvoker_->invokeAsync(
                [promise]() { promise->reject("Failed to build item"); });
            return;
          }
          if (index.has_value()) {
            NSInteger idx = (NSInteger)index.value();
            if (idx >= 0 && idx <= menu.numberOfItems) {
              [menu insertItem:nsItem atIndex:idx];
            } else {
              [menu addItem:nsItem];
            }
          } else {
            [menu addItem:nsItem];
          }
          [[NSMenuHelper shared] installDelegatesOnItem:nsItem];
          this->jsInvoker_->invokeAsync(
              [promise]() { promise->resolve(jsi::Value::undefined()); });
        });
      });
}

jsi::Value RNNSMenu::updateMenuItem(jsi::Runtime &rt, jsi::String menuItemId,
                                    jsi::Object props) {
  std::string itemId = menuItemId.utf8(rt);
  folly::dynamic propsDyn =
      bridging::fromJs<folly::dynamic>(rt, jsi::Value(rt, props), jsInvoker_);
  return createPromiseAsJSIValue(
      rt, [this, itemId = std::move(itemId), propsDyn = std::move(propsDyn)](
              jsi::Runtime &, std::shared_ptr<Promise> promise) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSMenuItem *item =
              [[NSMenuHelper shared] findMenuItemById:@(itemId.c_str())];
          if (!item) {
            this->jsInvoker_->invokeAsync(
                [promise]() { promise->reject("Menu item not found"); });
            return;
          }
          [[NSMenuHelper shared] applyProps:propsDyn toMenuItem:item];
          this->jsInvoker_->invokeAsync(
              [promise]() { promise->resolve(jsi::Value::undefined()); });
        });
      });
}

jsi::Value RNNSMenu::removeMenuItem(jsi::Runtime &rt, jsi::String menuItemId) {
  std::string itemId = menuItemId.utf8(rt);
  return createPromiseAsJSIValue(
      rt, [this, itemId = std::move(itemId)](jsi::Runtime &,
                                             std::shared_ptr<Promise> promise) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSMenuItem *item =
              [[NSMenuHelper shared] findMenuItemById:@(itemId.c_str())];
          if (!item) {
            this->jsInvoker_->invokeAsync(
                [promise]() { promise->reject("Menu item not found"); });
            return;
          }
          NSMenu *parent = item.menu;
          if (parent) {
            [parent removeItem:item];
          }
          this->jsInvoker_->invokeAsync(
              [promise]() { promise->resolve(jsi::Value::undefined()); });
        });
      });
}

} // namespace facebook::react
