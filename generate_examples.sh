#!/bin/bash
# Script to demonstrate the code generator output
# This creates manual example output to show what the generator produces

mkdir -p example_output/api
mkdir -p example_output/models

# Example: Generated helper file (user_api_helper.dart)
cat > example_output/api/user_api_helper.dart << 'EOF'
// Generated helper file for user_api.dart
// This file is auto-generated. Do not edit manually.

// NOTE: Update this import path to point to your original API file:
// import 'package:your_package/api/user_api.dart';

import '../models/res_user_info.dart';
import '../models/req_get_user.dart';
import '../models/res_login_result.dart';
import '../models/req_login.dart';

// NOTE: Update these import paths to point to your original model files:
// import 'package:your_package/model/gw_res_user_info.dart';
// import 'package:your_package/model/gw_req_get_user.dart';
// import 'package:your_package/model/gw_res_login_result.dart';
// import 'package:your_package/model/gw_req_login.dart';

abstract class UserApiHelper {
  static Future<ResUserInfo> getUserInfo(String token, ReqGetUser body) async {
    final GwResUserInfo res = await UserApi().getUserInfo(token, GwReqGetUser(userId: body.userId));
    return ResUserInfo(name: res.name, age: res.age);
  }

  static Future<ResLoginResult> login(ReqLogin body) async {
    final GwResLoginResult res = await UserApi().login(GwReqLogin(username: body.username, password: body.password));
    return ResLoginResult(token: res.token, userId: res.userId);
  }

  static Future<void> deleteUser(String userId) async {
    await UserApi().deleteUser(userId);
  }

}
EOF

# Example: Generated response model (res_user_info.dart)
cat > example_output/models/res_user_info.dart << 'EOF'
// Generated model class ResUserInfo
class ResUserInfo {
  const ResUserInfo({required this.name, required this.age});

  final String name;
  final int age;
}
EOF

# Example: Generated request model (req_get_user.dart)
cat > example_output/models/req_get_user.dart << 'EOF'
// Generated model class ReqGetUser
class ReqGetUser {
  const ReqGetUser({required this.userId});

  final String userId;
}
EOF

# Example: Generated response model (res_login_result.dart)
cat > example_output/models/res_login_result.dart << 'EOF'
// Generated model class ResLoginResult
class ResLoginResult {
  const ResLoginResult({required this.token, required this.userId});

  final String token;
  final int userId;
}
EOF

# Example: Generated request model (req_login.dart)
cat > example_output/models/req_login.dart << 'EOF'
// Generated model class ReqLogin
class ReqLogin {
  const ReqLogin({required this.username, required this.password});

  final String username;
  final String password;
}
EOF

# Example: Generated enum (res_user_status.dart)
cat > example_output/models/res_user_status.dart << 'EOF'
// Generated enum ResUserStatus
enum ResUserStatus {
  active,
  inactive,
  suspended
}
EOF

echo "Example output generated in example_output/"
echo ""
echo "Files created:"
ls -R example_output/
