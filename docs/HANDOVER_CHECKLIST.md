# Руководство по передаче проекта и релизной сборке (Handover Checklist)

Данный документ предназначен для покупателя, нового владельца или команды сопровождения репозитория `Maps`. В нём подробно описаны шаги по перенастройке идентификаторов под вашу организацию, генерации ключей подписи, сборке релизных пакетов (Android APK/AAB, iOS IPA) и передаче доступов.

---

## 1. Чек-лист передачи проекта покупателю

### 1.1 Что передаётся покупателю
- [x] Полный исходный код репозитория (ветка `main` / релизные теги) без зависимостей от личных локальных путей разработчика.
- [x] Настроенная модульная архитектура Feature-First Clean Architecture (`lib/core`, `lib/features`).
- [x] Настроенный пайплайн непрерывной интеграции (CI) GitHub Actions (`.github/workflows/ci.yml`).
- [x] Набор автоматических unit- и widget-тестов (40 тестов с замоканным HTTP).
- [x] Комплект документации: `README.md`, `README.ru.md`, `CHANGELOG.md`, `docs/PROVIDERS_AND_LICENSES.md`.
- [x] Права владельца (Organization Owner или Admin) в GitHub репозитории.

### 1.2 Что необходимо перегенерировать покупателю
- [ ] **Android Keystore**: сгенерировать собственный приватный ключ подписи для релиза в Google Play.
- [ ] **Apple Developer Certificate & Provisioning Profile**: настроить команду подписи в Xcode под ваш Apple Developer Account.
- [ ] **Собственные серверы API**: развернуть или подключить коммерческие сервисы (OSRM, Photon, тайлы OSM) и подставить их через `--dart-define` (см. раздел 4).
- [ ] **Секреты и переменные CI/CD**: настроить GitHub Actions Secrets (если планируется автоматическая сборка и деплой в App Store / Google Play).

### 1.3 Управление доступами
- [ ] Передать права администратора в репозитории новому владельцу.
- [ ] Отозвать доступы предыдущих контрибьюторов и разработчиков.
- [ ] Удалить устаревшие SSH deploy keys и персональные токены доступа (PAT).
- [ ] Настроить доступ к Google Play Console и Apple App Store Connect для аккаунтов покупателя.

---

## 2. Смена Bundle ID и названия организации

По умолчанию в проекте используется идентификатор `com.helltrilla.maps`. Чтобы заменить его на идентификатор вашей компании (например, `com.yourcompany.maps`), выполните следующие шаги:

### 2.1 Android
1. **`android/app/build.gradle.kts`**:
   - Измените `namespace = "com.yourcompany.maps"`
   - Измените `applicationId = "com.yourcompany.maps"`
2. **Каталог исходного кода MainActivity**:
   - Переместите файл `MainActivity.kt` в структуру папок, соответствующую новому пакету:
     `android/app/src/main/kotlin/com/yourcompany/maps/MainActivity.kt`
   - В начале файла укажите: `package com.yourcompany.maps`

### 2.2 iOS
1. **`ios/Runner.xcodeproj/project.pbxproj`**:
   - Найдите строки `PRODUCT_BUNDLE_IDENTIFIER = com.helltrilla.maps;` и замените на `PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.maps;`.
   - Замените `PRODUCT_BUNDLE_IDENTIFIER = com.helltrilla.maps.RunnerTests;` на `com.yourcompany.maps.RunnerTests;`.
2. **Либо откройте проект в Xcode**:
   - Откройте `ios/Runner.xcworkspace` в Xcode.
   - Выберите таргет **Runner** ➔ вкладка **Signing & Capabilities**.
   - Измените **Bundle Identifier** на `com.yourcompany.maps` и выберите вашу команду в поле **Team**.

### 2.3 Конфигурация приложения (`AppConfig`)
В файле [`lib/core/config/app_config.dart`](../lib/core/config/app_config.dart) измените значение по умолчанию для `USER_AGENT_PACKAGE_NAME`:
```dart
static const String userAgentPackageName = String.fromEnvironment(
  'USER_AGENT_PACKAGE_NAME',
  defaultValue: 'com.yourcompany.maps',
);
```

---

## 3. Настройка подписи релизных сборок

### 3.1 Подпись Android (Google Play)

1. **Генерация Keystore**:
   Выполните в терминале команду (замените плейсхолдеры на ваши данные):
   ```bash
   keytool -genkey -v -keystore release-keystore.jks \
     -alias maps-key -keyalg RSA -keysize 2048 -validity 10000
   ```

2. **Создание файла `android/key.properties`**:
   Создайте файл `android/key.properties` (он уже добавлен в `.gitignore`):
   ```properties
   storePassword=ваш_пароль_хранилища
   keyPassword=ваш_пароль_ключа
   keyAlias=maps-key
   storeFile=/полный/путь/к/release-keystore.jks
   ```

3. **Подключение к `android/app/build.gradle.kts`**:
   В блоке `android`:
   ```kotlin
   val keystorePropertiesFile = rootProject.file("key.properties")
   val keystoreProperties = java.util.Properties()
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
   }

   signingConfigs {
       create("release") {
           keyAlias = keystoreProperties["keyAlias"] as String?
           keyPassword = keystoreProperties["keyPassword"] as String?
           storeFile = keystoreProperties["storeFile"]?.let { file(it) }
           storePassword = keystoreProperties["storePassword"] as String?
       }
   }

   buildTypes {
       release {
           signingConfig = if (keystorePropertiesFile.exists()) {
               signingConfigs.getByName("release")
           } else {
               signingConfigs.getByName("debug")
           }
       }
   }
   ```

