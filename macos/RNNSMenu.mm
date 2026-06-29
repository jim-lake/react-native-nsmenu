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

static NSEventModifierFlags
maskFromKeyModifiers(const std::vector<std::string> &mods) {
  NSEventModifierFlags mask = 0;
  for (auto &m : mods) {
    if (m == "shift") {
      mask |= NSEventModifierFlagShift;
    } else if (m == "control") {
      mask |= NSEventModifierFlagControl;
    } else if (m == "option") {
      mask |= NSEventModifierFlagOption;
    } else if (m == "command") {
      mask |= NSEventModifierFlagCommand;
    }
  }
  return mask;
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

static NSControlStateValue stateFromString(const std::string &s) {
  if (s == "on") {
    return NSControlStateValueOn;
  }
  if (s == "mixed") {
    return NSControlStateValueMixed;
  }
  return NSControlStateValueOff;
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

// MARK: - Lookup helpers

static NSMenu *findMenuById(NSMenu *root, const std::string &targetId) {
  if (!root) {
    return nil;
  }
  if (menuIdForMenu(root) == targetId) {
    return root;
  }
  for (NSMenuItem *item in root.itemArray) {
    if (item.submenu) {
      NSMenu *found = findMenuById(item.submenu, targetId);
      if (found) {
        return found;
      }
    }
  }
  return nil;
}

static NSMenuItem *findMenuItemById(NSMenu *root, const std::string &targetId) {
  if (!root) {
    return nil;
  }
  for (NSMenuItem *item in root.itemArray) {
    if (menuItemIdForItem(item) == targetId) {
      return item;
    }
    if (item.submenu) {
      NSMenuItem *found = findMenuItemById(item.submenu, targetId);
      if (found) {
        return found;
      }
    }
  }
  return nil;
}

// MARK: - Building NSMenu from folly::dynamic

static NSMenuItem *buildNSMenuItem(const folly::dynamic &obj);

static NSMenu *buildNSMenu(const folly::dynamic &obj) {
  NSString *title =
      obj.count("title") ? @(obj["title"].getString().c_str()) : @"";
  NSMenu *menu = [[NSMenu alloc] initWithTitle:title];
  menu.autoenablesItems = NO;
  if (obj.count("items")) {
    for (auto &itemObj : obj["items"]) {
      NSMenuItem *item = buildNSMenuItem(itemObj);
      if (item) {
        [menu addItem:item];
      }
    }
  }
  return menu;
}

static NSMenuItem *buildNSMenuItem(const folly::dynamic &obj) {
  if (obj.count("separator") && obj["separator"].isBool() &&
      obj["separator"].getBool()) {
    return [NSMenuItem separatorItem];
  }

  NSString *title =
      obj.count("title") ? @(obj["title"].getString().c_str()) : @"";
  NSString *key = obj.count("key") ? @(obj["key"].getString().c_str()) : @"";

  NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title
                                                action:nil
                                         keyEquivalent:key];

  if (obj.count("keyModifiers") && obj["keyModifiers"].isArray()) {
    std::vector<std::string> mods;
    for (auto &m : obj["keyModifiers"]) {
      mods.push_back(m.getString());
    }
    item.keyEquivalentModifierMask = maskFromKeyModifiers(mods);
  }

  if (obj.count("enabled") && obj["enabled"].isBool()) {
    item.enabled = obj["enabled"].getBool();
  } else {
    item.enabled = YES;
  }

  if (obj.count("hidden") && obj["hidden"].isBool()) {
    item.hidden = obj["hidden"].getBool();
  }

  if (obj.count("state") && obj["state"].isString()) {
    item.state = stateFromString(obj["state"].getString());
  }

  if (obj.count("image") && obj["image"].isString()) {
    NSString *imageName = @(obj["image"].getString().c_str());
    item.image = [NSImage imageNamed:imageName];
  }

  if (obj.count("symbol") && obj["symbol"].isString()) {
    NSString *symbolName = @(obj["symbol"].getString().c_str());
    NSImage *img = [NSImage imageWithSystemSymbolName:symbolName
                             accessibilityDescription:nil];
    if (img) {
      item.image = img;
    }
  }

  if (obj.count("toolTip") && obj["toolTip"].isString()) {
    item.toolTip = @(obj["toolTip"].getString().c_str());
  }

  if (obj.count("indentationLevel") && obj["indentationLevel"].isDouble()) {
    item.indentationLevel = (NSInteger)obj["indentationLevel"].getDouble();
  }

  if (obj.count("alternate") && obj["alternate"].isBool() &&
      obj["alternate"].getBool()) {
    item.alternate = YES;
  }

  if (obj.count("submenu") && obj["submenu"].isObject()) {
    item.submenu = buildNSMenu(obj["submenu"]);
  }

  return item;
}

// MARK: - Apply updates to existing items

static void applyPropsToMenuItem(NSMenuItem *item,
                                 const folly::dynamic &props) {
  if (props.count("title") && props["title"].isString()) {
    item.title = @(props["title"].getString().c_str());
  }
  if (props.count("key") && props["key"].isString()) {
    item.keyEquivalent = @(props["key"].getString().c_str());
  }
  if (props.count("keyModifiers") && props["keyModifiers"].isArray()) {
    std::vector<std::string> mods;
    for (auto &m : props["keyModifiers"]) {
      mods.push_back(m.getString());
    }
    item.keyEquivalentModifierMask = maskFromKeyModifiers(mods);
  }
  if (props.count("enabled") && props["enabled"].isBool()) {
    item.enabled = props["enabled"].getBool();
  }
  if (props.count("hidden") && props["hidden"].isBool()) {
    item.hidden = props["hidden"].getBool();
  }
  if (props.count("state") && props["state"].isString()) {
    item.state = stateFromString(props["state"].getString());
  }
  if (props.count("image") && props["image"].isString()) {
    item.image = [NSImage imageNamed:@(props["image"].getString().c_str())];
  }
  if (props.count("symbol") && props["symbol"].isString()) {
    NSImage *img = [NSImage
        imageWithSystemSymbolName:@(props["symbol"].getString().c_str())
         accessibilityDescription:nil];
    if (img) {
      item.image = img;
    }
  }
  if (props.count("toolTip") && props["toolTip"].isString()) {
    item.toolTip = @(props["toolTip"].getString().c_str());
  }
  if (props.count("indentationLevel") && props["indentationLevel"].isDouble()) {
    item.indentationLevel = (NSInteger)props["indentationLevel"].getDouble();
  }
  if (props.count("alternate") && props["alternate"].isBool()) {
    item.alternate = props["alternate"].getBool();
  }
  if (props.count("submenu") && props["submenu"].isObject()) {
    item.submenu = buildNSMenu(props["submenu"]);
    [[NSMenuHelper shared] installDelegatesOnMenu:item.submenu];
  }
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

// MARK: - getMainMenu

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

// MARK: - setMainMenu

jsi::Value RNNSMenu::setMainMenu(jsi::Runtime &rt, jsi::Object menu) {
  folly::dynamic menuDyn =
      bridging::fromJs<folly::dynamic>(rt, jsi::Value(rt, menu), jsInvoker_);

  return createPromiseAsJSIValue(
      rt, [this, menuDyn = std::move(menuDyn)](
              jsi::Runtime &rt, std::shared_ptr<Promise> promise) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [[NSMenuHelper shared] stop];
          NSMenu *nsMenu = buildNSMenu(menuDyn);
          nsMenu.autoenablesItems = NO;
          [NSApp setMainMenu:nsMenu];
          [[NSMenuHelper shared] installDelegatesOnMenu:nsMenu];
          this->jsInvoker_->invokeAsync(
              [promise]() { promise->resolve(jsi::Value::undefined()); });
        });
      });
}

