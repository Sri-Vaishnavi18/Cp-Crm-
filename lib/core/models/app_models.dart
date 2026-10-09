class UserModel {
  final String id;
  final String name;
  final String firmName;
  final String reraNumber;
  final String phone;
  final String email;
  final String city;
  final bool isAgency;
  final String? password;
  final String? logoUrl;
  final DateTime? registeredAt;

  UserModel({
    required this.id,
    required this.name,
    required this.firmName,
    required this.reraNumber,
    required this.phone,
    required this.email,
    required this.city,
    required this.isAgency,
    this.password,
    this.logoUrl,
    this.registeredAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'firmName': firmName,
    'reraNumber': reraNumber,
    'phone': phone,
    'email': email,
    'city': city,
    'isAgency': isAgency,
    'password': password,
    'logoUrl': logoUrl,
    'registeredAt': registeredAt?.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    firmName: json['firmName']?.toString() ?? '',
    reraNumber: json['reraNumber']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    city: json['city']?.toString() ?? '',
    isAgency: json['isAgency'] == true,
    password: json['password']?.toString(),
    logoUrl: json['logoUrl']?.toString(),
    registeredAt: json['registeredAt'] != null ? DateTime.tryParse(json['registeredAt'].toString()) : null,
  );
}

enum LeadTemperature {
  hot,
  warm,
  cold,
}

extension LeadTemperatureExtension on LeadTemperature {
  String get displayName {
    switch (this) {
      case LeadTemperature.hot:
        return 'Hot';
      case LeadTemperature.warm:
        return 'Warm';
      case LeadTemperature.cold:
        return 'Cold';
    }
  }

  String get labelWithEmoji {
    switch (this) {
      case LeadTemperature.hot:
        return '🔥 Hot Lead';
      case LeadTemperature.warm:
        return '☀️ Warm Lead';
      case LeadTemperature.cold:
        return '❄️ Cold Lead';
    }
  }

  String get shortLabelWithEmoji {
    switch (this) {
      case LeadTemperature.hot:
        return '🔥 Hot';
      case LeadTemperature.warm:
        return '☀️ Warm';
      case LeadTemperature.cold:
        return '❄️ Cold';
    }
  }
}

enum LeadSource {
  walkIn,
  digitalAds,
  referral,
  socialMedia,
  channelPartner,
  coldCalling,
  website,
  exhibition,
}

extension LeadSourceExtension on LeadSource {
  String get displayName {
    switch (this) {
      case LeadSource.walkIn:
        return 'Walk-in';
      case LeadSource.digitalAds:
        return 'Digital Ads';
      case LeadSource.referral:
        return 'Referral';
      case LeadSource.socialMedia:
        return 'Social Media';
      case LeadSource.channelPartner:
        return 'Channel Partner';
      case LeadSource.coldCalling:
        return 'Cold Calling';
      case LeadSource.website:
        return 'Website Inquiry';
      case LeadSource.exhibition:
        return 'Property Expo';
    }
  }
}

class LeadNoteItem {
  final String id;
  final String text;
  final String author;
  final DateTime createdAt;

  LeadNoteItem({
    required this.id,
    required this.text,
    required this.author,
    required this.createdAt,
  });
}

class LeadActivityItem {
  final String id;
  final String title;
  final DateTime timestamp;
  final String? subtitle;

  LeadActivityItem({
    required this.id,
    required this.title,
    required this.timestamp,
    this.subtitle,
  });
}

enum LeadStage {
  newLead,
  contacted,
  visitScheduled,
  visitCompleted,
  negotiation,
  tokenPaid,
  lost,
}

extension LeadStageExtension on LeadStage {
  String get displayName {
    switch (this) {
      case LeadStage.newLead:
        return 'NEW';
      case LeadStage.contacted:
        return 'CONTACTED';
      case LeadStage.visitScheduled:
        return 'VISIT SCHEDULED';
      case LeadStage.visitCompleted:
        return 'VISIT COMPLETED';
      case LeadStage.negotiation:
        return 'NEGOTIATION';
      case LeadStage.tokenPaid:
        return 'BOOKED';
      case LeadStage.lost:
        return 'LOST';
    }
  }

  String get readableTitle {
    switch (this) {
      case LeadStage.newLead:
        return 'Lead Created';
      case LeadStage.contacted:
        return 'Contacted';
      case LeadStage.visitScheduled:
        return 'Site Visit Scheduled';
      case LeadStage.visitCompleted:
        return 'Site Visit Completed';
      case LeadStage.negotiation:
        return 'Negotiation';
      case LeadStage.tokenPaid:
        return 'Booked';
      case LeadStage.lost:
        return 'Lost';
    }
  }
}

class LeadModel {
  final String id;
  String firstName;
  String lastName;
  String phone;
  String? altPhone;
  String? email;
  String budget;
  List<String> configurations;
  String projectId;
  String projectName;
  String timeline;
  String notes;
  LeadStage stage;
  LeadTemperature temperature;
  String source;
  final DateTime createdAt;
  final bool isQueuedOffline;
  List<LeadNoteItem> notesList;
  List<String> siteVisitHistory;
  List<LeadActivityItem> activityList;

  LeadModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.altPhone,
    this.email,
    required this.budget,
    required this.configurations,
    required this.projectId,
    required this.projectName,
    required this.timeline,
    required this.notes,
    required this.stage,
    this.temperature = LeadTemperature.cold,
    this.source = 'CHANNEL_PARTNER',
    required this.createdAt,
    this.isQueuedOffline = false,
    List<LeadNoteItem>? notesList,
    List<String>? siteVisitHistory,
    List<LeadActivityItem>? activityList,
  })  : notesList = notesList ?? [],
        siteVisitHistory = siteVisitHistory ?? [],
        activityList = activityList ?? [];

  String get fullName => '$firstName $lastName'.trim();

  static LeadTemperature getTemperatureForStage(LeadStage stage) {
    switch (stage) {
      case LeadStage.newLead:
      case LeadStage.contacted:
      case LeadStage.lost:
        return LeadTemperature.cold;
      case LeadStage.visitScheduled:
      case LeadStage.visitCompleted:
      case LeadStage.negotiation:
        return LeadTemperature.warm;
      case LeadStage.tokenPaid:
        return LeadTemperature.hot;
    }
  }

  int get pipelineStepIndex {
    switch (stage) {
      case LeadStage.newLead:
        return 0;
      case LeadStage.contacted:
        return 1;
      case LeadStage.visitScheduled:
      case LeadStage.visitCompleted:
        return 2;
      case LeadStage.negotiation:
        return 3;
      case LeadStage.tokenPaid:
        return 4;
      case LeadStage.lost:
        return 1;
    }
  }
}

