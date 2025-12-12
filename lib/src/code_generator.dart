import 'dart:io';
import 'package:path/path.dart' as path;
import 'api_parser.dart';
import 'model_parser.dart';
import 'helper_generator.dart';
import 'model_generator.dart';

class CodeGenerator {
  final String sourcePath;
  final String outputPath;

  CodeGenerator(this.sourcePath, this.outputPath);

  void generate() {
    // Create output directories
    final apiOutputDir = Directory(path.join(outputPath, 'api'));
    final modelsOutputDir = Directory(path.join(outputPath, 'models'));

    if (apiOutputDir.existsSync()) {
      apiOutputDir.deleteSync(recursive: true);
    }
    if (modelsOutputDir.existsSync()) {
      modelsOutputDir.deleteSync(recursive: true);
    }

    apiOutputDir.createSync(recursive: true);
    modelsOutputDir.createSync(recursive: true);

    // Find all API files
    final apiDir = Directory(path.join(sourcePath, 'api'));
    if (!apiDir.existsSync()) {
      throw Exception('API directory not found: ${apiDir.path}');
    }

    final modelDir = Directory(path.join(sourcePath, 'model'));
    if (!modelDir.existsSync()) {
      throw Exception('Model directory not found: ${modelDir.path}');
    }

    // Parse all model files first
    final modelParser = ModelParser(modelDir.path);
    final allModels = modelParser.parseAllModels();

    // Process each API file
    final apiFiles = apiDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('_api.dart'));

    for (final apiFile in apiFiles) {
      print('Processing ${path.basename(apiFile.path)}...');

      // Parse API file
      final apiParser = ApiParser(apiFile.path);
      final apiClass = apiParser.parse();

      if (apiClass == null) {
        print('  Warning: No API class found in ${path.basename(apiFile.path)}');
        continue;
      }

      // Generate helper file
      final helperGenerator = HelperGenerator(apiClass, allModels);
      final helperContent = helperGenerator.generate();

      final helperFileName = path.basename(apiFile.path).replaceAll('_api.dart', '_api_helper.dart');
      final helperFile = File(path.join(apiOutputDir.path, helperFileName));
      helperFile.writeAsStringSync(helperContent);

      // Generate model files
      final modelGenerator = ModelGenerator(apiClass, allModels);
      final generatedModels = modelGenerator.generate();

      for (final entry in generatedModels.entries) {
        final modelFile = File(path.join(modelsOutputDir.path, entry.key));
        modelFile.writeAsStringSync(entry.value);
      }

      print('  Generated: $helperFileName');
      print('  Generated ${generatedModels.length} model files');
    }
  }
}