// MARK: - updateMenu

jsi::Value RNNSMenu::updateMenu(jsi::Runtime &rt, jsi::String menuId,
                                jsi::Object props) {
  std::string mid = menuId.utf8(rt);
  folly::dynamic propsDyn =
      bridging::fromJs<folly::dynamic>(rt, jsi::Value(rt, props), jsInvoker_);

  return createPromiseAsJSIValue(
      rt, [this, mid = std::move(mid), propsDyn = std::move(propsDyn)](
              jsi::Runtime &rt, std::shared_ptr<Promise> promise) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSMenu *menu = findMenuById(NSApp.mainMenu, mid);
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
              NSMenuItem *item = buildNSMenuItem(itemObj);
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

// MARK: - addMenuItem

jsi::Value RNNSMenu::addMenuItem(jsi::Runtime &rt, jsi::String parentId,
                                 jsi::Object item,
                                 std::optional<double> index) {
  std::string pid = parentId.utf8(rt);
  folly::dynamic itemDyn =
      bridging::fromJs<folly::dynamic>(rt, jsi::Value(rt, item), jsInvoker_);

  return createPromiseAsJSIValue(
      rt, [this, pid = std::move(pid), itemDyn = std::move(itemDyn),
           index](jsi::Runtime &rt, std::shared_ptr<Promise> promise) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSMenu *menu = findMenuById(NSApp.mainMenu, pid);
          if (!menu) {
            this->jsInvoker_->invokeAsync(
                [promise]() { promise->reject("Parent menu not found"); });
            return;
          }
          NSMenuItem *nsItem = buildNSMenuItem(itemDyn);
          if (!nsItem) {
            this->jsInvoker_->invokeAsync(
                [promise]() { promise->reject("Failed to build menu item"); });
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

// MARK: - updateMenuItem

jsi::Value RNNSMenu::updateMenuItem(jsi::Runtime &rt, jsi::String menuItemId,
                                    jsi::Object props) {
  std::string itemId = menuItemId.utf8(rt);
  folly::dynamic propsDyn =
      bridging::fromJs<folly::dynamic>(rt, jsi::Value(rt, props), jsInvoker_);

  return createPromiseAsJSIValue(
      rt, [this, itemId = std::move(itemId), propsDyn = std::move(propsDyn)](
              jsi::Runtime &rt, std::shared_ptr<Promise> promise) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSMenuItem *item = findMenuItemById(NSApp.mainMenu, itemId);
          if (!item) {
            this->jsInvoker_->invokeAsync(
                [promise]() { promise->reject("Menu item not found"); });
            return;
          }
          applyPropsToMenuItem(item, propsDyn);
          this->jsInvoker_->invokeAsync(
              [promise]() { promise->resolve(jsi::Value::undefined()); });
        });
      });
}

// MARK: - removeMenuItem

jsi::Value RNNSMenu::removeMenuItem(jsi::Runtime &rt, jsi::String menuItemId) {
  std::string itemId = menuItemId.utf8(rt);

  return createPromiseAsJSIValue(
      rt, [this, itemId = std::move(itemId)](jsi::Runtime &rt,
                                             std::shared_ptr<Promise> promise) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSMenuItem *item = findMenuItemById(NSApp.mainMenu, itemId);
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