enum UnitStatus {
  available,
  blocked,
  sold,
}

class UnitModel {
  final String unitNo;
  final String tower;
  final int floor;
  final String bhk;
  final double carpetArea;
  final double superArea;
  final String facing;
  final double basePrice;
  UnitStatus status;
  String? holdExpiresAt;

  UnitModel({
    required this.unitNo,
    required this.tower,
    required this.floor,
    required this.bhk,
    required this.carpetArea,
    required this.superArea,
    required this.facing,
    required this.basePrice,
    required this.status,
    this.holdExpiresAt,
  });
}

class ProjectModel {
  final String id;
  final String name;
  final String location;
  final String startingPrice;
  final String reraNumber;
  final String possessionDate;
  final String type; // 'Ongoing', 'Ready to Move', 'Pre-Launch'
  final String heroImageUrl;
  final List<String> galleryImages;
  final List<String> amenities;
  final List<String> approvedBanks;
  final String distanceDetails;
  final List<String> towers;
  final List<UnitModel> units;

  ProjectModel({
    required this.id,
    required this.name,
    required this.location,
    required this.startingPrice,
    required this.reraNumber,
    required this.possessionDate,
    required this.type,
    required this.heroImageUrl,
    required this.galleryImages,
    required this.amenities,
    required this.approvedBanks,
    required this.distanceDetails,
    required this.towers,
    required this.units,
  });
}

