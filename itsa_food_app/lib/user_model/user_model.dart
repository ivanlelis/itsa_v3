class UserModel {
  String uid;
  String firstName;
  String lastName;
  String userName;
  String imageUrl;
  String email;
  String userAddress;
  String emailAddress;

  // Latitude and Longitude fields
  double latitude;
  double longitude;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.userName,
    required this.emailAddress,
    required this.imageUrl,
    required this.email,
    required this.userAddress,
    required this.latitude,
    required this.longitude,
  });

  // Factory method to create a UserModel from a Map (Firestore document)
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      userName: data['userName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      email: data['email'] ?? '',
      userAddress: data['userAddress'] ?? '',
      emailAddress: data['emailAddress'] ?? '',
      latitude:
          data['userCoordinates']?['latitude'] ?? 0.0, // Access nested latitude
      longitude: data['userCoordinates']?['longitude'] ??
          0.0, // Access nested longitude
    );
  }
}
