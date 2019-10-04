import 'package:auto_data/auto_data.dart';
import 'package:meta/meta.dart';
import 'dart:convert';

import 'entity.dart';

part 'person_entity.g.dart';

@data
abstract class $PersonEntity implements Entity {
  String name;
  int age;
}
