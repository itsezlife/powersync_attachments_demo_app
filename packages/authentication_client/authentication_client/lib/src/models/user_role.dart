/// {@template user_role}
/// The role of a user in the system.
/// {@endtemplate}
enum UserRole {
  /// A user who can book and manage bookings.
  agent,

  /// A user who is a buyer and can book properties.
  buyer;

  /// Whether the user is an agent.
  bool get isAgent => this == agent;

  /// Whether the user is a buyer.
  bool get isBuyer => this == buyer;

  /// Switches the user role.
  UserRole get switchRole {
    return isAgent ? buyer : agent;
  }
}
