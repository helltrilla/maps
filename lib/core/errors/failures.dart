abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Ошибка сети. Проверьте подключение.']);
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(
      [super.message = 'Сервер временно недоступен.', this.statusCode]);
}

class LocationFailure extends Failure {
  const LocationFailure(
      [super.message = 'Не удалось определить местоположение.']);
}

class CacheFailure extends Failure {
  const CacheFailure(
      [super.message = 'Ошибка чтения или записи локального кэша.']);
}

class ParseFailure extends Failure {
  const ParseFailure([super.message = 'Ошибка обработки данных сервера.']);
}
