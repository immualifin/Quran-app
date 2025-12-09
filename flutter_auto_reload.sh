#!/usr/bin/env bash

# Pastikan Flutter aktif
echo "Menunggu Flutter dijalankan..."
until pgrep -f "flutter_tools.snapshot" >/dev/null; do
  sleep 2
done

# Ambil PID Flutter
PID=$(pgrep -f "flutter_tools.snapshot")
echo "Flutter process PID: $PID"

# Pantau folder lib untuk perubahan
echo "Watching for file changes in lib/..."
inotifywait -m -r -e modify,create,delete,move lib/ | while read -r path event file; do
  echo "File change detected in $path$file — sending hot reload..."
  # Kirim sinyal hot reload ke proses Flutter
  kill -SIGUSR1 "$PID"
done
