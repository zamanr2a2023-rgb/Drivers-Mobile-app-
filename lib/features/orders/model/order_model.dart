class OrderModel {
  const OrderModel({
    required this.id,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.customerName,
    required this.vendorName,
    required this.status,
    required this.price,
    required this.distance,
    required this.createdAt,
    this.isRestricted = false,
    this.items = const [],
    this.paymentStatus = 'Pending',
    this.deliveryNotes,
    this.tipAmount = 0,
  });

  final String id;
  final String pickupAddress;
  final String dropoffAddress;
  final String customerName;
  final String vendorName;
  final String status;
  final double price;
  final double distance;
  final DateTime createdAt;
  final bool isRestricted;
  final List<String> items;
  final String paymentStatus;
  final String? deliveryNotes;
  final double tipAmount;

  OrderModel copyWith({String? status}) {
    return OrderModel(
      id: id,
      pickupAddress: pickupAddress,
      dropoffAddress: dropoffAddress,
      customerName: customerName,
      vendorName: vendorName,
      status: status ?? this.status,
      price: price,
      distance: distance,
      createdAt: createdAt,
      isRestricted: isRestricted,
      items: items,
      paymentStatus: paymentStatus,
      deliveryNotes: deliveryNotes,
      tipAmount: tipAmount,
    );
  }
}
