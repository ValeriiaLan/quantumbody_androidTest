#!/usr/bin/env bash
set -euo pipefail

# 🚀 Reset Maestro agent on current Android emulator/device

DEVICE_ID="${DEVICE_ID:-$(adb devices | awk 'NR==2 {print $1}')}"

if [[ -z "${DEVICE_ID}" || "${DEVICE_ID}" == "device" ]]; then
  echo "❌ Не знайдено жодного активного емулятора/девайса"
  exit 1
fi

echo "🔄 Reset Maestro agent на ${DEVICE_ID}..."

# 1) Перезапускаємо adb
adb kill-server || true
adb start-server

# 2) Перевстановлюємо драйвер
maestro driver-setup

# 3) Перевіряємо чи агент стоїть
if adb -s "${DEVICE_ID}" shell pm list packages | grep -q "dev.mobile.maestro"; then
  echo "✅ Maestro agent успішно встановлено"
else
  echo "⚠️ Увага: Maestro agent не знайдено після перевстановлення"
fi

echo "✨ Готово! Тепер можна запускати свої тести 🚀"
