/// User address information
class GwResAddress {
  const GwResAddress({required this.street, required this.city});
  
  /// Street address
  final String street;
  
  /// City name
  final String city;
}

/// User profile with nested address
class GwResUserProfile {
  const GwResUserProfile({required this.name, required this.address});
  
  /// User's full name
  final String name;
  
  /// User's address information
  final GwResAddress address;
}

/// Company information
class GwResCompany {
  const GwResCompany({required this.name, required this.employees});
  
  /// Company name
  final String name;
  
  /// Number of employees
  final int employees;
}

/// Full user details with multiple nested objects
class GwResFullUser {
  const GwResFullUser({required this.profile, required this.company});
  
  /// User profile information
  final GwResUserProfile profile;
  
  /// Company information
  final GwResCompany company;
}
