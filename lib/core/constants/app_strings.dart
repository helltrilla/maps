/// Централизованные строки интерфейса приложения.
/// Подготовлено для будущей интернационализации (l10n).
class AppStrings {
  const AppStrings._();

  // Общие
  static const String appTitle = 'Карты';
  static const String cancel = 'Отмена';
  static const String confirm = 'Подтвердить';
  static const String close = 'Закрыть';
  static const String delete = 'Удалить';
  static const String save = 'Сохранить';
  static const String copy = 'Копировать';
  static const String error = 'Ошибка';
  static const String loading = 'Загрузка...';

  // Сообщения
  static const String locationCopied = 'Ссылка на геопозицию скопирована';
  static const String pointAdded = 'Точка добавлена';
  static const String cacheErrorPrefix = 'Ошибка кеша: ';
  static const String noLocationAvailable = 'Геолокация недоступна';

  // Выбор точки на карте
  static const String pickStartPoint = 'Выберите точку отправления (А)';
  static const String pickDestinationPoint = 'Выберите точку назначения (Б)';
  static const String moveMapHint = 'Переместите карту под центральный пин';
  static const String selectThisPoint = 'Выбрать эту точку';
  static const String pickedPoint = 'Выбранная точка';

  // Слои карты
  static const String mapLayers = 'Слои карты';
  static const String layerDark = 'Тёмная (CartoDB)';
  static const String layerOsm = 'Стандартная (OSM)';
  static const String layerSatellite = 'Спутник (Esri)';
  static const String layerTopo = 'Топографическая';
  static const String layerCyclo = 'Велосипедная';

  // Поиск
  static const String searchPlaceholder = 'Поиск мест, адресов, кафе...';
  static const String searchNoResults = 'Ничего не найдено';
  static const String searchClear = 'Очистить историю';
  static const String searchNearbyPlaces = 'Места рядом';

  // Категории
  static const String categoryCafes = 'Кафе';
  static const String categoryRestaurants = 'Рестораны';
  static const String categoryShops = 'Магазины';
  static const String categoryPharmacies = 'Аптеки';
  static const String categoryGasStations = 'АЗС';
  static const String categoryHotels = 'Отели';
  static const String categoryBanks = 'Банки';
  static const String categorySaved = 'Мои метки';

  // Детали места
  static const String buildRoute = 'Маршрут';
  static const String planRoute = 'Задать маршрут';
  static const String routeFromHere = 'Отсюда';
  static const String routeToHere = 'Сюда';
  static const String address = 'Адрес';
  static const String coordinates = 'Координаты';
  static const String openingHours = 'Часы работы';
  static const String website = 'Сайт';
  static const String phone = 'Телефон';
  static const String photos = 'Фотографии';
  static const String reviews = 'Отзывы пользователей';
  static const String demoNotice = 'Демонстрационные данные';
  static const String pointOnMap = 'Точка на карте';

  // Маршрутизатор
  static const String routePlannerTitle = 'Маршрут';
  static const String routeStart = 'Откуда';
  static const String routeDestination = 'Куда';
  static const String myCurrentLocation = 'Моё местоположение';
  static const String pickOnMapAction = 'Указать на карте';
  static const String buildRouteAction = 'Построить маршрут';
  static const String swapPoints = 'Поменять местами';
  static const String clearRoute = 'Сбросить маршрут';
  static const String metersUnit = 'м';
  static const String kilometersUnit = 'км';
  static const String minutesUnit = 'мин';
  static const String hoursUnit = 'ч';
}
