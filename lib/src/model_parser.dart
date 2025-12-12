import 'dart:io';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class ModelField {
  final String name;
  final String type;
  final bool isFinal;

  ModelField({
    required this.name,
    required this.type,
    this.isFinal = false,
  });
}

class ModelStaticField {
  final String name;
  final String value;

  ModelStaticField({
    required this.name,
    required this.value,
  });
}

class ModelClass {
  final String name;
  final List<ModelField> fields;
  final List<ModelStaticField> staticFields;
  final bool hasConstructor;

  ModelClass({
    required this.name,
    required this.fields,
    required this.staticFields,
    this.hasConstructor = false,
  });

  // Check if this model should be converted to an enum
  // Rule: Only one instance field named 'value' and has static fields
  bool get shouldBeEnum {
    final nonStaticFields = fields.where((f) => f.name != 'value').toList();
    final hasValueField = fields.any((f) => f.name == 'value');
    return hasValueField && nonStaticFields.isEmpty && staticFields.isNotEmpty;
  }
}

class ModelParser {
  final String modelDirPath;

  ModelParser(this.modelDirPath);

  Map<String, ModelClass> parseAllModels() {
    final models = <String, ModelClass>{};
    final modelDir = Directory(modelDirPath);

    final dartFiles = modelDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final parsedModels = _parseFile(file.path);
      models.addAll(parsedModels);
    }

    return models;
  }

  Map<String, ModelClass> _parseFile(String filePath) {
    final models = <String, ModelClass>{};
    final file = File(filePath);
    final content = file.readAsStringSync();

    final parseResult = parseString(
      content: content,
      featureSet: FeatureSet.latestLanguageVersion(),
      throwIfDiagnostics: false,
    );

    final visitor = _ModelVisitor();
    parseResult.unit.visitChildren(visitor);

    for (final modelClass in visitor.classes) {
      models[modelClass.name] = modelClass;
    }

    return models;
  }
}

class _ModelVisitor extends RecursiveAstVisitor<void> {
  final List<ModelClass> classes = [];

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final className = node.name.lexeme;
    final fields = <ModelField>[];
    final staticFields = <ModelStaticField>[];
    var hasConstructor = false;

    for (final member in node.members) {
      if (member is FieldDeclaration) {
        if (member.isStatic) {
          // Static field
          for (final variable in member.fields.variables) {
            staticFields.add(ModelStaticField(
              name: variable.name.lexeme,
              value: variable.initializer?.toString() ?? '',
            ));
          }
        } else {
          // Instance field
          for (final variable in member.fields.variables) {
            fields.add(ModelField(
              name: variable.name.lexeme,
              type: member.fields.type?.toString() ?? 'dynamic',
              isFinal: member.fields.isFinal,
            ));
          }
        }
      } else if (member is ConstructorDeclaration) {
        hasConstructor = true;
      }
    }

    classes.add(ModelClass(
      name: className,
      fields: fields,
      staticFields: staticFields,
      hasConstructor: hasConstructor,
    ));
  }
}
