/// Response model for user info
class GwResUserInfo {
  const GwResUserInfo({required this.name, required this.age});
  
  /// User's name
  final String name;
  
  /// User's age
  final int age;
}

/// Request model for getting user
class GwReqGetUser {
  const GwReqGetUser({required this.userId});
  
  /// User ID to fetch
  final String userId;
}

/// Response model for login result
class GwResLoginResult {
  const GwResLoginResult({required this.token, required this.userId});
  
  /// Authentication token
  final String token;
  
  /// User ID
  final int userId;
}

/// Request model for login
class GwReqLogin {
  const GwReqLogin({required this.username, required this.password});
  
  /// Username for login
  final String username;
  
  /// Password for login
  final String password;
}

/// Special placeholder for no object
class NoneObject {
  const NoneObject();
}
