import 'person_entity_service.dart';

main() async {
  final personService = PersonEntityService();
  final loadedPerson = await personService.getEntity("1");
  await personService.postEntity(loadedPerson);
}
