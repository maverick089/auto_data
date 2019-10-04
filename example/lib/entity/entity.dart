/// AutoData interface
///  copyWith is missing due to Dart limitations
abstract class AutoData {
  Map<String, dynamic> toMap();
  AutoData.fromMap(Map<String, dynamic> m);

  String toJson();
  AutoData.fromJson(String json);
}

/// A basic entity interface
abstract class Entity implements AutoData {
  String get id;
}
