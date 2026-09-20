class ProfileModel {
  const ProfileModel({
    required this.name,
    required this.phone,
    this.email,
    this.vehicleType,
    this.plateNumber,
    this.licenseNumber,
    this.licenseStatus = '',
    this.rating = 0,
  });

  final String name;
  final String phone;
  final String? email;
  final String? vehicleType;
  final String? plateNumber;
  final String? licenseNumber;
  final String licenseStatus;
  final double rating;

  ProfileModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? vehicleType,
    String? plateNumber,
  }) {
    return ProfileModel(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      vehicleType: vehicleType ?? this.vehicleType,
      plateNumber: plateNumber ?? this.plateNumber,
      licenseNumber: licenseNumber,
      licenseStatus: licenseStatus,
      rating: rating,
    );
  }
}
