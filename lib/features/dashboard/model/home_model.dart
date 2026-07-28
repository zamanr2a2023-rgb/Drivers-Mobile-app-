class DriverHomeModel {
  const DriverHomeModel({
    required this.driver,
    required this.wallet,
    required this.today,
    required this.scheduledOrdersCount,
    required this.unreadNotificationsCount,
    this.activeDelivery,
    this.waitingForRequests = false,
  });

  final HomeDriverModel driver;
  final HomeWalletModel wallet;
  final HomeTodayModel today;
  final int scheduledOrdersCount;
  final int unreadNotificationsCount;
  final dynamic activeDelivery;
  final bool waitingForRequests;

  factory DriverHomeModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map) {
      throw const FormatException('Invalid home response');
    }
    final map = Map<String, dynamic>.from(data);

    final driverRaw = map['driver'];
    final walletRaw = map['wallet'];
    final todayRaw = map['today'];
    if (driverRaw is! Map || walletRaw is! Map || todayRaw is! Map) {
      throw const FormatException('Invalid home response');
    }

    return DriverHomeModel(
      driver: HomeDriverModel.fromJson(Map<String, dynamic>.from(driverRaw)),
      wallet: HomeWalletModel.fromJson(Map<String, dynamic>.from(walletRaw)),
      today: HomeTodayModel.fromJson(Map<String, dynamic>.from(todayRaw)),
      scheduledOrdersCount: _asInt(map['scheduledOrdersCount']),
      unreadNotificationsCount: _asInt(map['unreadNotificationsCount']),
      activeDelivery: map['activeDelivery'],
      waitingForRequests: map['waitingForRequests'] == true,
    );
  }

  DriverHomeModel copyWith({
    HomeDriverModel? driver,
    HomeWalletModel? wallet,
    HomeTodayModel? today,
    int? scheduledOrdersCount,
    int? unreadNotificationsCount,
    dynamic activeDelivery,
    bool? waitingForRequests,
  }) {
    return DriverHomeModel(
      driver: driver ?? this.driver,
      wallet: wallet ?? this.wallet,
      today: today ?? this.today,
      scheduledOrdersCount: scheduledOrdersCount ?? this.scheduledOrdersCount,
      unreadNotificationsCount:
          unreadNotificationsCount ?? this.unreadNotificationsCount,
      activeDelivery: activeDelivery ?? this.activeDelivery,
      waitingForRequests: waitingForRequests ?? this.waitingForRequests,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class HomeDriverModel {
  const HomeDriverModel({
    required this.id,
    required this.champId,
    required this.firstName,
    required this.lastName,
    required this.status,
    required this.accountStatus,
    required this.isAutoAcceptEnabled,
    this.avatarUrl,
    this.averageRating = 0,
    this.rpiScore = 0,
  });

  final String id;
  final String champId;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String status;
  final String accountStatus;
  final bool isAutoAcceptEnabled;
  final double averageRating;
  final double rpiScore;

  String get displayName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? 'Driver' : name;
  }

  bool get isOnlineStatus {
    switch (status.toUpperCase()) {
      case 'ONLINE':
      case 'BUSY':
      case 'AVAILABLE':
      case 'WAITING':
        return true;
      default:
        return false;
    }
  }

  factory HomeDriverModel.fromJson(Map<String, dynamic> json) {
    return HomeDriverModel(
      id: json['id']?.toString() ?? '',
      champId: json['champId']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      status: json['status']?.toString() ?? 'OFFLINE',
      accountStatus: json['accountStatus']?.toString() ?? '',
      isAutoAcceptEnabled: json['isAutoAcceptEnabled'] == true,
      averageRating: _asDouble(json['averageRating']),
      rpiScore: _asDouble(json['rpiScore']),
    );
  }

  HomeDriverModel copyWith({
    String? status,
    bool? isAutoAcceptEnabled,
  }) {
    return HomeDriverModel(
      id: id,
      champId: champId,
      firstName: firstName,
      lastName: lastName,
      avatarUrl: avatarUrl,
      status: status ?? this.status,
      accountStatus: accountStatus,
      isAutoAcceptEnabled: isAutoAcceptEnabled ?? this.isAutoAcceptEnabled,
      averageRating: averageRating,
      rpiScore: rpiScore,
    );
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class HomeWalletModel {
  const HomeWalletModel({
    required this.balance,
    required this.pendingCashCollected,
  });

  final double balance;
  final double pendingCashCollected;

  factory HomeWalletModel.fromJson(Map<String, dynamic> json) {
    return HomeWalletModel(
      balance: _asDouble(json['balance']),
      pendingCashCollected: _asDouble(json['pendingCashCollected']),
    );
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class HomeTodayModel {
  const HomeTodayModel({
    required this.ordersCount,
    required this.totalEarnings,
    required this.onlineDurationSec,
    required this.onlineDurationLabel,
  });

  final int ordersCount;
  final double totalEarnings;
  final int onlineDurationSec;
  final String onlineDurationLabel;

  factory HomeTodayModel.fromJson(Map<String, dynamic> json) {
    return HomeTodayModel(
      ordersCount: json['ordersCount'] is int
          ? json['ordersCount'] as int
          : int.tryParse(json['ordersCount']?.toString() ?? '') ?? 0,
      totalEarnings: json['totalEarnings'] is num
          ? (json['totalEarnings'] as num).toDouble()
          : double.tryParse(json['totalEarnings']?.toString() ?? '') ?? 0,
      onlineDurationSec: json['onlineDurationSec'] is int
          ? json['onlineDurationSec'] as int
          : int.tryParse(json['onlineDurationSec']?.toString() ?? '') ?? 0,
      onlineDurationLabel: json['onlineDurationLabel']?.toString() ?? '0m',
    );
  }
}
