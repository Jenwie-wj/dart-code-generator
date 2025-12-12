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

## Original Requirements (Chinese)

帮我用 dart 实现一个dart包，功能是把现成的 dart 文件的方法转换成调用该方法的文件，我会给一个源文件夹路径，里面有api 文件夹和model 文件夹，api 文件夹里有多个以'_api.dart'为后缀的类文件，每个类文件有一个类定义，你需要把类里的所有方法收集起来生成一个新文件，新文件名为源文件名+'_helper'后缀，例如源文件名为'xx_api.dart'，则新文件名为'xx_api_helper.dart'。新文件由一个抽象类组成，抽象类名根据文件名为驼峰式命名，如'xx_api_helper.dart'则抽象类名为'XxApiHelper'，抽象类里的方法均为静态方法，方法名与源文件的一致，返回值需要根据源文件中的返回值的类名新建一个类，源文件的返回值类均在 model 文件夹中，你需要自己去寻找，新建的返回值类的类名参考源文件的返回值类名，例如源文件为'GwResXxx'，则新文件为'ResXxx'，返回值有特例情况：如果源文件返回值是'Future<NoneObject>'则新文件的返回值改为'Future<void>'；新文件的方法参数与源文件一致，请求体的类也需要新建一个类，可在 model 文件中查找类定义，新的请求体类名参考源文件的请求体类名，例如源文件为'GwReqXxx'，则新文件为'ReqXxx'，请求体有特例情况：如果请求体类型为'NoneObject'，则该方法忽略这个参数；新方法的方法体为调用源文件的同名方法，并返回新的返回值类对象，调用源文件同名方法时，源方法的参数由新方法的参数转换而成，新方法的返回值由源方法的返回值转换而成。

注意：源 model 可能存在只有一个字段为 value 的情况，此时需要把该 model 的所有静态字段变成 enum 枚举类型，枚举值为静态字段的名称

要求把新的'xxx_api_helper.dart'文件统一输出为一个名为'api'的文件夹中，'res_xxx.dart'和'req_xxx.dart'的文件统一输出为另一个名为'models'的文件夹中。

脚本输入：源文件夹目录路径、新文件夹目录路径
脚本输出：一个包含'api'文件夹和'models'文件夹的文件夹
