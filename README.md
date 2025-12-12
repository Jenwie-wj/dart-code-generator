帮我用 dart 实现一个dart包，功能是把现成的 dart 文件的方法转换成调用该方法的文件，我会给一个源文件夹路径，里面有api 文件夹和model 文件夹，api 文件夹里有多个以'_api.dart'为后缀的类文件，每个类文件有一个类定义，你需要把类里的所有方法收集起来生成一个新文件，新文件名为源文件名+'_helper'后缀，例如源文件名为'xx_api.dart'，则新文件名为'xx_api_helper.dart'。新文件由一个抽象类组成，抽象类名根据文件名为驼峰式命名，如'xx_api_helper.dart'则抽象类名为'XxApiHelper'，抽象类里的方法均为静态方法，方法名与源文件的一致，返回值需要根据源文件中的返回值的类名新建一个类，源文件的返回值类均在 model 文件夹中，你需要自己去寻找，新建的返回值类的类名参考源文件的返回值类名，例如源文件为'GwResXxx'，则新文件为'ResXxx'，返回值有特例情况：如果源文件返回值是'Future<NoneObject>'则新文件的返回值改为'Future<void>'；新文件的方法参数与源文件一致，请求体的类也需要新建一个类，可在 model 文件中查找类定义，新的请求体类名参考源文件的请求体类名，例如源文件为'GwReqXxx'，则新文件为'ReqXxx'，请求体有特例情况：如果请求体类型为'NoneObject'，则该方法忽略这个参数；新方法的方法体为调用源文件的同名方法，并返回新的返回值类对象，调用源文件同名方法时，源方法的参数由新方法的参数转换而成，新方法的返回值由源方法的返回值转换而成。最小 demo 如下：

```dart
/// 源文件的某个方法的返回值
class GwResXxx {
  const GwResXxx({required this.a});
  final int a;
}

/// 源文件的某个方法的请求体参数
class GwReqXxx {
  const GwReqXxx({required this.a});
  final int a;
}

/// 调用方的某个方法的返回值
class ResXxx {
  const ResXxx({required this.a});
  final int a;
}

/// 调用方的某个方法的请求体参数
class ReqXxx {
  const ReqXxx({required this.a});
  final int a;
}

/// 源文件的某个方法
class XxxApi {
  Future<GwResXxx> func(String token, GwReqXxx body) async {
    // 实际调用 api 的代码省略
    // ...
    return GwResXxx(a: 1);
  }
}

/// 调用方的某个方法的帮助类
abstract class XxxApiHelper {
  static Future<ResXxx> func(String token, ReqXxx body) async {
    final GwResXxx res = await XxxApi().func(token, GwReqXxx(a: body.a));
    return ResXxx(a: res.a);
  }
}
```

注意：源 model 可能存在只有一个字段为 value 的情况，此时需要把该 model 的所有静态字段变成 enum 枚举类型，枚举值为静态字段的名称

要求把新的'xxx_api_helper.dart'文件统一输出为一个名为'api'的文件夹中，'res_xxx.dart'和'req_xxx.dart'的文件统一输出为另一个名为'models'的文件夹中。

脚本输入：源文件夹目录路径、新文件夹目录路径
脚本输出：一个包含'api'文件夹和'models'文件夹的文件夹