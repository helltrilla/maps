# Условия использования, лицензии и квоты провайдеров

В данном документе приведён полный аудит всех внешних картографических, геопространственных и медиа-сервисов, используемых в приложении `Maps`, с официальными условиями использования, требованиями к атрибуции, лимитами и инструкциями по переводу в коммерческий продакшен.

---

## Сводная таблица провайдеров

| Сервис / Слой | Назначение | Провайдер по умолчанию | Допустимо для демо / портфолио | Допустимо для коммерции | Что менять в продакшене |
|---|---|---|:---:|:---:|---|
| **OSM Standard Tiles** | Базовый слой карты | `tile.openstreetmap.org` | Да | С ограничениями (Fair Use) | Собственные тайлы / MapTiler / Protomaps |
| **Esri World Imagery** | Спутниковый слой | `server.arcgisonline.com` | Да | Требует лицензию | Подписка ArcGIS / Mapbox Satellite |
| **CyclOSM** | Велосипедный слой | `tile-cyclosm.openstreetmap.fr` | Да | Нет (волонтёрский) | Собственный рендеринг CyclOSM |
| **OpenTopoMap** | Топографический слой | `tile.opentopomap.org` | Да | Нет (волонтёрский) | MapTiler Topo / собственный DEM-сервер |
| **Esri Dark Gray** | Тёмный ночной слой | `server.arcgisonline.com` | Да | Требует лицензию | Собственный Carto/Mapbox dark стиль |
| **OSRM** | Маршрутизация | `router.project-osrm.org` | Да (демо) | **НЕТ** (нет SLA) | Self-hosted OSRM Docker / Valhalla |
| **Overpass API** | Места рядом (POI) | `overpass-api.de` (+ зеркала) | Да | Ограниченно | Self-hosted Overpass / PostGIS POI |
| **Photon** | Поиск адресов и мест | `photon.komoot.io` | Да | Ограниченно (Fair Use) | Self-hosted Photon / Pelias |
| **Nominatim** | Резервный поиск | `nominatim.openstreetmap.org` | Да | **НЕТ** (макс 1 rps) | Self-hosted Nominatim / LocationIQ |
| **Unsplash** | Фотографии мест | `images.unsplash.com` | Да | Да (Unsplash License) | Собственный S3/CDN или Google Places |
| **Отзывы и рейтинги**| Карточка заведения | `MockPlaceDetailsDataSource` | Да (демо) | N/A (мок) | Собственный бэкенд отзывов |

---

## 1. Тайловые слои карты

