#!/usr/bin/env bash
set -euo pipefail

APP_ID="com.quantumbody.io.quantumbody"

# Вихід на Home
adb shell input keyevent 3 || true
sleep 0.3

# Запуск апки
adb shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || exit 1

sleep 1
