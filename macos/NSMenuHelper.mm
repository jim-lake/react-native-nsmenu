#import "NSMenuHelper.h"
#import "RNNSMenu.h"

static std::string ptrId(void *ptr) { return std::to_string((uintptr_t)ptr); }

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
  [self _installDelegates:NSApp.mainMenu];
}

- (void)stop {
  [self _removeDelegates:NSApp.mainMenu];
}

- (void)_installDelegates:(NSMenu *)menu {
  if (!menu) {
    return;
  }
  menu.delegate = self;
  for (NSMenuItem *item in menu.itemArray) {
    if (item.submenu) {
      [self _installDelegates:item.submenu];
    }
    if (!item.isSeparatorItem && item.action == nil) {
      item.target = self;
      item.action = @selector(_menuItemClicked:);
    }
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

- (void)_menuItemClicked:(NSMenuItem *)sender {
  if (!self.module) {
    return;
  }
  std::string itemId = ptrId((__bridge void *)sender);
  std::string menuId = sender.menu ? ptrId((__bridge void *)sender.menu) : "";
  facebook::react::MenuItemActionPayloadStruct payload{itemId, menuId};
  self.module->emitOnMenuItemAction(payload);
}

// MARK: - NSMenuDelegate

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
