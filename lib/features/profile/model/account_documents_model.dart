class AccountDocumentsModel {
  const AccountDocumentsModel({
    required this.progress,
    required this.canSubmitForReview,
    required this.checklist,
    this.documentsSubmittedAt,
    this.documents = const [],
  });

  final DocumentsProgressModel progress;
  final bool canSubmitForReview;
  final String? documentsSubmittedAt;
  final List<DocumentChecklistItemModel> checklist;
  final List<AccountDocumentModel> documents;

  factory AccountDocumentsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map) {
      throw const FormatException('Invalid documents response');
    }
    final map = Map<String, dynamic>.from(data);

    final progressRaw = map['progress'];
    final checklistRaw = map['checklist'];
    final documentsRaw = map['documents'];

    return AccountDocumentsModel(
      progress: progressRaw is Map
          ? DocumentsProgressModel.fromJson(
              Map<String, dynamic>.from(progressRaw),
            )
          : const DocumentsProgressModel(
              completed: 0,
              total: 0,
              label: '0 of 0 completed',
              almostThere: false,
            ),
      canSubmitForReview: map['canSubmitForReview'] == true,
      documentsSubmittedAt: map['documentsSubmittedAt']?.toString(),
      checklist: checklistRaw is List
          ? checklistRaw
              .whereType<Map>()
              .map(
                (e) => DocumentChecklistItemModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
      documents: documentsRaw is List
          ? documentsRaw
              .whereType<Map>()
              .map(
                (e) => AccountDocumentModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
    );
  }
}

class DocumentsProgressModel {
  const DocumentsProgressModel({
    required this.completed,
    required this.total,
    required this.label,
    required this.almostThere,
  });

  final int completed;
  final int total;
  final String label;
  final bool almostThere;

  double get fraction {
    if (total <= 0) return 0;
    return (completed / total).clamp(0.0, 1.0);
  }

  factory DocumentsProgressModel.fromJson(Map<String, dynamic> json) {
    return DocumentsProgressModel(
      completed: _asInt(json['completed']),
      total: _asInt(json['total']),
      label: json['label']?.toString() ?? '',
      almostThere: json['almostThere'] == true,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class DocumentChecklistItemModel {
  const DocumentChecklistItemModel({
    required this.key,
    required this.label,
    required this.subtitle,
    required this.status,
    required this.uiStatus,
    this.items = const [],
  });

  final String key;
  final String label;
  final String subtitle;
  final String status;
  final String uiStatus;
  final List<DocumentChecklistEntryModel> items;

  factory DocumentChecklistItemModel.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    return DocumentChecklistItemModel(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      uiStatus: json['uiStatus']?.toString() ?? '',
      items: itemsRaw is List
          ? itemsRaw
              .whereType<Map>()
              .map(
                (e) => DocumentChecklistEntryModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
    );
  }
}

class DocumentChecklistEntryModel {
  const DocumentChecklistEntryModel({
    required this.type,
    required this.status,
    required this.isRequired,
    this.documentNumber,
    this.nationality,
    this.imageUrl,
    this.expiryDate,
    this.daysUntilExpiry,
  });

  final String type;
  final String status;
  final bool isRequired;
  final String? documentNumber;
  final String? nationality;
  final String? imageUrl;
  final String? expiryDate;
  final int? daysUntilExpiry;

  factory DocumentChecklistEntryModel.fromJson(Map<String, dynamic> json) {
    return DocumentChecklistEntryModel(
      type: json['type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      isRequired: json['required'] == true,
      documentNumber: json['documentNumber']?.toString(),
      nationality: json['nationality']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      expiryDate: json['expiryDate']?.toString(),
      daysUntilExpiry: json['daysUntilExpiry'] is int
          ? json['daysUntilExpiry'] as int
          : int.tryParse(json['daysUntilExpiry']?.toString() ?? ''),
    );
  }
}

class AccountDocumentModel {
  const AccountDocumentModel({
    required this.id,
    required this.driverId,
    required this.type,
    required this.status,
    this.documentNumber,
    this.nationality,
    this.imageUrl,
    this.expiryDate,
    this.reviewedAt,
    this.rejectReason,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String driverId;
  final String type;
  final String status;
  final String? documentNumber;
  final String? nationality;
  final String? imageUrl;
  final String? expiryDate;
  final String? reviewedAt;
  final String? rejectReason;
  final String? createdAt;
  final String? updatedAt;

  factory AccountDocumentModel.fromJson(Map<String, dynamic> json) {
    return AccountDocumentModel(
      id: json['id']?.toString() ?? '',
      driverId: json['driverId']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      documentNumber: json['documentNumber']?.toString(),
      nationality: json['nationality']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      expiryDate: json['expiryDate']?.toString(),
      reviewedAt: json['reviewedAt']?.toString(),
      rejectReason: json['rejectReason']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}
