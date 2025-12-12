/// Enum example - model with only value field and static fields
class GwResUserStatus {
  const GwResUserStatus({required this.value});
  final String value;

  static const active = GwResUserStatus(value: 'ACTIVE');
  static const inactive = GwResUserStatus(value: 'INACTIVE');
  static const suspended = GwResUserStatus(value: 'SUSPENDED');
}
