import 'entity.dart';

typedef FromMapFactory<T> = T Function(Map<String, dynamic> map);
typedef FromJsonFactory<T> = T Function(String json);

/// A generic entity service which be typically used to store and load data from an API
abstract class EntityRestService<T extends Entity> {
  final HttpClient http;

  EntityRestService({HttpClient http}) : http = http ?? HttpClient();

  /// It is not possible in Dart to use generic constructors, therefore we need to
  /// provide a function to create an instance of entity from a map
  FromJsonFactory<T> get fromJsonFactory;

  /// The path to the REST resource
  String get restPath;

  /// Generic post function
  Future<T> postEntity(T entity) async {
    final jsonEntity = entity.toJson();
    final response = await http.post(restPath, body: jsonEntity);
    return fromJsonFactory(response);
  }

  /// Generic get function
  Future<T> getEntity(String id) async {
    final response = await http.get('$restPath/$id/');
    return fromJsonFactory(response);
  }
}

/// Mock HttpClient to avoid dependency
class HttpClient {
  Future<String> post(String url, {String body}) async {
    return body;
  }

  Future<String> get(String url) async {
    return "";
  }
}
