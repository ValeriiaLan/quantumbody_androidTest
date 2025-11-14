#!/usr/bin/env bash
set -euo pipefail

# 1) Завантажуємо змінні (.env.user1 > .env)
if [[ -f ".env.user1" ]]; then
  set -a
  source ".env.user1"
  set +a
elif [[ -f ".env" ]]; then
  set -a
  source ".env"
  set +a
fi

# 2) APP_ID -> appId (для Maestro)
: "${APP_ID:=}"
if [[ -n "${APP_ID}" && -z "${appId:-}" ]]; then
  export appId="${APP_ID}"
fi

# 3) Якщо запускаємо maestro test — робимо підготовку
if [[ "${1:-}" == "maestro" && "${2:-}" == "test" ]]; then
  # 3.1) Зафіксувати девайс для adb (надійніше)
  if [[ -n "${DEVICE_ID:-}" ]]; then
    export ANDROID_SERIAL="${DEVICE_ID}"
  fi

  # 3.2) Якщо APK не встановлено — встановити (потрібен APK_PATH у .env.user1)
  if [[ -n "${APK_PATH:-}" && -n "${DEVICE_ID:-}" ]]; then
    if ! adb -s "${DEVICE_ID}" shell pm list packages | grep -q "^package:${appId}$"; then
      echo "⚙️ Installing ${appId} from ${APK_PATH}..."
      adb -s "${DEVICE_ID}" install -r "${APK_PATH}"
    fi
  fi

  # 3.3) Гарантуємо фото в галереї (png/jpg) + media rescan
  if [[ -n "${DEVICE_ID:-}" ]]; then
    DEVICE_PICS="/sdcard/Pictures"
    LOCAL_PNG="./accets/body.png"
    LOCAL_JPG="./accets/body.jpg"
    DEV_PNG="${DEVICE_PICS}/body.png"
    DEV_JPG="${DEVICE_PICS}/body.jpg"
    DEV_FALLBACK="${DEVICE_PICS}/zz_screencap.png"

    # створити папку, якщо немає
    adb -s "${DEVICE_ID}" shell "mkdir -p '${DEVICE_PICS}'" || true

    # якщо є локальний зразок — закинемо (спершу png, потім jpg)
    if [[ -f "${LOCAL_PNG}" ]]; then
      adb -s "${DEVICE_ID}" push "${LOCAL_PNG}" "${DEV_PNG}" >/dev/null || true
    fi
    if [[ -f "${LOCAL_JPG}" ]]; then
      adb -s "${DEVICE_ID}" push "${LOCAL_JPG}" "${DEV_JPG}" >/dev/null || true
    fi

    # якщо все ще немає жодного зображення — створимо скріншот як fallback
    if ! adb -s "${DEVICE_ID}" shell "[ -f '${DEV_PNG}' ] || [ -f '${DEV_JPG}' ] || [ -f '${DEV_FALLBACK}' ]"; then
      adb -s "${DEVICE_ID}" shell "screencap -p '${DEV_FALLBACK}'" || true
    fi

    # примусовий перескан медіа (broadcast — сумісний скрізь)
    adb -s "${DEVICE_ID}" shell 'am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_DIR -d file:///sdcard/Pictures' >/dev/null 2>&1 || true
    adb -s "${DEVICE_ID}" shell 'am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/body.png' >/dev/null 2>&1 || true
    adb -s "${DEVICE_ID}" shell 'am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/body.jpg' >/dev/null 2>&1 || true
    adb -s "${DEVICE_ID}" shell 'am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/zz_screencap.png' >/dev/null 2>&1 || true
  fi

  # 3.4) Збираємо ENV для Maestro
  EXTRA=( --env appId="${appId:?appId is missing}" )
  [[ -n "${EMAIL:-}"     ]] && EXTRA+=( --env EMAIL="${EMAIL}" )
  [[ -n "${PASSWORD:-}"  ]] && EXTRA+=( --env PASSWORD="${PASSWORD}" )
  [[ -n "${FIRSTNAME:-}" ]] && EXTRA+=( --env FIRSTNAME="${FIRSTNAME}" )
  [[ -n "${LASTNAME:-}"  ]] && EXTRA+=( --env LASTNAME="${LASTNAME}" )
  [[ -n "${NEW_EMAIL:-}" ]] && EXTRA+=( --env NEW_EMAIL="${NEW_EMAIL}" )
  [[ -n "${GOOGLE_ACCOUNT_EMAIL:-}" ]] && EXTRA+=( --env GOOGLE_ACCOUNT_EMAIL="${GOOGLE_ACCOUNT_EMAIL}" )

  # 3.5) Опційний fresh-start (керується FRESH_START=true)
  FRESH_START="${FRESH_START:-false}"

  if [[ "${FRESH_START}" == "true" && -n "${DEVICE_ID:-}" && -n "${appId:-}" ]]; then
    adb -s "${DEVICE_ID}" shell pm clear "${appId}" || true
    adb -s "${DEVICE_ID}" shell input keyevent 3 || true
    sleep 0.5
    adb -s "${DEVICE_ID}" shell monkey -p "${appId}" -c android.intent.category.LAUNCHER 1 >/dev/null
    sleep 1
  fi

  exec maestro test "${EXTRA[@]}" "${@:3}"
fi

# Фолбек: виконуємо довільну команду як є
exec "$@"

