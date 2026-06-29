import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';
import type { EventEmitter } from 'react-native/Libraries/Types/CodegenTypes';

export type MenuItemId = string;
export type MenuId = string;

export interface MenuItem {
  menuItemId: MenuItemId;
  title: string;
  key?: string;
  keyModifiers?: Array<'shift' | 'control' | 'option' | 'command'>;
  enabled?: boolean;
  hidden?: boolean;
  state?: 'off' | 'on' | 'mixed';
  separator?: boolean;
  submenu?: Object;
}

export interface Menu {
  menuId: MenuId;
  title: string;
  items: MenuItem[];
}

export interface MenuItemUpdate {
  title?: string;
  key?: string;
  keyModifiers?: Array<'shift' | 'control' | 'option' | 'command'>;
  enabled?: boolean;
  hidden?: boolean;
  state?: 'off' | 'on' | 'mixed';
  separator?: boolean;
  submenu?: Object;
}

export interface MenuItemActionPayload {
  menuItemId: MenuItemId;
  menuId: MenuId;
}

export interface Spec extends TurboModule {
  getMainMenu(): Promise<Object>;
  setMainMenu(menu: Object): Promise<void>;

  addMenuItem(parentId: MenuId, item: Object, index?: number): Promise<void>;
  updateMenuItem(menuItemId: MenuItemId, props: MenuItemUpdate): Promise<void>;
  removeMenuItem(menuItemId: MenuItemId): Promise<void>;

  readonly onMenuItemAction: EventEmitter<MenuItemActionPayload>;
}

export const nativeModule =
  TurboModuleRegistry.getEnforcing<Spec>('NSMenuModule');