---

## 4. Сборка релизных пакетов

### 4.1 Предварительные проверки качества
Перед запуском релизной сборки убедитесь, что все проверки проходят успешно:
```bash
# 1. Проверка форматирования
dart format --output=none --set-exit-if-changed .

# 2. Строгий статический анализ (0 ошибок, 0 предупреждений)
flutter analyze --fatal-infos

# 3. Полный прогон тестов
flutter test
```

### 4.2 Сборка Android

#### Релизный APK (для прямого распространения / тестирования):
```bash
flutter build apk --release \
  --dart-define=USER_AGENT_PACKAGE_NAME=com.yourcompany.maps \
  --dart-define=APP_USER_AGENT="YourCompanyMaps/1.0 (+https://yourcompany.com)"
```
Результат: `build/app/outputs/flutter-apk/app-release.apk`

#### Релизный App Bundle (AAB для публикации в Google Play):
```bash
flutter build appbundle --release \
  --dart-define=USER_AGENT_PACKAGE_NAME=com.yourcompany.maps \
  --dart-define=APP_USER_AGENT="YourCompanyMaps/1.0 (+https://yourcompany.com)"
```
Результат: `build/app/outputs/bundle/release/app-release.aab`

### 4.3 Сборка iOS

#### Сборка архива и IPA для App Store Connect:
```bash
flutter build ipa --release \
  --dart-define=USER_AGENT_PACKAGE_NAME=com.yourcompany.maps \
  --dart-define=APP_USER_AGENT="YourCompanyMaps/1.0 (+https://yourcompany.com)"
```
Результат: `build/ios/ipa/*.ipa`

Загрузка в App Store Connect через Xcode Organizer или командную строку:
```bash
xcrun altool --upload-app --type ios -f build/ios/ipa/*.ipa \
  --apiKey YOUR_API_KEY --apiIssuer YOUR_ISSUER_ID
```

---

## 5. Флаги конфигурации продакшен-бэкенда

При коммерческой эксплуатации публичные серверы OSM, OSRM и Overpass должны быть заменены на собственные или коммерческие аналоги с SLA. Подробный технический анализ приведен в [`docs/PROVIDERS_AND_LICENSES.md`](PROVIDERS_AND_LICENSES.md).

При сборке передаются соответствующие аргументы `--dart-define`:

| Флаг `--dart-define` | Назначение | Пример для продакшена |
|:---|:---|:---|
| `OSRM_BASE_URL` | Сервер автомобильной маршрутизации | `https://osrm.yourcompany.com/route/v1/driving` |
| `PHOTON_BASE_URL` | Сервер геопоиска адресов и объектов | `https://photon.yourcompany.com/api` |
| `NOMINATIM_BASE_URL` | Резервный геопоиск | `https://nominatim.yourcompany.com` |
| `OVERPASS_MIRRORS` | Список зеркал Overpass POI через запятую | `https://overpass.yourcompany.com/api` |
| `CUSTOM_TILE_URL` | Шаблон собственного сервера тайлов | `https://tiles.yourcompany.com/{z}/{x}/{y}.png` |
| `USER_AGENT_PACKAGE_NAME` | Идентификатор пакета для тайлов | `com.yourcompany.maps` |
| `APP_USER_AGENT` | Строка User-Agent для всех API | `MyMaps/1.0 (+support@yourcompany.com)` |

### Полный пример команды релизной сборки с продакшен-бэкендом:
```bash
flutter build appbundle --release \
  --dart-define=USER_AGENT_PACKAGE_NAME=com.yourcompany.maps \
  --dart-define=APP_USER_AGENT="YourApp/1.0 (+support@yourcompany.com)" \
  --dart-define=OSRM_BASE_URL=https://osrm.yourcompany.com/route/v1/driving \
  --dart-define=PHOTON_BASE_URL=https://photon.yourcompany.com/api \
  --dart-define=NOMINATIM_BASE_URL=https://nominatim.yourcompany.com \
  --dart-define=OVERPASS_MIRRORS=https://overpass.yourcompany.com/api \
  --dart-define=CUSTOM_TILE_URL=https://tiles.yourcompany.com/{z}/{x}/{y}.png
```

---

## 6. Чек-лист соответствия требованиям магазинов приложений

### Google Play:
- [x] Наличие `targetSdkVersion = 34` (Android 14).
- [x] Разрешения `ACCESS_FINE_LOCATION` и `ACCESS_COARSE_LOCATION` объявлены в `AndroidManifest.xml`.
- [x] Сборка в формате Android App Bundle (`.aab`).
- [x] Корректная иконка приложения (`mipmap-*/ic_launcher.png`).
- [x] Политика конфиденциальности (Privacy Policy) с указанием сбора геолокационных данных для навигации.

### Apple App Store:
- [x] Понятные, подробные строки назначения в `ios/Runner/Info.plist`:
  - `NSLocationWhenInUseUsageDescription` (поиск мест, отображение позиции, маршруты).
  - `NSLocationAlwaysAndWhenInUseUsageDescription` (ведение по маршруту).
  - `NSLocationAlwaysUsageDescription`.
- [x] Корректные иконки всех размеров в `ios/Runner/Assets.xcassets/AppIcon.appiconset/`.
- [x] Наличие видимой атрибуции картографических данных на экране карты (`MapAttributionWidget`, &copy; OpenStreetMap contributors).
