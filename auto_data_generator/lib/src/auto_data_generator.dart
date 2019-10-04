// Copyright 2019, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of auto_data_generator;

Builder autoData(BuilderOptions _) =>
    new SharedPartBuilder([new AutoDataGenerator()], 'auto_data');

class DataClass {
  final String name;
  final String interface;
  final List<DataClassProperty> props;
  final List<DataClassConstructor> constructors;
  final List<FieldElement> fieldElements;
  final List<ConstructorElement> constElements;
  final String documentationComment;

  DataClass(
    this.name,
    this.interface,
    this.props,
    this.constructors,
    this.fieldElements,
    this.constElements, {
    this.documentationComment,
  });
}

class DataClassConstructor {
  final String declaration;
  final String documentationComment;

  DataClassConstructor(this.declaration, [this.documentationComment]);
}

class DataClassProperty {
  final String name;
  final String type;
  final bool isNullable;
  final bool isEnum;
  final bool isInterface;
  final String assignmentString;
  final String documentationComment;

  DataClassProperty(
    this.name,
    this.type,
    this.isNullable,
    this.isEnum,
    this.isInterface, [
    this.assignmentString,
    this.documentationComment,
  ]);
}

class AutoDataGenerator extends Generator {
  const AutoDataGenerator();

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final classes = List<DataClass>();
    library.annotatedWith(TypeChecker.fromRuntime(Data)).forEach((e) {
      final visitor = DataElementVisitor(library);
      e.element.accept(visitor);
      e.element.visitChildren(visitor);
      final c = DataClass(
        e.element.name.substring(1),
        visitor.interface,
        visitor.props,
        visitor.constructors,
        visitor.fieldElements,
        visitor.constElements,
        documentationComment: e.element.documentationComment,
      );
      classes.add(c);
    });

    final result = FileGenerator.generate(classes);

    if (result.length > 0) {
      return result.toString().replaceAll('\$', '');
    }

    return null;
  }
}

class DataElementVisitor<T> extends SimpleElementVisitor<T> {
  String interface;
  final List<DataClassProperty> props = [];
  final List<DataClassConstructor> constructors = [];
  final List<FieldElement> fieldElements = [];
  final List<ConstructorElement> constElements = [];

  final LibraryReader library;

  DataElementVisitor(this.library);

  @override
  T visitClassElement(ClassElement element) {
    if (element.interfaces.isNotEmpty) {
      interface = element.interfaces.first.name;
      element.interfaces.forEach(
        (interface) => _parseInterfaceElement(interface.element),
      );
    }
  }

  _parseInterfaceElement(ClassElement element) {
    element.fields.forEach(
      (field) => props.add(_parseFieldElement(field, true)),
    );
  }

  @override
  T visitFieldElement(FieldElement element) {
    props.add(_parseFieldElement(element, false));
    fieldElements.add(element);
  }

  @override
  T visitConstructorElement(ConstructorElement element) {
    final parsedLibrary =
        element.session.getParsedLibraryByElement(element.library);
    final declaration = parsedLibrary.getElementDeclaration(element);
    if (declaration != null && declaration.node != null) {
      var s = declaration.node.toSource();
      s = s.startsWith('\$') ? s.substring(1) : s;
      constructors.add(DataClassConstructor(s, element.documentationComment));
      constElements.add(element);
    }
  }

  DataClassProperty _parseFieldElement(FieldElement element, bool isInterface) {
    final parsedLibrary =
        element.session.getParsedLibraryByElement(element.library);
    final declaration = parsedLibrary.getElementDeclaration(element);
    final ee = library.findType(element.type.name);
    final name = element.name;
    final type = element.type.displayName;
    final comment = element.documentationComment;
    final isNullable = element.metadata.any((a) => a.toSource() == '@nullable');
    final isEnum = ee?.isEnum ?? false;

    String assignmentString;
    if (declaration != null && declaration.node != null) {
      assignmentString = declaration.node.toSource();
      assignmentString = assignmentString.substring(name.length);
      if (assignmentString.length <= 0) {
        assignmentString = null;
      }
    }

    return DataClassProperty(
        name, type, isNullable, isEnum, isInterface, assignmentString, comment);
  }
}
