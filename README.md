# Dart Code Generator (Dart 代码生成器)

✅ **已实现** - This requirement has been fully implemented!

## 功能说明 (Features)

本工具实现了一个 Dart 代码生成器，可以自动将现有的 API 文件转换为带有类型转换的辅助文件。

A Dart code generator that automatically converts API files to helper files with type transformations.

### 核心功能 (Core Features)

1. ✅ 自动扫描 `api/` 文件夹中所有 `*_api.dart` 文件
2. ✅ 解析每个 API 类的所有方法
3. ✅ 生成对应的 `*_api_helper.dart` 辅助文件
4. ✅ 自动转换类型：
   - `GwResXxx` → `ResXxx` (响应模型)
   - `GwReqXxx` → `ReqXxx` (请求模型)
5. ✅ 特殊情况处理：
   - `Future<NoneObject>` → `Future<void>`
   - `NoneObject` 参数自动忽略
6. ✅ 枚举转换：只有 `value` 字段的模型 → enum 类型
7. ✅ 文件输出到指定文件夹结构

## 使用方法 (Usage)

```bash
dart run bin/dart_code_generator.dart -s <源文件夹路径> -o <输出文件夹路径>
```

### 参数说明 (Arguments)

- `-s, --source`: 源文件夹路径（必需）
  - 必须包含 `api/` 文件夹和 `model/` 文件夹
- `-o, --output`: 输出文件夹路径（必需）
  - 将自动创建 `api/` 和 `models/` 文件夹

### 示例 (Example)

```bash
dart run bin/dart_code_generator.dart -s ./test_input -o ./test_output
```

## 详细文档 (Documentation)

请查看 [USAGE.md](USAGE.md) 获取详细的使用说明和示例。

For detailed usage instructions and examples, please see [USAGE.md](USAGE.md).