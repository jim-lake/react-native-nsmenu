import React, { useEffect, useState } from 'react';
import { View, Text, Button, ScrollView, StyleSheet } from 'react-native';
import NSMenu from 'react-native-nsmenu';
import type { Menu, MenuItem } from 'react-native-nsmenu';
import { addLine } from './log_store';
import { LogBox } from './components/log_box';

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
        console.log('MainMenu:', JSON.stringify(m, null, 2));
        setMenu(m);
      })
      .catch(console.error);
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

  return (
    <ScrollView style={styles.scroll} contentContainerStyle={styles.container}>
      <Text style={styles.title}>NSMenu Example</Text>
      <Button title='Refresh' onPress={fetchMenu} />
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
});
