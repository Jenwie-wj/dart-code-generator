import 'api_parser.dart';
import 'model_parser.dart';

class ModelGenerator {
  final ApiClass apiClass;
  final Map<String, ModelClass> allModels;

  ModelGenerator(this.apiClass, this.allModels);

  Map<String, String> generate() {
    final generatedFiles = <String, String>{};
    final processedModels = <String>{};

    // Collect all models referenced in the API
    for (final method in apiClass.methods) {
      _processType(method.returnType, generatedFiles, processedModels);
      for (final param in method.parameters) {
        _processType(param.type, generatedFiles, processedModels);
      }
    }

    return generatedFiles;
  }

  void _processType(String type, Map<String, String> files, Set<String> processed) {
    // Extract all GwRes and GwReq models from the type
    final pattern = RegExp(r'(Gw(?:Res|Req)\w+)');
    final matches = pattern.allMatches(type);

    for (final match in matches) {
      final modelName = match.group(1)!;
      if (processed.contains(modelName) || modelName == 'NoneObject') {
        continue;
      }

      processed.add(modelName);

      final model = allModels[modelName];
      if (model == null) {
        continue;
      }

      // Generate the new model
      final newModelName = _transformModelName(modelName);
      if (newModelName == null) {
        continue;
      }

      final fileName = '${_toSnakeCase(newModelName)}.dart';

      if (model.shouldBeEnum) {
        files[fileName] = _generateEnumModel(newModelName, model);
      } else {
        files[fileName] = _generateClassModel(newModelName, model);
      }

      // Recursively process nested custom types
      for (final field in model.fields) {
        _processType(field.type, files, processed);
      }
    }
  }

  String _generateClassModel(String className, ModelClass model) {
    final buffer = StringBuffer();

    buffer.writeln('// Generated model class $className');
    buffer.writeln('class $className {');

    // Constructor
    if (model.fields.isNotEmpty) {
      buffer.write('  const $className({');

      final paramList = model.fields.map((f) {
        return 'required this.${f.name}';
      }).join(', ');

      buffer.write(paramList);
      buffer.writeln('});');
      buffer.writeln();

      // Fields
      for (final field in model.fields) {
        // Add comment if available
        if (field.comment != null && field.comment!.isNotEmpty) {
          buffer.writeln('  ${field.comment}');
        }
        
        // Transform field type from GwRes/GwReq to Res/Req
        final transformedType = _transformFieldType(field.type);
        buffer.writeln('  final $transformedType ${field.name};');
      }
    } else {
      buffer.writeln('  const $className();');
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  String _generateEnumModel(String enumName, ModelClass model) {
    final buffer = StringBuffer();

    buffer.writeln('// Generated enum $enumName');
    buffer.write('enum $enumName {');

    // Generate enum values from static fields
    final enumValues = model.staticFields.map((f) => f.name).toList();

    if (enumValues.isNotEmpty) {
      buffer.writeln();
      for (int i = 0; i < enumValues.length; i++) {
        buffer.write('  ${enumValues[i]}');
        if (i < enumValues.length - 1) {
          buffer.writeln(',');
        } else {
          buffer.writeln();
        }
      }
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  String? _transformModelName(String modelName) {
    if (modelName.startsWith('GwRes')) {
      return modelName.replaceFirst('GwRes', 'Res');
    } else if (modelName.startsWith('GwReq')) {
      return modelName.replaceFirst('GwReq', 'Req');
    }
    return null;
  }

  String _transformFieldType(String type) {
    // Transform GwRes and GwReq types in the field type
    // This handles simple types, generics, and complex types
    return type
        .replaceAllMapped(
            RegExp(r'GwRes(\w+)'), (match) => 'Res${match.group(1)}')
        .replaceAllMapped(
            RegExp(r'GwReq(\w+)'), (match) => 'Req${match.group(1)}');
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => '_${match.group(1)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
  }
}