### 1.1 OpenStreetMap Standard (`tile.openstreetmap.org`)
* **Лицензия данных**: Open Database License (ODbL) 1.0.
* **Политика тайлов**: [OSMF Tile Usage Policy](https://operations.osmfoundation.org/policies/tiles/).
* **Официальные лимиты**:
  * Запрещено использование в тяжелых мобильных приложениях без предварительного согласования.
  * Обязателен валидный `User-Agent` с идентификатором приложения и контактной информацией.
  * Запрещен массовый предварительный скачинг тайлов (кеширование на лету разрешено в разумных пределах).
* **Требуемая атрибуция**: `© OpenStreetMap contributors` (отображается в нижнем левом углу карты через `MapAttributionWidget`).
* **Коммерческое использование**: Разрешено только для умеренной нагрузки в рамках добросовестного использования (Fair Use). Для продакшена с высокой нагрузкой OSM Foundation прямо требует перехода на независимые тайловые серверы.
* **Решение для продакшена**:
  * Запуск собственного сервера тайлов на `renderd` / `tirex` / `tegola` + PostgreSQL/PostGIS.
  * Либо коммерческие провайдеры векторных/растровых тайлов: MapTiler, Stadia Maps, Protomaps, Thunderforest.
  * Переопределяется через `--dart-define=OSM_TILE_URL=https://your-tiles.example.com/{z}/{x}/{y}.png`.

### 1.2 Esri World Imagery (`server.arcgisonline.com`)
* **Лицензия / Условия**: [Esri Master License Agreement](https://www.esri.com/en-us/legal/terms/full-master-agreement) и ArcGIS Online Terms of Use.
* **Лимиты**: Публичные эндпоинты ArcGIS Online предоставляются для ознакомительного, персонального и некоммерческого тестирования.
* **Требуемая атрибуция**: `Tiles © Esri — Source: Esri, Maxar, Earthstar Geographics` (поддерживается в приложении).
* **Коммерческое использование**: Требует коммерческой подписки ArcGIS Developer или ArcGIS Location Platform.
* **Решение для продакшена**:
  * Приобретение ключа ArcGIS Developer и подстановка приватного URL с токеном.
  * Либо переход на спутниковые тайлы Mapbox Satellite или Google Maps Platform.
  * Переопределяется через `--dart-define=ESRI_SATELLITE_TILE_URL=...`.

### 1.3 CyclOSM (`tile-cyclosm.openstreetmap.fr`)
* **Лицензия / Условия**: Французское сообщество OpenStreetMap France и проект CyclOSM.
* **Лимиты**: Волонтёрская инфраструктура, не имеет SLA. Прямо запрещено использование в высоконагруженных коммерческих продуктах.
* **Требуемая атрибуция**: `© OpenStreetMap contributors. Tiles courtesy of CyclOSM`.
* **Коммерческое использование**: Не допускается без согласования с OSM-FR.
* **Решение для продакшена**:
  * Развёртывание открытого рендерера CyclOSM на собственной инфраструктуре ([CyclOSM GitHub](https://github.com/cyclosm/cyclosm-cartocss)).
  * Переопределяется через `--dart-define=CYCLOSM_TILE_URL=...`.

### 1.4 OpenTopoMap (`tile.opentopomap.org`)
* **Лицензия**: Данные: OSM (ODbL) + рельеф SRTM; стиль карты: CC-BY-SA 3.0.
* **Лимиты**: Сервер поддерживается энтузиастами и университетом Friedrich-Alexander-Universität Erlangen-Nürnberg. Очень жесткий Rate Limiting (при превышении IP временно банится).
* **Требуемая атрибуция**: `Map data: © OpenStreetMap contributors, SRTM | Map style: © OpenTopoMap (CC-BY-SA)`.
* **Коммерческое использование**: Запрещено без согласования с авторами проекта.
* **Решение для продакшена**:
  * Self-hosted рендеринг OpenTopoMap с генерацией изолиний высот из SRTM.
  * Либо коммерческий топо-провайдер Thunderforest (Outdoors / Landscape) / MapTiler Outdoor.
  * Переопределяется через `--dart-define=OPENTOPO_TILE_URL=...`.

### 1.5 Esri Dark Gray (`server.arcgisonline.com`)
* **Лицензия / Условия**: Аналогично Esri World Imagery (ArcGIS Online).
* **Требуемая атрибуция**: `Tiles © Esri — Esri, DeLorme, NAVTEQ`.
* **Решение для продакшена**:
  * Приобретение лицензии ArcGIS либо генерация темного стиля через MapLibre/Carto/Mapbox.
  * Переопределяется через `--dart-define=ESRI_DARK_TILE_URL=...`.

---

## 2. Маршрутизация (OSRM)

* **Используемый публичный эндпоинт**: `https://router.project-osrm.org/route/v1/driving`
* **Лицензия проекта OSRM**: BSD-2-Clause (открытый исходный код).
* **Условия публичного сервера**: Сервер `router.project-osrm.org` является **исключительно демонстрационным**. У него нет SLA, он подвержен жестким ограничениям по частоте запросов (Rate Limit) и может блокировать спам-трафик.
* **Коммерческое использование**: **Категорически не рекомендуется в продакшене** на публичном демо-сервере.
* **Решение для продакшена**:
  1. **Self-hosted OSRM Docker (Рекомендуется)**:
     ```bash
     # Скачать PBF региона (например, kaliningrad-latest.osm.pbf)
     docker run -t -v $(pwd):/data ghcr.io/project-osrm/osrm-backend osrm-extract -p /opt/car.lua /data/region.osm.pbf
     docker run -t -v $(pwd):/data ghcr.io/project-osrm/osrm-backend osrm-partition /data/region.osrm
     docker run -t -v $(pwd):/data ghcr.io/project-osrm/osrm-backend osrm-customize /data/region.osrm
     docker run -t -i -p 5000:5000 -v $(pwd):/data ghcr.io/project-osrm/osrm-backend osrm-routed --algorithm mld /data/region.osrm
     ```
  2. Альтернатива: Self-hosted Valhalla или GraphHopper.
  3. Коммерческие API: OpenRouteService, Mapbox Directions API.
* **Как переключить**:
  `--dart-define=OSRM_BASE_URL=https://routing.your-company.com/route/v1/driving`

---

## 3. Геопоиск и геокодинг (Photon и Nominatim)

### 3.1 Photon (`photon.komoot.io`)
* **Лицензия**: Проект с открытым кодом от Komoot (Apache License 2.0) на базе Elasticsearch и данных OSM.
* **Лимиты**: Публичный сервис без гарантий доступности, предназначен для умеренного использования.
* **Коммерческое использование**: Допустимо для небольших объёмов, но не гарантирует бесперебойную работу.
* **Решение для продакшена**:
  * Развернуть собственный Photon из открытого репозитория ([komoot/photon](https://github.com/komoot/photon)) c поисковым индексом нужной страны/региона.
  * Переопределяется через `--dart-define=PHOTON_BASE_URL=https://geocoder.your-company.com/api`.

### 3.2 Nominatim (`nominatim.openstreetmap.org`)
* **Лицензия**: ODbL 1.0.
* **Политика использования**: [Nominatim Usage Policy](https://operations.osmfoundation.org/policies/nominatim/).
* **Официальные лимиты**:
  * **Максимум 1 запрос в секунду (1 rps)**.
  * Обязателен честный контактный `User-Agent`.
  * Запрещен автодополнитель (autocomplete на каждое нажатие клавиши) — в нашем коде используется только как редкий резервный fallback при сбое Photon.
* **Коммерческое использование**: Публичный сервер запрещен для прямого коммерческого поиска в реальном времени.
* **Решение для продакшена**:
  * Использовать собственный инстанс Nominatim либо коммерческих провайдеров (LocationIQ, Geoapify).
  * Переопределяется через `--dart-define=NOMINATIM_BASE_URL=https://nominatim.your-company.com`.

---

## 4. Поиск мест рядом (Overpass API)

* **Используемые зеркала**:
  * `https://lz4.overpass-api.de/api/interpreter`
  * `https://overpass-api.de/api/interpreter`
  * `https://z.overpass-api.de/api/interpreter`
* **Лицензия данных**: ODbL 1.0.
* **Официальные лимиты Overpass**:
  * Ограничение слотов (обычно не более 2 параллельных запросов с одного IP).
  * Ограничение по памяти и времени выполнения запроса (`[timeout:6]`, `[maxsize:2097152]`).
  * При превышении нагрузки сервер возвращает HTTP 429 или 504.
* **Отказоустойчивость в коде**: В классе `OverpassDataSourceImpl` реализован механизм автоматического перебора зеркал при ошибках или таймауте текущего сервера.
* **Решение для продакшена**:
  * Развернуть собственный локальный Overpass сервер с базой данных `overpass-turbo` / `osm3s`.
  * Либо импортировать POI в базу данных PostgreSQL + PostGIS и отдавать места через быстрый REST API (на порядки быстрее, чем динамический опрос Overpass).
  * Переопределяется через `--dart-define=OVERPASS_MIRRORS=https://overpass1.my.com/api/interpreter,https://overpass2.my.com/api/interpreter`.

---

## 5. Фотографии, отзывы и рейтинги мест

### 5.1 Фотографии заведений
* В демонстрационной реализации используются прямые URL изображений с сервиса **Unsplash** (`images.unsplash.com`).
* **Лицензия Unsplash**: [Unsplash License](https://unsplash.com/license) разрешает бесплатное коммерческое и некоммерческое использование без необходимости получения разрешения или указания авторства (хотя указание приветствуется).
* **Для продакшена**: В коммерческом приложении фотографии должны храниться в собственном объектном хранилище (S3/GCS/Cloudinary), либо поступать из легального API (Google Places API, Foursquare Places API).

### 5.2 Отзывы и рейтинги пользователей
* **Честное маркирование**: В коде реализован `MockPlaceDetailsDataSource`, который явно генерирует демонстрационные карточки отзывов и оценок. В интерфейсе карточки места они однозначно помечены меткой **«(Демо)»**.
* **Юридический запрет на парсинг**:
  * Условия использования Google Maps Platform и Яндекс Карт прямо запрещают парсинг, скрейпинг или сохранение данных отзывов вне их официальных SDK/API.
  * В коде **нет** и не должно быть парсеров Google или Яндекс.
* **Решение для продакшена**:
  * Подключение собственного бэкенда с реальной системой отзывов пользователей вашего сервиса.
  * Либо подключение официального Google Places Details API (с соблюдением правил квотирования и обязательным показом логотипа «Powered by Google»).

---

## 6. Конфигурация приложения при сборке (`--dart-define`)

Все параметры централизованно вынесены в класс [`lib/core/config/app_config.dart`](file:///Users/helltrilla/flutter/maps/maps/lib/core/config/app_config.dart).

Покупатель или разработчик может скомпилировать приложение с собственными серверами без модификации исходного кода Dart:

```bash
flutter build apk --release \
  --dart-define=APP_NAME="My City Maps" \
  --dart-define=USER_AGENT_PACKAGE_NAME="com.mycompany.citymaps" \
  --dart-define=APP_USER_AGENT="CityMaps/1.0 (+https://mycompany.com)" \
  --dart-define=OSM_TILE_URL="https://tiles.mycompany.com/{z}/{x}/{y}.png" \
  --dart-define=OSRM_BASE_URL="https://router.mycompany.com/route/v1/driving" \
  --dart-define=PHOTON_BASE_URL="https://search.mycompany.com/api" \
  --dart-define=OVERPASS_MIRRORS="https://overpass.mycompany.com/api/interpreter"
```

Для локального запуска с кастомным OSRM:
```bash
flutter run --dart-define=OSRM_BASE_URL="http://localhost:5000/route/v1/driving"
```
