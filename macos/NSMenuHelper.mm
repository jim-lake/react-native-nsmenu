#import "NSMenuHelper.h"
#import "RNNSMenu.h"

static std::string ptrId(void *ptr) { return std::to_string((uintptr_t)ptr); }

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

static NSControlStateValue stateFromString(const std::string &s) {
  if (s == "on") {
    return NSControlStateValueOn;
  }
  if (s == "mixed") {
    return NSControlStateValueMixed;
  }
  return NSControlStateValueOff;
}

@implementation NSMenuHelper

+ (instancetype)shared {
  static NSMenuHelper *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[NSMenuHelper alloc] init];
  });
  return instance;
}

- (void)start {
  [self installDelegatesOnMenu:NSApp.mainMenu];
}

- (void)stop {
  [self _removeDelegates:NSApp.mainMenu];
}

// MARK: - Tree lookup

- (NSMenu *)findMenuById:(NSString *)menuId {
  return [self _findMenu:NSApp.mainMenu byId:menuId.UTF8String];
}

- (NSMenuItem *)findMenuItemById:(NSString *)itemId {
  return [self _findItem:NSApp.mainMenu byId:itemId.UTF8String];
}

- (NSMenu *)_findMenu:(NSMenu *)root byId:(const std::string &)targetId {
  if (!root) {
    return nil;
  }
  if (ptrId((__bridge void *)root) == targetId) {
    return root;
  }
  for (NSMenuItem *item in root.itemArray) {
    if (item.submenu) {
      NSMenu *found = [self _findMenu:item.submenu byId:targetId];
      if (found) {
        return found;
      }
    }
  }
  return nil;
}

- (NSMenuItem *)_findItem:(NSMenu *)root byId:(const std::string &)targetId {
  if (!root) {
    return nil;
  }
  for (NSMenuItem *item in root.itemArray) {
    if (ptrId((__bridge void *)item) == targetId) {
      return item;
    }
    if (item.submenu) {
      NSMenuItem *found = [self _findItem:item.submenu byId:targetId];
      if (found) {
        return found;
      }
    }
  }
  return nil;
}

// MARK: - Construction from folly::dynamic

- (NSMenu *)buildMenuFromDynamic:(const folly::dynamic &)obj {
  NSString *title =
      obj.count("title") ? @(obj["title"].getString().c_str()) : @"";
  NSMenu *menu = [[NSMenu alloc] initWithTitle:title];
  menu.autoenablesItems = NO;
  if (obj.count("items")) {
    for (auto &itemObj : obj["items"]) {
      NSMenuItem *item = [self buildMenuItemFromDynamic:itemObj];
      if (item) {
        [menu addItem:item];
      }
    }
  }
  return menu;
}

- (NSMenuItem *)buildMenuItemFromDynamic:(const folly::dynamic &)obj {
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

  item.enabled = (obj.count("enabled") && obj["enabled"].isBool())
                     ? obj["enabled"].getBool()
                     : YES;

  if (obj.count("hidden") && obj["hidden"].isBool()) {
    item.hidden = obj["hidden"].getBool();
  }

  if (obj.count("state") && obj["state"].isString()) {
    item.state = stateFromString(obj["state"].getString());
  }

  if (obj.count("image") && obj["image"].isString()) {
    item.image = [NSImage imageNamed:@(obj["image"].getString().c_str())];
  }

  if (obj.count("symbol") && obj["symbol"].isString()) {
    NSImage *img =
        [NSImage imageWithSystemSymbolName:@(obj["symbol"].getString().c_str())
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
    item.submenu = [self buildMenuFromDynamic:obj["submenu"]];
  }

  return item;
}

- (void)applyProps:(const folly::dynamic &)props toMenuItem:(NSMenuItem *)item {
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
    item.submenu = [self buildMenuFromDynamic:props["submenu"]];
    [self installDelegatesOnMenu:item.submenu];
  }
}

// MARK: - Delegate wiring

- (void)installDelegatesOnMenu:(NSMenu *)menu {
  if (!menu) {
    return;
  }
  menu.delegate = self;
  for (NSMenuItem *item in menu.itemArray) {
    [self installDelegatesOnItem:item];
  }
}

- (void)installDelegatesOnItem:(NSMenuItem *)item {
  if (!item) {
    return;
  }
  if (!item.isSeparatorItem && item.action == nil) {
    item.target = self;
    item.action = @selector(_menuItemClicked:);
  }
  if (item.submenu) {
    [self installDelegatesOnMenu:item.submenu];
  }
}

- (void)_removeDelegates:(NSMenu *)menu {
  if (!menu) {
    return;
  }
  if (menu.delegate == self) {
    menu.delegate = nil;
  }
  for (NSMenuItem *item in menu.itemArray) {
    if (item.submenu) {
      [self _removeDelegates:item.submenu];
    }
    if (item.target == self) {
      item.target = nil;
      item.action = nil;
    }
  }
}

// MARK: - Actions & NSMenuDelegate

- (void)_menuItemClicked:(NSMenuItem *)sender {
  if (!self.module) {
    return;
  }
  std::string itemId = ptrId((__bridge void *)sender);
  std::string menuId = sender.menu ? ptrId((__bridge void *)sender.menu) : "";
  facebook::react::MenuItemActionPayloadStruct payload{itemId, menuId};
  self.module->emitOnMenuItemAction(payload);
}

- (void)menuWillOpen:(NSMenu *)menu {
  if (!self.module) {
    return;
  }
  self.module->emitOnMenuWillOpen(ptrId((__bridge void *)menu));
}

- (void)menuDidClose:(NSMenu *)menu {
  if (!self.module) {
    return;
  }
  self.module->emitOnMenuDidClose(ptrId((__bridge void *)menu));
}

- (void)menu:(NSMenu *)menu willHighlightItem:(nullable NSMenuItem *)item {
  if (!self.module || !item) {
    return;
  }
  std::string itemId = ptrId((__bridge void *)item);
  std::string menuId = ptrId((__bridge void *)menu);
  facebook::react::MenuItemActionPayloadStruct payload{itemId, menuId};
  self.module->emitOnMenuWillHighlightItem(payload);
}

@end
