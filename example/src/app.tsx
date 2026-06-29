import React, { useEffect, useState } from 'react';
import { View, Text, Button, ScrollView, StyleSheet } from 'react-native';
import NSMenu from 'react-native-nsmenu';
import type { Menu, MenuItem } from 'react-native-nsmenu';
import { addLine } from './log_store';
import { LogBox } from './components/log_box';

const WORDS = [
  'Alpha',
  'Bravo',
  'Charlie',
  'Delta',
  'Echo',
  'Foxtrot',
  'Golf',
  'Hotel',
  'India',
  'Juliet',
  'Kilo',
  'Lima',
];
const pick = () => WORDS[Math.floor(Math.random() * WORDS.length)]!;
const randTitle = () => `${pick()} ${pick()}`;

function MenuItemRow({ item, depth = 0 }: { item: MenuItem; depth?: number }) {
  if (item.separator) {
    return <View style={[styles.separator, { marginLeft: depth * 16 }]} />;
  }
  const mods =
    item.keyModifiers
      ?.map((m) => {
        switch (m) {
          case 'command':
            return '⌘';
          case 'option':
            return '⌥';
          case 'control':
            return '⌃';
          case 'shift':
            return '⇧';
          default:
            return '';
        }
      })
      .join('') ?? '';
  const shortcut = mods + (item.key ?? '');

  return (
    <View style={{ marginLeft: depth * 16 }}>
      <View style={styles.itemRow}>
        <View style={styles.itemLeft}>
          {item.symbol && <Text style={styles.symbol}>⟨{item.symbol}⟩ </Text>}
          {item.image && !item.symbol && (
            <Text style={styles.symbol}>[{item.image}] </Text>
          )}
          <Text style={[styles.itemTitle, !item.enabled && styles.disabled]}>
            {item.title}
          </Text>
          {item.state === 'on' && <Text style={styles.check}> ✓</Text>}
          {item.state === 'mixed' && <Text style={styles.check}> −</Text>}
          {item.toolTip && <Text style={styles.tip}> 💬</Text>}
          {item.hidden && <Text style={styles.tip}> 👁‍🗨</Text>}
          {item.alternate && <Text style={styles.tip}> ⎇</Text>}
        </View>
        {shortcut ? <Text style={styles.shortcut}>{shortcut}</Text> : null}
      </View>
      {item.submenu && <MenuView menu={item.submenu} depth={depth + 1} />}
    </View>
  );
}

function MenuView({ menu, depth = 0 }: { menu: Menu; depth?: number }) {
  return (
    <View style={[styles.menu, depth > 0 && styles.submenu]}>
      <Text style={styles.menuTitle}>{menu.title}</Text>
      {menu.items.map((item, i) => (
        <MenuItemRow
          key={item.menuItemId ?? `${i}`}
          item={item}
          depth={depth}
        />
      ))}
    </View>
  );
}

