import 'dart:io';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class ApiMethod {
  final String name;
  final String returnType;
  final List<MethodParameter> parameters;

  ApiMethod({
    required this.name,
    required this.returnType,
    required this.parameters,
  });
}

class MethodParameter {
  final String name;
  final String type;
  final bool isRequired;
  final bool isNamed;

  MethodParameter({
    required this.name,
    required this.type,
    this.isRequired = false,
    this.isNamed = false,
  });
}

class ApiClass {
  final String name;
  final List<ApiMethod> methods;
  final String originalFileName;

  ApiClass({
    required this.name,
    required this.methods,
    required this.originalFileName,
  });
}

class ApiParser {
  final String filePath;

  ApiParser(this.filePath);

  ApiClass? parse() {
    final file = File(filePath);
    final content = file.readAsStringSync();

    final parseResult = parseString(
      content: content,
      featureSet: FeatureSet.latestLanguageVersion(),
      throwIfDiagnostics: false,
    );

    final visitor = _ApiVisitor();
    parseResult.unit.visitChildren(visitor);

    if (visitor.apiClass == null) {
      return null;
    }

    return ApiClass(
      name: visitor.apiClass!,
      methods: visitor.methods,
      originalFileName: file.uri.pathSegments.last,
    );
  }
}

class _ApiVisitor extends RecursiveAstVisitor<void> {
  String? apiClass;
  final List<ApiMethod> methods = [];

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // Only process the first class found
    if (apiClass == null) {
      apiClass = node.name.lexeme;
      super.visitClassDeclaration(node);
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isStatic || node.isAbstract || node.isSetter || node.isGetter) {
      return;
    }

    final returnType = node.returnType?.toString() ?? 'dynamic';
    final methodName = node.name.lexeme;
    final parameters = <MethodParameter>[];

    if (node.parameters != null) {
      for (final param in node.parameters!.parameters) {
        if (param is SimpleFormalParameter) {
          parameters.add(MethodParameter(
            name: param.name?.lexeme ?? '',
            type: param.type?.toString() ?? 'dynamic',
            isRequired: param.isRequired,
            isNamed: param.isNamed,
          ));
        } else if (param is DefaultFormalParameter) {
          final innerParam = param.parameter;
          if (innerParam is SimpleFormalParameter) {
            parameters.add(MethodParameter(
              name: innerParam.name?.lexeme ?? '',
              type: innerParam.type?.toString() ?? 'dynamic',
              isRequired: param.isRequired,
              isNamed: param.isNamed,
            ));
          }
        }
      }
    }

    methods.add(ApiMethod(
      name: methodName,
      returnType: returnType,
      parameters: parameters,
    ));
  }
}
