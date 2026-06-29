import { useSyncExternalStore } from 'react';

let g_lines: string[] = [];
let g_paused = false;
let g_pendingLines: string[] = [];
const g_listeners = new Set<() => void>();

function _notify() {
  for (const listener of g_listeners) listener();
}

function _subscribe(listener: () => void) {
  g_listeners.add(listener);
  return () => g_listeners.delete(listener);
}

export function addLine(line: string) {
  if (g_paused) {
    g_pendingLines.push(line);
    return;
  }
  g_lines = [line, ...g_lines];
  _notify();
}

export function clearLog() {
  g_lines = [];
  g_pendingLines = [];
  _notify();
}

export function pauseLog() {
  g_paused = true;
  _notify();
}

export function resumeLog() {
  g_paused = false;
  if (g_pendingLines.length > 0) {
    g_lines = [...g_pendingLines.reverse(), ...g_lines];
    g_pendingLines = [];
  }
  _notify();
}

export function useLogLines(): readonly string[] {
  return useSyncExternalStore(
    _subscribe,
    () => g_lines,
    () => g_lines
  );
}

export function useLogPaused(): boolean {
  return useSyncExternalStore(
    _subscribe,
    () => g_paused,
    () => g_paused
  );
}
