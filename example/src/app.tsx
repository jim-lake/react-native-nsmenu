import React, { useEffect, useState } from 'react';
import { View, Text, Button, StyleSheet } from 'react-native';
import NSMenu from 'react-native-nsmenu';
import type { Menu } from 'react-native-nsmenu';

export default function App() {
  const [menu, setMenu] = useState<Menu | null>(null);

  useEffect(() => {
    NSMenu.getMainMenu().then(setMenu).catch(console.error);
  }, []);

  return (
    <View style={styles.container}>
      <Text style={styles.title}>NSMenu Example</Text>
      <Text style={styles.mono}>{JSON.stringify(menu, null, 2)}</Text>
      <Button
        title='Refresh'
        onPress={() => NSMenu.getMainMenu().then(setMenu)}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 20 },
  title: { fontSize: 24, fontWeight: 'bold', marginBottom: 12 },
  mono: { fontFamily: 'monospace', fontSize: 11 },
});