export default function App() {
  const [menu, setMenu] = useState<Menu | null>(null);

  const fetchMenu = () => {
    NSMenu.getMainMenu()
      .then((m) => {
        addLine(`getMainMenu: ${m.items.length} top-level items`);
        setMenu(m);
      })
      .catch((e) => addLine(`ERROR: ${e}`));
  };

  useEffect(() => {
    fetchMenu();
    const itemSub = NSMenu.onMenuItemAction((e) => {
      addLine(`menuItemAction: ${e.menuItemId} in ${e.menuId}`);
    });
    const openSub = NSMenu.onMenuWillOpen((menuId) => {
      addLine(`menuWillOpen: ${menuId}`);
    });
    const closeSub = NSMenu.onMenuDidClose((menuId) => {
      addLine(`menuDidClose: ${menuId}`);
    });
    const highlightSub = NSMenu.onMenuWillHighlightItem((e) => {
      addLine(`highlightItem: ${e.menuItemId} in ${e.menuId}`);
    });
    return () => {
      itemSub.remove();
      openSub.remove();
      closeSub.remove();
      highlightSub.remove();
    };
  }, []);

  const doSetMainMenu = () => {
    NSMenu.setMainMenu({
      menuId: '',
      title: '',
      items: [
        {
          menuItemId: 'app',
          title: 'App',
          submenu: {
            menuId: '',
            title: 'App',
            items: [
              { menuItemId: 'about', title: 'About', symbol: 'info.circle' },
              { menuItemId: 'sep1', separator: true },
              {
                menuItemId: 'quit',
                title: 'Quit',
                key: 'q',
                keyModifiers: ['command'],
              },
            ],
          },
        },
        {
          menuItemId: 'file',
          title: 'File',
          submenu: {
            menuId: '',
            title: 'File',
            items: [
              {
                menuItemId: 'new',
                title: 'New',
                key: 'n',
                keyModifiers: ['command'],
                symbol: 'doc.badge.plus',
              },
              {
                menuItemId: 'open',
                title: 'Open',
                key: 'o',
                keyModifiers: ['command'],
                symbol: 'folder',
              },
              { menuItemId: 'sep2', separator: true },
              {
                menuItemId: 'save',
                title: 'Save',
                key: 's',
                keyModifiers: ['command'],
                image: 'NSActionTemplate',
              },
              {
                menuItemId: 'saveAs',
                title: 'Save As…',
                key: 's',
                keyModifiers: ['command', 'shift'],
                alternate: true,
              },
              { menuItemId: 'sep3', separator: true },
              {
                menuItemId: 'recent',
                title: 'Recent Files',
                submenu: {
                  menuId: '',
                  title: 'Recent Files',
                  items: [
                    {
                      menuItemId: 'r1',
                      title: 'report.pdf',
                      indentationLevel: 1,
                    },
                    {
                      menuItemId: 'r2',
                      title: 'notes.txt',
                      indentationLevel: 1,
                    },
                  ],
                },
              },
            ],
          },
        },
        {
          menuItemId: 'view',
          title: 'View',
          submenu: {
            menuId: '',
            title: 'View',
            items: [
              {
                menuItemId: 'sidebar',
                title: 'Show Sidebar',
                state: 'on',
                symbol: 'sidebar.left',
                key: 's',
                keyModifiers: ['command', 'control'],
              },
              {
                menuItemId: 'toolbar',
                title: 'Show Toolbar',
                state: 'off',
                symbol: 'menubar.rectangle',
              },
              {
                menuItemId: 'inspector',
                title: 'Inspector',
                state: 'mixed',
                symbol: 'info.circle',
              },
              { menuItemId: 'sep4', separator: true },
              { menuItemId: 'hidden1', title: 'Hidden Item', hidden: true },
              {
                menuItemId: 'disabled1',
                title: 'Disabled Item',
                enabled: false,
                toolTip: 'This item is disabled',
              },
              {
                menuItemId: 'tipped',
                title: 'Hover for Tip',
                toolTip: 'Hello from a tooltip!',
              },
            ],
          },
        },
      ],
    })
      .then(() => {
        addLine('setMainMenu: done');
        fetchMenu();
      })
      .catch((e) => addLine(`ERROR setMainMenu: ${e}`));
  };

  const doUpdateMenu = () => {
    if (!menu) return;
    const firstSub = menu.items.find((i) => i.submenu);
    if (!firstSub?.submenu) {
      addLine('No submenu found');
      return;
    }
    NSMenu.updateMenu(firstSub.submenu.menuId, { title: randTitle() })
      .then(() => {
        addLine('updateMenu: done');
        fetchMenu();
      })
      .catch((e) => addLine(`ERROR updateMenu: ${e}`));
  };

  const doAddMenuItem = () => {
    if (!menu) return;
    const firstSub = menu.items.find((i) => i.submenu);
    if (!firstSub?.submenu) {
      addLine('No submenu found');
      return;
    }
    NSMenu.addMenuItem(firstSub.submenu.menuId, {
      menuItemId: '',
      title: randTitle(),
      key: 'n',
      keyModifiers: ['command', 'option'],
      symbol: 'star.fill',
      toolTip: 'Dynamically added',
    })
      .then(() => {
        addLine('addMenuItem: done');
        fetchMenu();
      })
      .catch((e) => addLine(`ERROR addMenuItem: ${e}`));
  };

  const doAddSeparator = () => {
    if (!menu) return;
    const firstSub = menu.items.find((i) => i.submenu);
    if (!firstSub?.submenu) {
      addLine('No submenu found');
      return;
    }
    NSMenu.addMenuItem(firstSub.submenu.menuId, {
      menuItemId: '',
      separator: true,
    })
      .then(() => {
        addLine('addSeparator: done');
        fetchMenu();
      })
      .catch((e) => addLine(`ERROR addSeparator: ${e}`));
  };

  const doUpdateMenuItem = () => {
    if (!menu) return;
    const firstSub = menu.items.find((i) => i.submenu);
    const target = firstSub?.submenu?.items.find(
      (i) => !i.separator && !i.submenu
    );
    if (!target) {
      addLine('No item to update');
      return;
    }
    const newState =
      target.state === 'on' ? 'off' : target.state === 'mixed' ? 'on' : 'mixed';
    NSMenu.updateMenuItem(target.menuItemId, {
      title: randTitle(),
      state: newState,
      symbol: 'pencil.circle.fill',
      toolTip: `State: ${newState}`,
      enabled: true,
    })
      .then(() => {
        addLine(`updateMenuItem: done (state→${newState})`);
        fetchMenu();
      })
      .catch((e) => addLine(`ERROR updateMenuItem: ${e}`));
  };

  const doRemoveMenuItem = () => {
    if (!menu) return;
    const firstSub = menu.items.find((i) => i.submenu);
    const items = firstSub?.submenu?.items;
    if (!items || items.length === 0) {
      addLine('No item to remove');
      return;
    }
    const target = items[items.length - 1]!;
    NSMenu.removeMenuItem(target.menuItemId)
      .then(() => {
        addLine(`removeMenuItem: done`);
        fetchMenu();
      })
      .catch((e) => addLine(`ERROR removeMenuItem: ${e}`));
  };

  return (
    <ScrollView style={styles.scroll} contentContainerStyle={styles.container}>
      <Text style={styles.title}>NSMenu Example</Text>
      <View style={styles.buttons}>
        <Button title='Refresh' onPress={fetchMenu} />
        <Button title='Set Menu' onPress={doSetMainMenu} />
        <Button title='Update Menu' onPress={doUpdateMenu} />
        <Button title='Add Item' onPress={doAddMenuItem} />
        <Button title='Add Separator' onPress={doAddSeparator} />
        <Button title='Update Item' onPress={doUpdateMenuItem} />
        <Button title='Remove Item' onPress={doRemoveMenuItem} />
      </View>
      <LogBox />
      {menu && (
        <View style={styles.menuBar}>
          {menu.items.map((item, i) => (
            <MenuItemRow key={item.menuItemId ?? `${i}`} item={item} />
          ))}
        </View>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  scroll: { flex: 1 },
  container: { padding: 20, paddingBottom: 60 },
  title: { fontSize: 24, fontWeight: 'bold', marginBottom: 12 },
  buttons: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 12 },
  menuBar: { marginTop: 16 },
  menu: {
    marginBottom: 12,
    borderLeftWidth: 2,
    borderLeftColor: '#ccc',
    paddingLeft: 8,
  },
  submenu: { marginTop: 4, marginBottom: 4 },
  menuTitle: {
    fontSize: 14,
    fontWeight: '600',
    marginBottom: 4,
    color: '#333',
  },
  itemRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 2,
  },
  itemLeft: { flexDirection: 'row', alignItems: 'center', flex: 1 },
  itemTitle: { fontSize: 13, color: '#111' },
  disabled: { color: '#999' },
  shortcut: {
    fontSize: 12,
    color: '#666',
    fontFamily: 'Menlo',
    marginLeft: 12,
  },
  separator: { height: 1, backgroundColor: '#ddd', marginVertical: 4 },
  symbol: { fontSize: 11, color: '#007AFF' },
  check: { fontSize: 13, color: '#007AFF' },
  tip: { fontSize: 11, color: '#888' },
});
