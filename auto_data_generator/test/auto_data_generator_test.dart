import 'package:auto_data_generator/auto_data_generator.dart';
import 'package:test/test.dart';
import 'package:logging/logging.dart';
import 'package:source_gen/source_gen.dart';
import 'package:build/build.dart' show Builder, AssetId;
import 'package:build_test/build_test.dart';
import 'package:resource/resource.dart' show Resource;
import 'dart:convert' show utf8;

void main() {
  group('generator', () {
    test('contains basic properties', () async {
      expect(
          await generate(
            '''
import 'package:meta/meta.dart';
import 'package:auto_data/auto_data.dart';
import 'dart:convert';

part 'value.g.dart';

@data
class \$Value {
  double x;
  double y;
}
''',
          ),
          allOf([
            contains('  final double x;\n'),
            contains('  final double y;\n'),
          ]));
    });

    test('implements interface and overrrides properties', () async {
      expect(
          await generate(
            '''
import 'package:meta/meta.dart';
import 'package:auto_data/auto_data.dart';
import 'dart:convert';

part 'value.g.dart';

abstract class InterfaceClass {
  String get interfaceProperty;
}

@data
abstract class \$Value implements InterfaceClass {
  double x;
  double y;
}
''',
          ),
          allOf([
            contains('class Value implements InterfaceClass {'),
            contains('  final double x;\n'),
            contains('  final double y;\n'),
            contains('  final String interfaceProperty;\n'),
          ]));
    });

    test(
        'implements interfaces and overrrides properties of inherited interfaces',
        () async {
      expect(
          await generate(
            '''
import 'package:meta/meta.dart';
import 'package:auto_data/auto_data.dart';
import 'dart:convert';

part 'value.g.dart';

abstract class InterfaceClass1 {
  String get interfaceProperty1;
}

abstract class InterfaceClass2 implements InterfaceClass1 {
  String get interfaceProperty2;
}

@data
abstract class \$Value implements InterfaceClass2 {
  double x;
  double y;
}
''',
          ),
          allOf([
            contains('class Value implements InterfaceClass2 {'),
            contains('  final double x;\n'),
            contains('  final double y;\n'),
            contains('  final String interfaceProperty1;\n'),
            contains('  final String interfaceProperty2;\n'),
          ]));
    });
  });
}

// Test setup.
final String pkgName = 'pkg';
final Builder builder = PartBuilder([AutoDataGenerator()], '.g.dart');

Future<String> readSourceFile(String source) async {
  final resource = Resource(source);
  return await resource.readAsString(encoding: utf8);
}

Future<String> generate(String source) async {
  final sources = <String, String>{
    'auto_data|lib/src/annotations.dart':
        await readSourceFile("package:auto_data/src/annotations.dart"),
    'auto_data|lib/auto_data.dart':
        await readSourceFile("package:auto_data/auto_data.dart"),
    '$pkgName|lib/value.dart': source,
  };

  // Capture any error from generation; if there is one, return that instead of
  // the generated output.
  String error;
  void captureError(LogRecord logRecord) {
    if (logRecord.error is InvalidGenerationSourceError) {
      if (error != null) throw StateError('Expected at most one error.');
      error = logRecord.error.toString();
    }
  }

  final writer = InMemoryAssetWriter();
  await testBuilder(builder, sources,
      rootPackage: pkgName, writer: writer, onLog: captureError);

  final createdSource = error ??
      String.fromCharCodes(
          writer.assets[AssetId(pkgName, 'lib/value.g.dart')] ?? []);

  print(createdSource);
  return createdSource;
}
