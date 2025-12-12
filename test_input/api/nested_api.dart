/// API for nested data
class NestedApi {
  Future<GwResFullUser> getFullUser(String userId) async {
    // Mock API call
    return GwResFullUser(
      profile: GwResUserProfile(
        name: 'John',
        address: GwResAddress(street: '123 Main St', city: 'NYC'),
      ),
      company: GwResCompany(name: 'Acme Inc', employees: 100),
    );
  }
}
