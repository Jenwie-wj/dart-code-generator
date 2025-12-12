import 'dart:io';
import 'package:args/args.dart';
import 'package:dart_code_generator/dart_code_generator.dart';

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption('source', abbr: 's', help: 'Source folder path', mandatory: true)
    ..addOption('output', abbr: 'o', help: 'Output folder path', mandatory: true)
    ..addFlag('help', abbr: 'h', help: 'Show usage', negatable: false);

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      print('Usage: dart_code_generator -s <source_path> -o <output_path>');
      print(parser.usage);
      return;
    }

    final sourcePath = results['source'] as String;
    final outputPath = results['output'] as String;

    final sourceDir = Directory(sourcePath);
    if (!sourceDir.existsSync()) {
      stderr.writeln('Error: Source directory does not exist: $sourcePath');
      exit(1);
    }

    final generator = CodeGenerator(sourcePath, outputPath);
    generator.generate();

    print('Code generation completed successfully!');
    print('Output directory: $outputPath');
  } catch (e) {
    stderr.writeln('Error: $e');
    print('\nUsage: dart_code_generator -s <source_path> -o <output_path>');
    print(parser.usage);
    exit(1);
  }
}