class SiteVisitModel {
  final String id;
  final String visitCode;
  final String leadId;
  final String clientName;
  final String clientPhone;
  final String projectId;
  final String projectName;
  final DateTime scheduledAt;
  final bool cabRequired;
  final bool accompanying;
  String status; // 'SCHEDULED', 'CHECKED_IN', 'COMPLETED', 'CANCELLED'
  final String? salesRepName;
  final String? feedback;

  SiteVisitModel({
    required this.id,
    required this.visitCode,
    required this.leadId,
    required this.clientName,
    required this.clientPhone,
    required this.projectId,
    required this.projectName,
    required this.scheduledAt,
    required this.cabRequired,
    required this.accompanying,
    required this.status,
    this.salesRepName,
    this.feedback,
  });
}

class SpocModel {
  final String id;
  final String name;
  final String role;
  final String projectName;
  final String phone;
  final String email;
  final String avatarUrl;

  SpocModel({
    required this.id,
    required this.name,
    required this.role,
    required this.projectName,
    required this.phone,
    required this.email,
    required this.avatarUrl,
  });
}

class CollateralModel {
  final String id;
  final String title;
  final String category; // 'Brochure', 'Floor Plan', 'Price Sheet', 'Video', 'Approval'
  final String projectId;
  final String projectName;
  final String fileSize;
  final String fileUrl;
  final bool isDownloaded;

  CollateralModel({
    required this.id,
    required this.title,
    required this.category,
    required this.projectId,
    required this.projectName,
    required this.fileSize,
    required this.fileUrl,
    this.isDownloaded = false,
  });
}

class AppNotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'lead', 'visit', 'broadcast'
  final DateTime timestamp;
  bool isRead;
  final String? targetRoute;
  final String? targetId;

  AppNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.targetRoute,
    this.targetId,
  });
}

enum InvoiceType {
  siteVisit,
  booking,
}

extension InvoiceTypeExtension on InvoiceType {
  String get displayName {
    switch (this) {
      case InvoiceType.siteVisit:
        return 'Site Visit Invoice';
      case InvoiceType.booking:
        return 'Booking Commission Invoice';
    }
  }

  String get shortLabel {
    switch (this) {
      case InvoiceType.siteVisit:
        return 'Site Visit Payout';
      case InvoiceType.booking:
        return 'Booking Brokerage';
    }
  }
}

enum InvoiceStatus {
  pending,
  approved,
  paid,
  rejected,
}

extension InvoiceStatusExtension on InvoiceStatus {
  String get displayName {
    switch (this) {
      case InvoiceStatus.pending:
        return 'Pending Approval';
      case InvoiceStatus.approved:
        return 'Approved';
      case InvoiceStatus.paid:
        return 'Paid / Disbursed';
      case InvoiceStatus.rejected:
        return 'Rejected';
    }
  }
}

class BankDetailsModel {
  final String accountHolder;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String? upiId;

  BankDetailsModel({
    required this.accountHolder,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    this.upiId,
  });

  Map<String, dynamic> toJson() => {
    'accountHolder': accountHolder,
    'bankName': bankName,
    'accountNumber': accountNumber,
    'ifscCode': ifscCode,
    'upiId': upiId,
  };

  factory BankDetailsModel.fromJson(Map<String, dynamic> json) => BankDetailsModel(
    accountHolder: json['accountHolder']?.toString() ?? '',
    bankName: json['bankName']?.toString() ?? '',
    accountNumber: json['accountNumber']?.toString() ?? '',
    ifscCode: json['ifscCode']?.toString() ?? '',
    upiId: json['upiId']?.toString(),
  );
}

class CommissionInvoiceModel {
  final String id;
  final String invoiceNumber;
  final String leadId;
  final String clientName;
  final String clientPhone;
  final String projectId;
  final String projectName;
  final InvoiceType type;
  final double amount;
  final DateTime date;
  InvoiceStatus status;
  final BankDetailsModel bankDetails;
  final String? notes;

  CommissionInvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.leadId,
    required this.clientName,
    required this.clientPhone,
    required this.projectId,
    required this.projectName,
    required this.type,
    required this.amount,
    required this.date,
    this.status = InvoiceStatus.pending,
    required this.bankDetails,
    this.notes,
  });
}
