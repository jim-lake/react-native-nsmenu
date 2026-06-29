import { nativeModule } from '../spec/NativeNSMenu';
import type {
  MenuItem as _MenuItem,
  Menu as _Menu,
  MenuItemUpdate as _MenuItemUpdate,
} from '../spec/NativeNSMenu';
export type {
  MenuItemId,
  MenuId,
  MenuItemActionPayload,
} from '../spec/NativeNSMenu';

export interface Menu extends Omit<_Menu, 'items'> {
  items: MenuItem[];
}

export interface MenuItem extends Omit<_MenuItem, 'submenu'> {
  submenu?: Menu;
}

export interface MenuItemUpdate extends Omit<_MenuItemUpdate, 'submenu'> {
  submenu?: Menu;
}

export default nativeModule as unknown as Omit<
  typeof nativeModule,
  'getMainMenu' | 'setMainMenu' | 'addMenuItem' | 'updateMenuItem'
> & {
  getMainMenu(): Promise<Menu>;
  setMainMenu(menu: Menu): Promise<void>;
  addMenuItem(parentId: string, item: MenuItem, index?: number): Promise<void>;
  updateMenuItem(menuItemId: string, props: MenuItemUpdate): Promise<void>;
};
