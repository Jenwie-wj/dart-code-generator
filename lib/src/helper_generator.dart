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
    buffer.writeln('// This file is auto-generated. Do not edit manually.');
    buffer.writeln();
    buffer.writeln('// NOTE: Update this import path to point to your original API file:');
    buffer.writeln("// import 'package:your_package/api/${apiClass.originalFileName}';");
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

    // Generate model imports for generated models
    for (final modelName in requiredModels) {
      final transformedName = _transformModelName(modelName);
      if (transformedName != null && transformedName != 'void') {
        final fileName = _toSnakeCase(transformedName);
        buffer.writeln("import '../models/$fileName.dart';");
      }
    }

    // Add note about original model imports
    buffer.writeln();
    buffer.writeln('// NOTE: Update these import paths to point to your original model files:');
    for (final modelName in requiredModels) {
      if (modelName.startsWith('Gw') && modelName != 'NoneObject') {
        buffer.writeln("// import 'package:your_package/model/${_toSnakeCase(modelName)}.dart';");
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
    // Map the type names to the original model names (GwRes/GwReq)
    final originalFromType = _getOriginalModelName(fromType);
    final originalToType = _getOriginalModelName(toType);
    
    final fromModel = allModels[originalFromType];
    final toModel = allModels[originalToType];

    if (fromModel == null || toModel == null) {
      return varName;
    }

    // Check if source model should be converted to enum
    if (toModel.shouldBeEnum) {
      // Convert from enum-like class to actual enum
      // Generate a switch statement based on static field values
      final buffer = StringBuffer();
      buffer.write('(() {\n');
      buffer.write('      switch ($varName.value) {\n');
      
      for (final staticField in toModel.staticFields) {
        // Extract the value from the static field initializer
        // e.g., "GwResUserStatus(value: 'ACTIVE')" -> "ACTIVE"
        final valuePattern = RegExp(r"value:\s*'([^']+)'");
        final valueMatch = valuePattern.firstMatch(staticField.value);
        if (valueMatch != null) {
          final value = valueMatch.group(1);
          buffer.write("        case '$value': return $toType.${staticField.name};\n");
        }
      }
      
      final exceptionMsg = 'Unknown value: \${$varName.value}';
      buffer.write('        default: throw Exception("$exceptionMsg");\n');
      buffer.write('      }\n');
      buffer.write('    })()');
      
      return buffer.toString();
    }
    
    // Generate constructor call with field mappings
    final buffer = StringBuffer('$toType(');
    final fieldMappings = <String>[];

    for (final toField in toModel.fields) {
      final fromField = fromModel.fields.firstWhere(
        (f) => f.name == toField.name,
        orElse: () => ModelField(name: '', type: 'dynamic'),
      );

      if (fromField.name.isNotEmpty) {
        // Check if field type needs conversion (is a custom type)
        final fieldValue = _generateFieldConversion(
          '$varName.${fromField.name}',
          fromField.type,
          toField.type,
        );
        fieldMappings.add('${toField.name}: $fieldValue');
      }
    }

    buffer.write(fieldMappings.join(', '));
    buffer.write(')');

    return buffer.toString();
  }

  String _generateFieldConversion(String fieldAccess, String fromType, String toType) {
    // Check if the type is a custom Gw type that needs conversion
    final gwPattern = RegExp(r'Gw(?:Res|Req)(\w+)');
    final gwMatch = gwPattern.firstMatch(fromType);
    
    if (gwMatch != null) {
      // This is a custom type that needs conversion
      final originalTypeName = gwMatch.group(0)!;
      final transformedTypeName = _transformModelName(originalTypeName);
      
      if (transformedTypeName != null) {
        // Recursively convert nested custom type
        return _generateTypeConversion(fieldAccess, originalTypeName, transformedTypeName);
      }
    }
    
    // For primitive types or types that don't need conversion
    return fieldAccess;
  }

  // Convert ResXxx/ReqXxx back to GwResXxx/GwReqXxx for model lookup
  String _getOriginalModelName(String typeName) {
    if (typeName.startsWith('Res') && !typeName.startsWith('Response')) {
      return 'GwRes${typeName.substring(3)}';
    } else if (typeName.startsWith('Req') && !typeName.startsWith('Request')) {
      return 'GwReq${typeName.substring(3)}';
    }
    return typeName;
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
