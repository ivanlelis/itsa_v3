class UserModel {
  String uid;
  String firstName;
  String lastName;
  String userName;
  String imageUrl;
  String email; // Assuming this is the user's email.

  // Change emailAddress from final to a regular field
  String emailAddress;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.userName,
    required this.emailAddress, // Pass this as a parameter
    required this.imageUrl,
    required this.email,
  });
}
