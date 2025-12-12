# Dart Code Generator

A Dart code generator that converts API files to helper files with automatic type transformations.

## Features

- Automatically generates helper classes from API files
- Transforms `GwResXxx` models to `ResXxx` (response models)
- Transforms `GwReqXxx` models to `ReqXxx` (request models)
- Converts models with single `value` field and static fields to enums
- Handles special cases like `NoneObject` and `Future<NoneObject>`
- Generates clean, maintainable code with proper imports

## Requirements

- Dart SDK >= 3.0.0

## Installation

1. Clone this repository
2. Run `dart pub get` to install dependencies

## Usage

```bash
dart run bin/dart_code_generator.dart -s <source_path> -o <output_path>
```

### Arguments

- `-s, --source`: Source folder path (required)
  - Must contain `api/` folder with `*_api.dart` files
  - Must contain `model/` folder with model class definitions

- `-o, --output`: Output folder path (required)
  - Will create `api/` folder for helper files
  - Will create `models/` folder for generated model files

- `-h, --help`: Show usage information

### Example

```bash
dart run bin/dart_code_generator.dart -s ./test_input -o ./test_output
```

## Input Structure

Your source folder should have the following structure:

```
source_folder/
├── api/
│   ├── user_api.dart
│   └── product_api.dart
└── model/
    ├── user_models.dart
    └── product_models.dart
```

### API Files

API files should:
- End with `_api.dart` suffix
- Contain a single class with methods
- Methods should return `Future<GwResXxx>` or `Future<NoneObject>`
- Methods can accept parameters of type `GwReqXxx` or primitives

Example:
```dart
class UserApi {
  Future<GwResUserInfo> getUserInfo(String token, GwReqGetUser body) async {
    // API implementation
  }
}
```

### Model Files

Model files should contain:
- Request models prefixed with `GwReq`
- Response models prefixed with `GwRes`
- Special `NoneObject` class for empty responses

Example:
```dart
class GwResUserInfo {
  const GwResUserInfo({required this.name, required this.age});
  final String name;
  final int age;
}

class GwReqGetUser {
  const GwReqGetUser({required this.userId});
  final String userId;
}
```

## Output Structure

The generator creates:

```
output_folder/
├── api/
│   ├── user_api_helper.dart
│   └── product_api_helper.dart
└── models/
    ├── res_user_info.dart
    ├── req_get_user.dart
    └── ...
```

### Helper Files

Helper files contain:
- Abstract class with static methods
- Automatic type conversion between Gw* and generated models
- Proper imports for all dependencies
- Comments indicating where to update import paths

Example output:
```dart
// Generated helper file for user_api.dart
// This file is auto-generated. Do not edit manually.

// NOTE: Update this import path to point to your original API file:
// import 'package:your_package/api/user_api.dart';

import '../models/res_user_info.dart';
import '../models/req_get_user.dart';

// NOTE: Update these import paths to point to your original model files:
// import 'package:your_package/model/gw_res_user_info.dart';
// import 'package:your_package/model/gw_req_get_user.dart';

abstract class UserApiHelper {
  static Future<ResUserInfo> getUserInfo(String token, ReqGetUser body) async {
    final GwResUserInfo res = await UserApi().getUserInfo(token, GwReqGetUser(userId: body.userId));
    return ResUserInfo(name: res.name, age: res.age);
  }
}
```

### Generated Model Files

- `res_xxx.dart`: Response models (transformed from `GwResXxx`)
- `req_xxx.dart`: Request models (transformed from `GwReqXxx`)
- Models with single `value` field become enums

Example response model (`res_user_info.dart`):
```dart
// Generated model class ResUserInfo
class ResUserInfo {
  const ResUserInfo({required this.name, required this.age});

  final String name;
  final int age;
}
```

Example request model (`req_get_user.dart`):
```dart
// Generated model class ReqGetUser
class ReqGetUser {
  const ReqGetUser({required this.userId});

  final String userId;
}
```

Example enum (`res_user_status.dart`):
```dart
// Generated enum ResUserStatus
enum ResUserStatus {
  active,
  inactive,
  suspended
}
```

## Transformation Rules

1. **Type Name Transformation**:
   - `GwResXxx` → `ResXxx`
   - `GwReqXxx` → `ReqXxx`

2. **Special Cases**:
   - `Future<NoneObject>` → `Future<void>`
   - `NoneObject` parameters are omitted

3. **Enum Conversion**:
   - Models with only a `value` field and static fields → enum
   - Static field names become enum values

4. **File Naming**:
   - Helper files: `xxx_api_helper.dart`
   - Model files: Snake case (e.g., `res_user_info.dart`)

## Development

### Project Structure

```
dart-code-generator/
├── bin/
│   └── dart_code_generator.dart    # CLI entry point
├── lib/
│   ├── dart_code_generator.dart    # Main library
│   └── src/
│       ├── code_generator.dart     # Main generator orchestrator
│       ├── api_parser.dart         # Parses API files
│       ├── model_parser.dart       # Parses model files
│       ├── helper_generator.dart   # Generates helper files
│       └── model_generator.dart    # Generates model files
├── test_input/                     # Sample input for testing
├── test_output/                    # Sample output
├── pubspec.yaml
└── README.md
```

### Testing

Run the generator with test input:

```bash
dart run bin/dart_code_generator.dart -s ./test_input -o ./test_output
```

Check the `test_output/` folder for generated files.

## License

MIT License
