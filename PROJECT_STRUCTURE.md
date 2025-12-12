# Project Structure

## Overview

This document describes the structure of the Dart Code Generator project and explains each component.

## Directory Layout

```
dart-code-generator/
├── bin/
│   └── dart_code_generator.dart       # CLI entry point
├── lib/
│   ├── dart_code_generator.dart       # Main library export file
│   └── src/
│       ├── code_generator.dart        # Orchestrator - coordinates all generation
│       ├── api_parser.dart            # Parses API files using Dart analyzer
│       ├── model_parser.dart          # Parses model files using Dart analyzer
│       ├── helper_generator.dart      # Generates helper files with type conversions
│       └── model_generator.dart       # Generates new model files
├── test_input/                        # Sample input for testing
│   ├── api/
│   │   └── user_api.dart             # Example API file
│   └── model/
│       ├── user_models.dart          # Example model file
│       └── user_status.dart          # Example enum-style model
├── example_output/                    # Example generated output (gitignored)
├── pubspec.yaml                       # Package dependencies
├── analysis_options.yaml              # Dart linter configuration
├── .gitignore                         # Git ignore rules
├── README.md                          # Main documentation
├── USAGE.md                           # Detailed usage guide
└── generate_examples.sh               # Script to generate example output

```

## Component Details

### bin/dart_code_generator.dart
- Command-line interface entry point
- Parses command-line arguments using `args` package
- Validates input/output directories
- Instantiates and runs CodeGenerator

### lib/src/code_generator.dart
- Main orchestrator class
- Coordinates the entire code generation process
- Steps:
  1. Creates output directory structure (api/, models/)
  2. Scans for API files (files ending in `_api.dart`)
  3. Parses all model files first (to build type registry)
  4. For each API file:
     - Parses the API class and methods
     - Generates helper file
     - Generates transformed model files
  5. Writes all generated files to output directory

### lib/src/api_parser.dart
- Uses Dart analyzer package to parse API files
- Extracts:
  - Class name
  - All methods (excluding getters, setters, static methods)
  - Method return types
  - Method parameters (name, type, required, named)
- Returns ApiClass object containing all extracted information

### lib/src/model_parser.dart
- Uses Dart analyzer package to parse model files
- Extracts:
  - Class name
  - Instance fields (name, type, final)
  - Static fields (for enum detection)
  - Constructor information
- Detects enum-style classes:
  - Only has one instance field named 'value'
  - Has static fields (constants)
- Returns Map of ModelClass objects

### lib/src/helper_generator.dart
- Generates helper class files
- Key responsibilities:
  1. Generate imports (with notes for manual update)
  2. Transform method signatures:
     - `Future<GwResXxx>` → `Future<ResXxx>`
     - `Future<NoneObject>` → `Future<void>`
  3. Filter parameters (remove NoneObject)
  4. Generate method body:
     - Instantiate original API class
     - Convert new parameter types to old types
     - Call original method
     - Convert return value from old type to new type
- Handles type conversions by mapping field-by-field

### lib/src/model_generator.dart
- Generates new model files
- For each GwRes/GwReq model referenced in API:
  1. Check if should be enum (value field + static fields)
  2. Generate enum or class accordingly
  3. Transform field types if needed
  4. Generate proper constructor
- Output files named in snake_case

## Code Flow

```
User runs CLI command
    ↓
bin/dart_code_generator.dart validates args
    ↓
CodeGenerator.generate() is called
    ↓
ModelParser parses all models in model/ directory
    ↓
For each *_api.dart file:
    ↓
    ApiParser extracts class and methods
    ↓
    HelperGenerator creates helper file
    ↓
    ModelGenerator creates model files
    ↓
    Files written to output directory
```

## Testing

### Manual Testing
1. Run `./generate_examples.sh` to create example output
2. Review files in `example_output/` directory
3. Compare with expected output format

### With Dart SDK
```bash
# Install dependencies
dart pub get

# Run generator on test input
dart run bin/dart_code_generator.dart -s ./test_input -o ./test_output

# Review generated files
ls -R test_output/
```

## Key Design Decisions

1. **AST Parsing**: Uses Dart analyzer for accurate parsing instead of regex
2. **Two-phase approach**: Parse all models first, then process APIs
3. **Field-by-field conversion**: Maps fields individually for type conversions
4. **Comment-based imports**: Generated files have import path comments for user to update
5. **Snake case filenames**: Consistent with Dart conventions
6. **Enum detection**: Automatic detection based on field structure

## Extension Points

The code can be extended to:
- Support custom type mappings via configuration
- Add more sophisticated type conversions
- Support nested generic types
- Generate additional metadata or documentation
- Support different output formats
