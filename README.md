
# Проєктна структура (Maestro)

```
quantumbody_androidTest/
├─ Chains/
│  ├─ Onboarding_Chain.yaml         # запускає 00_ HappyPath → 01_ Skip
│  ├─ Auth_Chain.yaml               # логін/логаут/ресет
│  ├─ CreateLogs_Chain.yaml         # утиліти для логів/скрінів
│  ├─ Cleanup_Chain.yaml            # очистка стейту/видалення акаунту (за наявності)
│  └─ FullRegression_Chain.yaml     # зібраний набір важливих флоу
│
├─ Flows/                           # «будівельні блоки» (повторно вживаються)
│  ├─ auth/
│  ├─ onboarding/
│  │  └─ Onboarding_Flow.yaml       # спільні кроки онбордингу для reuse
│  ├─ common/                       # утилітарні кроки (очікування, скрол, тощо)
│  └─ logs/                         # зняття логів, скріни, збори артефактів
│
├─ Tests/                           # автономні тести (self-contained)
│  ├─ 01_Auth/
│  ├─ 02_Onboarding/
│  │  ├─ 00_Onboarding_HappyPath.yaml
│  │  ├─ 01_Onboarding_Skip.yaml
│  │  └─ 02_Onboarding_Notifications_Denied.yaml   # відкладено
│  ├─ 03_CreateLogs/
│  └─ 04_Account/
│
├─ debug/                           # локальні артефакти (логи/скріни від Maestro)
├─ run_with_env.sh                  # універсальний запуск (інʼєкція --env)
├─ .env.template                    # шаблон змінних середовища
├─ .env.user1                       # твій локальний профіль (у .gitignore)
├─ .gitignore
└─ README.md
```

## Принципи

* **Chains/** — композиції тестів; не містять кроків UI, тільки `runFlow`.

* **Flows/** — дрібні відновно-вживані шматки (login, onboarding step, утиліти).

* **Tests/** — повні сценарії, які можна запускати автономно (починаються з:

  ```yaml
  - clearState
  - launchApp
  ```

  і мають заголовок `appId: ${appId}`).

* Іменування тестів: двозначний префікс **`00_`, `01_`, `02_`** для порядку.

* Всі конфіги/секрети — лише через `.env.user1` → інʼєкція в Maestro робиться скриптом `run_with_env.sh`.

## Запуск (нагадування)

```bash
# одиночний
./run_with_env.sh maestro test Tests/02_Onboarding/00_Onboarding_HappyPath.yaml

# ланцюг
./run_with_env.sh maestro test Chains/Onboarding_Chain.yaml
```

## Приклад Chain

```yaml
# Chains/Onboarding_Chain.yaml
appId: ${appId}
name: Onboarding Chain
---
- runFlow: ../Tests/02_Onboarding/00_Onboarding_HappyPath.yaml
- runFlow: ../Tests/02_Onboarding/01_Onboarding_Skip.yaml
```

## Заголовок кожного тесту

```yaml
appId: ${appId}
---
# ...кроки...
```

## .env (шаблон)

```env
appId=com.example.app
EMAIL=testuser@example.com
PASSWORD=Qwerty123
FIRSTNAME=QA
LASTNAME=Tester
DEVICE_ID=emulator-5554
```

## Скрипт запуску (коротко)

* Підтягує `.env.user1` (або `.env`)
* Мапить `APP_ID → appId` (на сумісність)
* Інʼєктує `--env appId=...` та інші у `maestro test`
* Для вибору девайса використовує `ANDROID_SERIAL` (бо твоя версія Maestro без `--device`)

Якщо хочеш, додам сюди ще блок **“Міграція APP\_ID → appId у всіх репо”** з готовими командами пошуку/заміни.
