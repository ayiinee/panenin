class BuyerProfileData {
  const BuyerProfileData({
    required this.ownerName,
    required this.businessName,
    required this.businessType,
    required this.phone,
    required this.email,
    required this.address,
    required this.commodities,
    required this.whatsappConnected,
    required this.completedFields,
    required this.totalFields,
    required this.imagePath,
  });

  final String ownerName;
  final String businessName;
  final String businessType;
  final String phone;
  final String email;
  final String address;
  final List<String> commodities;
  final bool whatsappConnected;
  final int completedFields;
  final int totalFields;
  final String imagePath;

  String get initials => ownerName
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((word) => word[0])
      .join()
      .toUpperCase();

  double get completion => totalFields == 0 ? 0 : completedFields / totalFields;
}

abstract final class BuyerProfileFixture {
  static const design = BuyerProfileData(
    ownerName: 'Mbak Ani',
    businessName: 'Dapur Bu Ani',
    businessType: 'Katering & makanan rumahan',
    phone: '+62 812-3456-7890',
    email: 'ani@dapurbuani.id',
    address: 'Jl. Diponegoro No. 24, Ambarawa, Jawa Tengah',
    commodities: ['Tomat', 'Cabai', 'Bawang Merah'],
    whatsappConnected: true,
    completedFields: 4,
    totalFields: 5,
    imagePath: 'assets/images/aini.jpeg',
  );
}
