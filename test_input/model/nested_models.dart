/// User address information
class GwResAddress {
  const GwResAddress({required this.street, required this.city});
  final String street;
  final String city;
}

/// User profile with nested address
class GwResUserProfile {
  const GwResUserProfile({required this.name, required this.address});
  final String name;
  final GwResAddress address;
}

/// Company information
class GwResCompany {
  const GwResCompany({required this.name, required this.employees});
  final String name;
  final int employees;
}

/// Full user details with multiple nested objects
class GwResFullUser {
  const GwResFullUser({required this.profile, required this.company});
  final GwResUserProfile profile;
  final GwResCompany company;
}
