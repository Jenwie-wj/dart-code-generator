/// Example API class
class UserApi {
  Future<GwResUserInfo> getUserInfo(String token, GwReqGetUser body) async {
    // Mock API call
    return GwResUserInfo(name: 'John', age: 30);
  }

  Future<GwResUserWithStatus> getUserWithStatus(String userId) async {
    // Mock API call
    return GwResUserWithStatus(name: 'John', status: GwResUserStatus.active);
  }

  Future<GwResLoginResult> login(GwReqLogin body) async {
    // Mock API call
    return GwResLoginResult(token: 'abc123', userId: 1);
  }

  Future<NoneObject> deleteUser(String userId) async {
    // Mock API call
    return NoneObject();
  }
}
