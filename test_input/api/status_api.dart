/// API for status management
class StatusApi {
  Future<GwResUserStatus> getUserStatus(String userId) async {
    // Mock API call
    return GwResUserStatus.active;
  }
}
