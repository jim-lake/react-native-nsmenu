import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';
import type { EventEmitter } from 'react-native/Libraries/Types/CodegenTypes';

export type MenuItemId = string;
export type MenuId = string;

export interface MenuItemUpdate {
  title?: string;
  key?: string;
  keyModifiers?: Array<'shift' | 'control' | 'option' | 'command'>;
  enabled?: boolean;
  hidden?: boolean;
  state?: 'off' | 'on' | 'mixed';
  separator?: boolean;
  image?: string;
  symbol?: string;
  toolTip?: string;
  indentationLevel?: number;
  alternate?: boolean;
  submenu?: Object;
}
export interface MenuItem extends MenuItemUpdate {
  menuItemId: MenuItemId;
}
export interface Menu {
  menuId: MenuId;
  title: string;
  items: MenuItem[];
}
export interface MenuUpdate {
  title?: string;
  items?: MenuItemUpdate[];
}

export interface MenuItemActionPayload {
  menuItemId: MenuItemId;
  menuId: MenuId;
}

export interface Spec extends TurboModule {
  getMainMenu(): Promise<Menu>;
  setMainMenu(menu: Menu): Promise<void>;
  updateMenu(menuId: MenuId, props: MenuUpdate): Promise<void>;

  addMenuItem(parentId: MenuId, item: MenuItem, index?: number): Promise<void>;
  updateMenuItem(menuItemId: MenuItemId, props: MenuItemUpdate): Promise<void>;
  removeMenuItem(menuItemId: MenuItemId): Promise<void>;

  readonly onMenuItemAction: EventEmitter<MenuItemActionPayload>;
  readonly onMenuWillOpen: EventEmitter<MenuId>;
  readonly onMenuDidClose: EventEmitter<MenuId>;
  readonly onMenuWillHighlightItem: EventEmitter<MenuItemActionPayload>;
}

export const nativeModule =
  TurboModuleRegistry.getEnforcing<Spec>('NSMenuModule');
