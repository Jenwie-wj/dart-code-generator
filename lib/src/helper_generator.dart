import 'api_parser.dart';
import 'model_parser.dart';

class HelperGenerator {
  final ApiClass apiClass;
  final Map<String, ModelClass> allModels;

  HelperGenerator(this.apiClass, this.allModels);

  String generate() {
    final buffer = StringBuffer();

    // Generate imports
    buffer.writeln('// Generated helper file for ${apiClass.originalFileName}');
    buffer.writeln("import 'dart:async';");
    buffer.writeln();

    // Import the original API file
    final originalApiFileName = apiClass.originalFileName;
    buffer.writeln("import '../source/api/$originalApiFileName';");
    buffer.writeln();

    // Collect all unique model imports needed
    final requiredModels = <String>{};
    for (final method in apiClass.methods) {
      // Extract model names from return type and parameters
      _collectModelNames(method.returnType, requiredModels);
      for (final param in method.parameters) {
        _collectModelNames(param.type, requiredModels);
      }
    }

    // Generate model imports
    for (final modelName in requiredModels) {
      final transformedName = _transformModelName(modelName);
      if (transformedName != null && transformedName != 'void') {
        final fileName = _toSnakeCase(transformedName);
        buffer.writeln("import '../models/$fileName.dart';");
      }
    }

    // Import original models
    for (final modelName in requiredModels) {
      if (modelName.startsWith('Gw') && modelName != 'NoneObject') {
        buffer.writeln("import '../source/model/${_toSnakeCase(modelName)}.dart';");
      }
    }

    buffer.writeln();

    // Generate helper class
    final helperClassName = _toHelperClassName(apiClass.originalFileName);
    buffer.writeln('abstract class $helperClassName {');

    // Generate methods
    for (final method in apiClass.methods) {
      buffer.writeln(_generateMethod(method));
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  String _generateMethod(ApiMethod method) {
    final buffer = StringBuffer();

    // Transform return type
    final newReturnType = _transformReturnType(method.returnType);

    // Filter and transform parameters
    final newParams = method.parameters
        .where((p) => p.type != 'NoneObject')
        .map((p) => _transformParameter(p))
        .toList();

    // Generate method signature
    buffer.write('  static $newReturnType ${method.name}(');

    // Generate parameters
    if (newParams.isEmpty) {
      buffer.write(') async {');
    } else {
      final paramStrings = newParams.map((p) {
        if (p.isNamed) {
          return '${p.isRequired ? 'required ' : ''}${p.type} ${p.name}';
        }
        return '${p.type} ${p.name}';
      }).toList();

      buffer.write(paramStrings.join(', '));
      buffer.write(') async {');
    }

    buffer.writeln();

    // Generate method body
    final hasReturn = !newReturnType.contains('void');

    // Convert parameters for the API call
    final apiCallParams = method.parameters.map((p) {
      if (p.type == 'NoneObject') {
        return 'NoneObject()';
      }
      final transformedType = _transformModelName(p.type);
      if (transformedType != null && transformedType != p.type) {
        // Need to convert from new type to old type
        return _generateTypeConversion(p.name, transformedType, p.type);
      }
      return p.name;
    }).join(', ');

    if (hasReturn) {
      final originalReturnType = _extractGenericType(method.returnType);
      buffer.writeln('    final $originalReturnType res = await ${apiClass.name}().${ method.name}($apiCallParams);');

      // Convert return value
      final newReturnModelType = _extractGenericType(newReturnType);
      if (newReturnModelType != originalReturnType) {
        buffer.writeln('    return ${_generateTypeConversion('res', originalReturnType, newReturnModelType)};');
      } else {
        buffer.writeln('    return res;');
      }
    } else {
      buffer.writeln('    await ${apiClass.name}().${method.name}($apiCallParams);');
    }

    buffer.writeln('  }');
    buffer.writeln();

    return buffer.toString();
  }

  String _transformReturnType(String returnType) {
    if (returnType.contains('Future<NoneObject>')) {
      return 'Future<void>';
    }

    return _replaceModelNames(returnType);
  }

  MethodParameter _transformParameter(MethodParameter param) {
    return MethodParameter(
      name: param.name,
      type: _replaceModelNames(param.type),
      isRequired: param.isRequired,
      isNamed: param.isNamed,
    );
  }

  String _replaceModelNames(String type) {
    var result = type;

    // Transform GwResXxx to ResXxx and GwReqXxx to ReqXxx
    final gwResPattern = RegExp(r'GwRes(\w+)');
    result = result.replaceAllMapped(gwResPattern, (match) => 'Res${match.group(1)}');

    final gwReqPattern = RegExp(r'GwReq(\w+)');
    result = result.replaceAllMapped(gwReqPattern, (match) => 'Req${match.group(1)}');

    return result;
  }

  String? _transformModelName(String modelName) {
    if (modelName.startsWith('GwRes')) {
      return modelName.replaceFirst('GwRes', 'Res');
    } else if (modelName.startsWith('GwReq')) {
      return modelName.replaceFirst('GwReq', 'Req');
    }
    return null;
  }

  void _collectModelNames(String type, Set<String> models) {
    // Extract model names from types like Future<GwResXxx>, List<GwReqYyy>, etc.
    final pattern = RegExp(r'(Gw(?:Res|Req)\w+)');
    final matches = pattern.allMatches(type);
    for (final match in matches) {
      models.add(match.group(1)!);
    }
  }

  String _extractGenericType(String type) {
    final match = RegExp(r'<(.+)>').firstMatch(type);
    return match?.group(1) ?? type;
  }

  String _generateTypeConversion(String varName, String fromType, String toType) {
    final fromModel = allModels[fromType];
    final toModel = allModels[toType];

    if (fromModel == null || toModel == null) {
      return varName;
    }

    // Check if it's an enum conversion
    if (toModel.shouldBeEnum) {
      // For enum, we just use the value
      return '$toType.${_toEnumCase(varName)}';
    }

    // Generate constructor call with field mappings
    final buffer = StringBuffer('$toType(');
    final fieldMappings = <String>[];

    for (final toField in toModel.fields) {
      final fromField = fromModel.fields.firstWhere(
        (f) => f.name == toField.name,
        orElse: () => ModelField(name: toField.name, type: 'dynamic'),
      );

      if (fromField.name.isNotEmpty) {
        fieldMappings.add('${toField.name}: $varName.${fromField.name}');
      }
    }

    buffer.write(fieldMappings.join(', '));
    buffer.write(')');

    return buffer.toString();
  }

  String _toHelperClassName(String fileName) {
    // Convert xx_api.dart to XxApiHelper
    final baseName = fileName.replaceAll('_api.dart', '');
    final parts = baseName.split('_');
    final camelCase = parts.map((p) => p[0].toUpperCase() + p.substring(1)).join();
    return '${camelCase}ApiHelper';
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => '_${match.group(1)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
  }

  String _toEnumCase(String input) {
    // Convert camelCase to SCREAMING_SNAKE_CASE for enum
    return input
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => '_${match.group(1)}')
        .toUpperCase()
        .replaceFirst(RegExp(r'^_'), '');
  }
}
