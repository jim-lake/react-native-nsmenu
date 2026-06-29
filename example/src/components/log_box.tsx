import React from 'react';
import { View, Text, FlatList, StyleSheet, Pressable } from 'react-native';
import {
  useLogLines,
  useLogPaused,
  clearLog,
  pauseLog,
  resumeLog,
} from '../log_store';

export function LogBox() {
  const lines = useLogLines();
  const paused = useLogPaused();

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerText}>
          Event Log{paused ? ' (paused)' : ''}
        </Text>
        <View style={styles.headerButtons}>
          <Pressable onPress={paused ? resumeLog : pauseLog}>
            <Text style={styles.btn}>{paused ? 'Resume' : 'Pause'}</Text>
          </Pressable>
          <Pressable onPress={clearLog}>
            <Text style={styles.btn}>Clear</Text>
          </Pressable>
        </View>
      </View>
      <FlatList
        contentContainerStyle={styles.listContent}
        data={lines}
        keyExtractor={(_, i) => String(i)}
        renderItem={({ item }) => <Text style={styles.line}>{item}</Text>}
        style={styles.list}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    height: 200,
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 4,
    marginTop: 16,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    padding: 6,
    borderBottomWidth: 1,
    borderBottomColor: '#ccc',
    backgroundColor: '#f5f5f5',
  },
  headerText: { fontSize: 12, fontWeight: '600', color: '#333' },
  headerButtons: { flexDirection: 'row', gap: 8 },
  btn: { color: '#007AFF', fontSize: 12 },
  list: { flex: 1, padding: 4 },
  listContent: { flexDirection: 'column', paddingTop: 20 },
  line: { fontSize: 11, color: '#333', fontFamily: 'Menlo' },
});
