/// Response model for user info
class GwResUserInfo {
  const GwResUserInfo({required this.name, required this.age});
  final String name;
  final int age;
}

/// Request model for getting user
class GwReqGetUser {
  const GwReqGetUser({required this.userId});
  final String userId;
}

/// Response model for login result
class GwResLoginResult {
  const GwResLoginResult({required this.token, required this.userId});
  final String token;
  final int userId;
}

/// Request model for login
class GwReqLogin {
  const GwReqLogin({required this.username, required this.password});
  final String username;
  final String password;
}

/// Special placeholder for no object
class NoneObject {
  const NoneObject();
}
