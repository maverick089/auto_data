import 'entity_service.dart';
import 'person_entity.dart';

class PersonEntityService extends EntityRestService<PersonEntity> {
  @override
  FromJsonFactory<PersonEntity> get fromJsonFactory =>
      (json) => PersonEntity.fromJson(json);

  @override
  String get restPath => "persons/";
}
