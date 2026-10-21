import 'dart:convert';

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'author': author,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LeadNoteItem.fromJson(Map<String, dynamic> json) => LeadNoteItem(
        id: json['id'] as String? ?? '',
        text: json['text'] as String? ?? '',
        author: json['author'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'timestamp': timestamp.toIso8601String(),
        'subtitle': subtitle,
      };

  factory LeadActivityItem.fromJson(Map<String, dynamic> json) => LeadActivityItem(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
        subtitle: json['subtitle'] as String?,
      );
}

enum LeadStage {
  cold,
  siteVisited,
  booked,
}

extension LeadStageExtension on LeadStage {
  String get displayName {
    switch (this) {
      case LeadStage.cold:
        return 'COLD';
      case LeadStage.siteVisited:
        return 'SITE VISITED';
      case LeadStage.booked:
        return 'BOOKED';
    }
  }

  String get readableTitle {
    switch (this) {
      case LeadStage.cold:
        return 'Cold';
      case LeadStage.siteVisited:
        return 'Site Visited';
      case LeadStage.booked:
        return 'Booked';
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'altPhone': altPhone,
        'email': email,
        'budget': budget,
        'configurations': configurations,
        'projectId': projectId,
        'projectName': projectName,
        'timeline': timeline,
        'notes': notes,
        'stage': stage.name,
        'temperature': temperature.name,
        'source': source,
        'createdAt': createdAt.toIso8601String(),
        'isQueuedOffline': isQueuedOffline,
        'notesList': notesList.map((n) => n.toJson()).toList(),
        'siteVisitHistory': siteVisitHistory,
        'activityList': activityList.map((a) => a.toJson()).toList(),
      };

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      id: json['id'] as String? ?? 'lead_${DateTime.now().millisecondsSinceEpoch}',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      altPhone: json['altPhone'] as String?,
      email: json['email'] as String?,
      budget: json['budget'] as String? ?? '',
      configurations: (json['configurations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      projectId: json['projectId'] as String? ?? '',
      projectName: json['projectName'] as String? ?? '',
      timeline: json['timeline'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      stage: LeadStage.values.firstWhere(
        (s) => s.name == json['stage'],
        orElse: () => LeadStage.cold,
      ),
      temperature: LeadTemperature.values.firstWhere(
        (t) => t.name == json['temperature'],
        orElse: () => LeadTemperature.cold,
      ),
      source: json['source'] as String? ?? 'CHANNEL_PARTNER',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isQueuedOffline: json['isQueuedOffline'] as bool? ?? false,
      notesList: (json['notesList'] as List<dynamic>?)
              ?.map((e) => LeadNoteItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      siteVisitHistory: (json['siteVisitHistory'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      activityList: (json['activityList'] as List<dynamic>?)
              ?.map((e) => LeadActivityItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  LeadModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phone,
    String? altPhone,
    String? email,
    String? budget,
    List<String>? configurations,
    String? projectId,
    String? projectName,
    String? timeline,
    String? notes,
    LeadStage? stage,
    LeadTemperature? temperature,
    String? source,
    DateTime? createdAt,
    bool? isQueuedOffline,
    List<LeadNoteItem>? notesList,
    List<String>? siteVisitHistory,
    List<LeadActivityItem>? activityList,
  }) {
    return LeadModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      altPhone: altPhone ?? this.altPhone,
      email: email ?? this.email,
      budget: budget ?? this.budget,
      configurations: configurations ?? this.configurations,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      timeline: timeline ?? this.timeline,
      notes: notes ?? this.notes,
      stage: stage ?? this.stage,
      temperature: temperature ?? this.temperature,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      isQueuedOffline: isQueuedOffline ?? this.isQueuedOffline,
      notesList: notesList ?? this.notesList,
      siteVisitHistory: siteVisitHistory ?? this.siteVisitHistory,
      activityList: activityList ?? this.activityList,
    );
  }

  static LeadTemperature getTemperatureForStage(LeadStage stage) {
    switch (stage) {
      case LeadStage.cold:
        return LeadTemperature.cold;
      case LeadStage.siteVisited:
        return LeadTemperature.warm;
      case LeadStage.booked:
        return LeadTemperature.hot;
    }
  }

  int get pipelineStepIndex {
    switch (stage) {
      case LeadStage.cold:
        return 0;
      case LeadStage.siteVisited:
        return 1;
      case LeadStage.booked:
        return 2;
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

  Map<String, dynamic> toJson() => {
    'unitNo': unitNo,
    'tower': tower,
    'floor': floor,
    'bhk': bhk,
    'carpetArea': carpetArea,
    'superArea': superArea,
    'facing': facing,
    'basePrice': basePrice,
    'status': status.name,
    'holdExpiresAt': holdExpiresAt,
  };

  factory UnitModel.fromJson(Map<String, dynamic> json) => UnitModel(
    unitNo: json['unitNo'] as String? ?? '',
    tower: json['tower'] as String? ?? '',
    floor: (json['floor'] as num?)?.toInt() ?? 1,
    bhk: json['bhk'] as String? ?? '2 BHK',
    carpetArea: (json['carpetArea'] as num?)?.toDouble() ?? 800.0,
    superArea: (json['superArea'] as num?)?.toDouble() ?? 1100.0,
    facing: json['facing'] as String? ?? 'East',
    basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
    status: UnitStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => UnitStatus.available,
    ),
    holdExpiresAt: json['holdExpiresAt'] as String?,
  );
}

class ProjectModel {
  final String id;
  final String name;
  final String location;
  String startingPrice;
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
  String? brochureFileName;
  String? brochureFileSize;
  DateTime? brochureUpdatedAt;

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
    this.brochureFileName,
    this.brochureFileSize,
    this.brochureUpdatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'location': location,
    'startingPrice': startingPrice,
    'reraNumber': reraNumber,
    'possessionDate': possessionDate,
    'type': type,
    'heroImageUrl': heroImageUrl,
    'galleryImages': galleryImages,
    'amenities': amenities,
    'approvedBanks': approvedBanks,
    'distanceDetails': distanceDetails,
    'towers': towers,
    'units': units.map((u) => u.toJson()).toList(),
    'brochureFileName': brochureFileName,
    'brochureFileSize': brochureFileSize,
    'brochureUpdatedAt': brochureUpdatedAt?.toIso8601String(),
  };

  factory ProjectModel.fromJson(Map<String, dynamic> json) => ProjectModel(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    location: json['location'] as String? ?? '',
    startingPrice: json['startingPrice'] as String? ?? '',
    reraNumber: json['reraNumber'] as String? ?? '',
    possessionDate: json['possessionDate'] as String? ?? '',
    type: json['type'] as String? ?? 'Ongoing',
    heroImageUrl: json['heroImageUrl'] as String? ?? '',
    galleryImages: (json['galleryImages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    amenities: (json['amenities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    approvedBanks: (json['approvedBanks'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    distanceDetails: json['distanceDetails'] as String? ?? '',
    towers: (json['towers'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    units: (json['units'] as List<dynamic>?)?.map((e) => UnitModel.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    brochureFileName: json['brochureFileName'] as String?,
    brochureFileSize: json['brochureFileSize'] as String?,
    brochureUpdatedAt: json['brochureUpdatedAt'] != null
        ? DateTime.tryParse(json['brochureUpdatedAt'].toString())
        : null,
  );
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'visitCode': visitCode,
    'leadId': leadId,
    'clientName': clientName,
    'clientPhone': clientPhone,
    'projectId': projectId,
    'projectName': projectName,
    'scheduledAt': scheduledAt.toIso8601String(),
    'cabRequired': cabRequired,
    'accompanying': accompanying,
    'status': status,
    'salesRepName': salesRepName,
    'feedback': feedback,
  };

  factory SiteVisitModel.fromJson(Map<String, dynamic> json) => SiteVisitModel(
    id: json['id']?.toString() ?? '',
    visitCode: json['visitCode']?.toString() ?? '',
    leadId: json['leadId']?.toString() ?? '',
    clientName: json['clientName']?.toString() ?? '',
    clientPhone: json['clientPhone']?.toString() ?? '',
    projectId: json['projectId']?.toString() ?? '',
    projectName: json['projectName']?.toString() ?? '',
    scheduledAt: json['scheduledAt'] != null
        ? DateTime.tryParse(json['scheduledAt']) ?? DateTime.now()
        : DateTime.now(),
    cabRequired: json['cabRequired'] as bool? ?? false,
    accompanying: json['accompanying'] as bool? ?? false,
    status: json['status']?.toString() ?? 'SCHEDULED',
    salesRepName: json['salesRepName']?.toString(),
    feedback: json['feedback']?.toString(),
  );
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'targetRoute': targetRoute,
    'targetId': targetId,
  };

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) => AppNotificationModel(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    message: json['message']?.toString() ?? '',
    type: json['type']?.toString() ?? 'broadcast',
    timestamp: json['timestamp'] != null
        ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
        : DateTime.now(),
    isRead: json['isRead'] == true,
    targetRoute: json['targetRoute']?.toString(),
    targetId: json['targetId']?.toString(),
  );
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'invoiceNumber': invoiceNumber,
    'leadId': leadId,
    'clientName': clientName,
    'clientPhone': clientPhone,
    'projectId': projectId,
    'projectName': projectName,
    'type': type.name,
    'amount': amount,
    'date': date.toIso8601String(),
    'status': status.name,
    'bankDetails': bankDetails.toJson(),
    'notes': notes,
  };

  factory CommissionInvoiceModel.fromJson(Map<String, dynamic> json) => CommissionInvoiceModel(
    id: json['id']?.toString() ?? '',
    invoiceNumber: json['invoiceNumber']?.toString() ?? '',
    leadId: json['leadId']?.toString() ?? '',
    clientName: json['clientName']?.toString() ?? '',
    clientPhone: json['clientPhone']?.toString() ?? '',
    projectId: json['projectId']?.toString() ?? '',
    projectName: json['projectName']?.toString() ?? '',
    type: InvoiceType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => InvoiceType.siteVisit,
    ),
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    date: json['date'] != null ? DateTime.tryParse(json['date']) ?? DateTime.now() : DateTime.now(),
    status: InvoiceStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => InvoiceStatus.pending,
    ),
    bankDetails: json['bankDetails'] != null
        ? BankDetailsModel.fromJson(Map<String, dynamic>.from(json['bankDetails']))
        : BankDetailsModel(accountHolder: '', bankName: '', accountNumber: '', ifscCode: ''),
    notes: json['notes']?.toString(),
  );
}

/// DTO for Parsed Lead Row during Bulk Import
class LeadImportRow {
  String firstName;
  String lastName;
  String phone;
  String? email;
  String budget;
  String projectId;
  String projectName;
  List<String> configurations;
  String source;
  bool isValid;
  String? validationError;
  bool isDuplicate;
  String? duplicateReason;

  LeadImportRow({
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    required this.budget,
    required this.projectId,
    required this.projectName,
    required this.configurations,
    this.source = 'CHANNEL_PARTNER',
    this.isValid = true,
    this.validationError,
    this.isDuplicate = false,
    this.duplicateReason,
  });

  String get fullName => '$firstName $lastName'.trim();
}

/// CSV Parser & Validator for Leads Bulk Import
class LeadCsvParser {
  static const String sampleInvestorLeads = '''Name,Phone,Email,Project,Budget,Source
Rahul Sharma,9876543210,rahul.sharma@gmail.com,Skyline Heights,1.2 - 1.5 Cr,Channel Partner
Priya Patel,9823456781,priya.patel@yahoo.com,Elysium Greens,85 - 95 L,Digital Ads
Amit Singh,9765432109,amit.singh@outlook.com,Aura Grand,2.0 - 2.5 Cr,Walk-in
Sunita Rao,9988776655,sunita.rao@techcorp.in,Skyline Heights,1.0 - 1.3 Cr,Referral
Vikram Malhotra,9123456789,vikram.m@investments.com,The Imperial Residences,3.5 - 4.5 Cr,Channel Partner''';

  static const String sampleLuxuryLeads = '''Name,Phone,Email,Project,Budget,Source
Karan Mehra,9811223344,karan.mehra@luxuryestate.in,The Imperial Residences,4.0 - 5.0 Cr,Channel Partner
Meera Sen,9833445566,meera.sen@senenterprises.com,The Imperial Residences,3.0 - 4.0 Cr,Referral
Arjun Kapoor,9744556677,arjun.k@startupventures.io,Skyline Heights,1.8 - 2.2 Cr,Direct Inquiry''';

  static const String sampleNriLeads = '''Name,Phone,Email,Project,Budget,Source
Rohan Nair,9871122334,rohan.nair@dubaiholdings.ae,Elysium Greens,1.5 - 2.0 Cr,Channel Partner
Ananya Deshmukh,9866778899,ananya.d@ushealthcare.org,Aura Grand,2.2 - 2.8 Cr,Website Inquiry
Sameer Merchant,9855667788,sameer.m@sginvestments.sg,The Imperial Residences,3.5 - 4.0 Cr,Channel Partner''';

  static List<LeadImportRow> parse({
    required String rawText,
    required List<ProjectModel> availableProjects,
    required bool Function(String phone) duplicateChecker,
  }) {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return [];

    final results = <LeadImportRow>[];

    // Detect if first line is header
    int startIndex = 0;
    final firstLine = lines.first.toLowerCase();
    Map<String, int> headerMap = {};

    if (firstLine.contains('phone') || firstLine.contains('name') || firstLine.contains('email')) {
      startIndex = 1;
      final headers = _splitCsvLine(lines.first).map((h) => h.toLowerCase().trim()).toList();
      for (int i = 0; i < headers.length; i++) {
        final h = headers[i];
        if (h.contains('name') || h == 'full name' || h == 'client') {
          headerMap['name'] = i;
        } else if (h.contains('first')) {
          headerMap['first_name'] = i;
        } else if (h.contains('last')) {
          headerMap['last_name'] = i;
        } else if (h.contains('phone') || h.contains('mobile') || h.contains('contact')) {
          headerMap['phone'] = i;
        } else if (h.contains('email')) {
          headerMap['email'] = i;
        } else if (h.contains('project')) {
          headerMap['project'] = i;
        } else if (h.contains('budget')) {
          headerMap['budget'] = i;
        } else if (h.contains('source')) {
          headerMap['source'] = i;
        } else if (h.contains('config') || h.contains('bhk')) {
          headerMap['config'] = i;
        }
      }
    }

    final defaultProject = availableProjects.isNotEmpty ? availableProjects.first : null;

    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i];
      final cols = _splitCsvLine(line);
      if (cols.isEmpty || cols.every((c) => c.isEmpty)) continue;

      String name = '';
      String firstName = '';
      String lastName = '';
      String phone = '';
      String? email;
      String budget = '1.0 - 1.5 Cr';
      String projectName = defaultProject?.name ?? 'Skyline Heights';
      String projectId = defaultProject?.id ?? 'p1';
      String source = 'CHANNEL_PARTNER';
      List<String> configs = ['2 BHK', '3 BHK'];

      if (headerMap.isNotEmpty) {
        if (headerMap.containsKey('name') && headerMap['name']! < cols.length) {
          name = cols[headerMap['name']!].trim();
        }
        if (headerMap.containsKey('first_name') && headerMap['first_name']! < cols.length) {
          firstName = cols[headerMap['first_name']!].trim();
        }
        if (headerMap.containsKey('last_name') && headerMap['last_name']! < cols.length) {
          lastName = cols[headerMap['last_name']!].trim();
        }
        if (headerMap.containsKey('phone') && headerMap['phone']! < cols.length) {
          phone = cols[headerMap['phone']!].trim();
        }
        if (headerMap.containsKey('email') && headerMap['email']! < cols.length) {
          final e = cols[headerMap['email']!].trim();
          email = e.isNotEmpty ? e : null;
        }
        if (headerMap.containsKey('project') && headerMap['project']! < cols.length) {
          final pName = cols[headerMap['project']!].trim();
          if (pName.isNotEmpty) {
            final match = availableProjects.firstWhere(
              (p) => p.name.toLowerCase().contains(pName.toLowerCase()) || pName.toLowerCase().contains(p.name.toLowerCase()),
              orElse: () => defaultProject ?? ProjectModel(
                id: 'p1',
                name: pName,
                location: 'Prime Location',
                startingPrice: '85 L',
                reraNumber: 'RERA/PRM/001',
                possessionDate: 'Dec 2026',
                type: 'Ongoing',
                heroImageUrl: '',
                galleryImages: [],
                amenities: [],
                approvedBanks: [],
                distanceDetails: '',
                towers: ['Tower A'],
                units: [],
              ),
            );
            projectName = match.name;
            projectId = match.id;
          }
        }
        if (headerMap.containsKey('budget') && headerMap['budget']! < cols.length) {
          final b = cols[headerMap['budget']!].trim();
          if (b.isNotEmpty) budget = b;
        }
        if (headerMap.containsKey('source') && headerMap['source']! < cols.length) {
          final s = cols[headerMap['source']!].trim();
          if (s.isNotEmpty) source = s;
        }
      } else {
        // Positional fallback: Name, Phone, Email, Project, Budget, Source
        if (cols.isNotEmpty) name = cols[0].trim();
        if (cols.length > 1) phone = cols[1].trim();
        if (cols.length > 2 && cols[2].trim().isNotEmpty) email = cols[2].trim();
        if (cols.length > 3 && cols[3].trim().isNotEmpty) {
          final pName = cols[3].trim();
          final match = availableProjects.firstWhere(
            (p) => p.name.toLowerCase().contains(pName.toLowerCase()) || pName.toLowerCase().contains(p.name.toLowerCase()),
            orElse: () => defaultProject ?? ProjectModel(
              id: 'p1',
              name: pName,
              location: 'Prime Location',
              startingPrice: '85 L',
              reraNumber: 'RERA/PRM/001',
              possessionDate: 'Dec 2026',
              type: 'Ongoing',
              heroImageUrl: '',
              galleryImages: [],
              amenities: [],
              approvedBanks: [],
              distanceDetails: '',
              towers: ['Tower A'],
              units: [],
            ),
          );
          projectName = match.name;
          projectId = match.id;
        }
        if (cols.length > 4 && cols[4].trim().isNotEmpty) budget = cols[4].trim();
        if (cols.length > 5 && cols[5].trim().isNotEmpty) source = cols[5].trim();
      }

      // Name normalization
      if (firstName.isEmpty && lastName.isEmpty) {
        if (name.isNotEmpty) {
          final parts = name.split(RegExp(r'\s+'));
          firstName = parts.first;
          if (parts.length > 1) {
            lastName = parts.sublist(1).join(' ');
          }
        } else {
          firstName = 'Lead';
          lastName = '#${i + 1}';
        }
      }

      // Phone validation & normalization
      final cleanDigits = phone.replaceAll(RegExp(r'[^\d]'), '');
      String cleanPhone = cleanDigits;
      if (cleanPhone.startsWith('91') && cleanPhone.length > 10) {
        cleanPhone = cleanPhone.substring(2);
      }

      bool isValid = true;
      String? error;
      bool isDuplicate = false;
      String? duplicateReason;

      if (cleanPhone.length < 10) {
        isValid = false;
        error = 'Phone number must have at least 10 digits ($phone)';
      } else {
        // Format as 10-digit
        cleanPhone = cleanPhone.substring(cleanPhone.length - 10);
        // Check duplicate
        if (duplicateChecker(cleanPhone)) {
          isDuplicate = true;
          duplicateReason = 'Active in pipeline / duplicate phone';
        }
      }

      results.add(
        LeadImportRow(
          firstName: firstName,
          lastName: lastName,
          phone: cleanPhone.isNotEmpty ? cleanPhone : phone,
          email: email,
          budget: budget,
          projectId: projectId,
          projectName: projectName,
          configurations: configs,
          source: source,
          isValid: isValid,
          validationError: error,
          isDuplicate: isDuplicate,
          duplicateReason: duplicateReason,
        ),
      );
    }

    return results;
  }

  static List<String> _splitCsvLine(String line) {
    if (line.contains('\t')) {
      return line.split('\t');
    }
    final result = <String>[];
    bool insideQuote = false;
    StringBuffer current = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        insideQuote = !insideQuote;
      } else if (char == ',' && !insideQuote) {
        result.add(current.toString().trim());
        current.clear();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString().trim());
    return result;
  }
}

/// DTO for Parsed Unit Row during Bulk Inventory Import
class UnitImportRow {
  String unitNo;
  String tower;
  int floor;
  String bhk;
  double carpetArea;
  double superArea;
  String facing;
  double basePrice;
  UnitStatus status;
  bool isValid;
  String? validationError;

  UnitImportRow({
    required this.unitNo,
    required this.tower,
    required this.floor,
    required this.bhk,
    required this.carpetArea,
    required this.superArea,
    required this.facing,
    required this.basePrice,
    required this.status,
    this.isValid = true,
    this.validationError,
  });

  UnitModel toUnitModel() => UnitModel(
    unitNo: unitNo,
    tower: tower,
    floor: floor,
    bhk: bhk,
    carpetArea: carpetArea,
    superArea: superArea,
    facing: facing,
    basePrice: basePrice,
    status: status,
  );
}

/// CSV Parser & Validator for Units / Inventory Bulk Import
class UnitCsvParser {
  static const String sampleTowerAUnits = '''UnitNo,Tower,Floor,BHK,CarpetArea,SuperArea,Facing,BasePrice,Status
A-101,Tower A,1,2 BHK,780,1050,East,8500000,available
A-102,Tower A,1,2 BHK,820,1110,North,8900000,available
A-201,Tower A,2,3 BHK,1150,1540,East,12500000,available
A-202,Tower A,2,3 BHK,1220,1650,North-East,13200000,blocked
A-301,Tower A,3,3.5 BHK,1380,1850,East,15500000,available
A-401,Tower A,4,Penthouse,2100,2850,East,26500000,sold''';

  static const String sampleTowerBUnits = '''UnitNo,Tower,Floor,BHK,CarpetArea,SuperArea,Facing,BasePrice,Status
B-101,Tower B,1,2 BHK,790,1060,West,8400000,available
B-102,Tower B,1,2.5 BHK,950,1280,South,9800000,available
B-201,Tower B,2,3 BHK,1180,1580,West,12800000,available
B-301,Tower B,3,3 BHK,1250,1680,North-West,13500000,available
B-401,Tower B,4,4 BHK,1650,2250,West,19500000,available''';

  static List<UnitImportRow> parse({
    required String rawText,
    required List<String> availableTowers,
    String? fallbackTower,
  }) {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return [];

    final results = <UnitImportRow>[];
    int startIndex = 0;
    final firstLine = lines.first.toLowerCase();
    Map<String, int> headerMap = {};

    if (firstLine.contains('unit') || firstLine.contains('bhk') || firstLine.contains('price') || firstLine.contains('floor')) {
      startIndex = 1;
      final headers = _splitCsvLine(lines.first).map((h) => h.toLowerCase().trim()).toList();
      for (int i = 0; i < headers.length; i++) {
        final h = headers[i];
        if (h.contains('unit') || h == 'flat' || h == 'number') {
          headerMap['unit_no'] = i;
        } else if (h.contains('tower') || h.contains('block') || h.contains('wing')) {
          headerMap['tower'] = i;
        } else if (h.contains('floor')) {
          headerMap['floor'] = i;
        } else if (h.contains('bhk') || h.contains('config') || h.contains('type')) {
          headerMap['bhk'] = i;
        } else if (h.contains('carpet') || h == 'sqft' || h == 'area') {
          headerMap['carpet_area'] = i;
        } else if (h.contains('super') || h.contains('built')) {
          headerMap['super_area'] = i;
        } else if (h.contains('facing') || h.contains('direction')) {
          headerMap['facing'] = i;
        } else if (h.contains('price') || h.contains('cost') || h.contains('amount')) {
          headerMap['price'] = i;
        } else if (h.contains('status')) {
          headerMap['status'] = i;
        }
      }
    }

    final defaultTower = fallbackTower ?? (availableTowers.isNotEmpty ? availableTowers.first : 'Tower A');

    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i];
      final cols = _splitCsvLine(line);
      if (cols.isEmpty || cols.every((c) => c.isEmpty)) continue;

      String unitNo = '';
      String tower = defaultTower;
      int floor = 1;
      String bhk = '2 BHK';
      double carpetArea = 850.0;
      double superArea = 1150.0;
      String facing = 'East';
      double basePrice = 8500000.0;
      UnitStatus status = UnitStatus.available;

      if (headerMap.isNotEmpty) {
        if (headerMap.containsKey('unit_no') && headerMap['unit_no']! < cols.length) {
          unitNo = cols[headerMap['unit_no']!].trim();
        }
        if (headerMap.containsKey('tower') && headerMap['tower']! < cols.length) {
          final t = cols[headerMap['tower']!].trim();
          if (t.isNotEmpty) tower = t;
        }
        if (headerMap.containsKey('floor') && headerMap['floor']! < cols.length) {
          final fStr = cols[headerMap['floor']!].replaceAll(RegExp(r'[^\d]'), '').trim();
          floor = int.tryParse(fStr) ?? 1;
        }
        if (headerMap.containsKey('bhk') && headerMap['bhk']! < cols.length) {
          final b = cols[headerMap['bhk']!].trim();
          if (b.isNotEmpty) bhk = b;
        }
        if (headerMap.containsKey('carpet_area') && headerMap['carpet_area']! < cols.length) {
          final cStr = cols[headerMap['carpet_area']!].replaceAll(RegExp(r'[^\d.]'), '').trim();
          carpetArea = double.tryParse(cStr) ?? 850.0;
        }
        if (headerMap.containsKey('super_area') && headerMap['super_area']! < cols.length) {
          final sStr = cols[headerMap['super_area']!].replaceAll(RegExp(r'[^\d.]'), '').trim();
          superArea = double.tryParse(sStr) ?? (carpetArea * 1.35);
        }
        if (headerMap.containsKey('facing') && headerMap['facing']! < cols.length) {
          final f = cols[headerMap['facing']!].trim();
          if (f.isNotEmpty) facing = f;
        }
        if (headerMap.containsKey('price') && headerMap['price']! < cols.length) {
          final pStr = cols[headerMap['price']!].replaceAll(RegExp(r'[^\d.]'), '').trim();
          basePrice = double.tryParse(pStr) ?? 8500000.0;
        }
        if (headerMap.containsKey('status') && headerMap['status']! < cols.length) {
          final s = cols[headerMap['status']!].toLowerCase().trim();
          if (s.contains('sold') || s == 'booked') {
            status = UnitStatus.sold;
          } else if (s.contains('block') || s == 'hold') {
            status = UnitStatus.blocked;
          } else {
            status = UnitStatus.available;
          }
        }
      } else {
        // Positional: UnitNo, Tower, Floor, BHK, CarpetArea, SuperArea, Facing, BasePrice, Status
        if (cols.isNotEmpty) unitNo = cols[0].trim();
        if (cols.length > 1 && cols[1].trim().isNotEmpty) tower = cols[1].trim();
        if (cols.length > 2) floor = int.tryParse(cols[2].replaceAll(RegExp(r'[^\d]'), '').trim()) ?? 1;
        if (cols.length > 3 && cols[3].trim().isNotEmpty) bhk = cols[3].trim();
        if (cols.length > 4) carpetArea = double.tryParse(cols[4].replaceAll(RegExp(r'[^\d.]'), '').trim()) ?? 850.0;
        if (cols.length > 5) superArea = double.tryParse(cols[5].replaceAll(RegExp(r'[^\d.]'), '').trim()) ?? (carpetArea * 1.35);
        if (cols.length > 6 && cols[6].trim().isNotEmpty) facing = cols[6].trim();
        if (cols.length > 7) basePrice = double.tryParse(cols[7].replaceAll(RegExp(r'[^\d.]'), '').trim()) ?? 8500000.0;
        if (cols.length > 8) {
          final s = cols[8].toLowerCase().trim();
          if (s.contains('sold')) {
            status = UnitStatus.sold;
          } else if (s.contains('block')) {
            status = UnitStatus.blocked;
          } else {
            status = UnitStatus.available;
          }
        }
      }

      bool isValid = true;
      String? error;

      if (unitNo.isEmpty) {
        isValid = false;
        error = 'Unit number cannot be blank';
      } else if (basePrice <= 0) {
        isValid = false;
        error = 'Base price must be greater than 0';
      }

      results.add(
        UnitImportRow(
          unitNo: unitNo,
          tower: tower,
          floor: floor,
          bhk: bhk,
          carpetArea: carpetArea,
          superArea: superArea,
          facing: facing,
          basePrice: basePrice,
          status: status,
          isValid: isValid,
          validationError: error,
        ),
      );
    }

    return results;
  }

  static List<String> _splitCsvLine(String line) {
    if (line.contains('\t')) {
      return line.split('\t');
    }
    final result = <String>[];
    bool insideQuote = false;
    StringBuffer current = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        insideQuote = !insideQuote;
      } else if (char == ',' && !insideQuote) {
        result.add(current.toString().trim());
        current.clear();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString().trim());
    return result;
  }
}

// ==========================================
// CP DOCUMENTS & RECEIVED INVOICES MODELS
// ==========================================

enum CpDocumentType {
  reraCertificate,
  panCard,
  gstCertificate,
  aadhaarCard,
  cpAgreement,
  cancelledCheque,
  specimenSignature,
  other,
}

extension CpDocumentTypeExtension on CpDocumentType {
  String get displayName {
    switch (this) {
      case CpDocumentType.reraCertificate:
        return 'RERA Certificate';
      case CpDocumentType.panCard:
        return 'PAN Card';
      case CpDocumentType.gstCertificate:
        return 'GST Certificate';
      case CpDocumentType.aadhaarCard:
        return 'Aadhaar / ID Proof';
      case CpDocumentType.cpAgreement:
        return 'CP Agreement / MOU';
      case CpDocumentType.cancelledCheque:
        return 'Bank Proof / Cheque';
      case CpDocumentType.specimenSignature:
        return 'Authorized Specimen Signature';
      case CpDocumentType.other:
        return 'Other Document';
    }
  }

  String get category {
    switch (this) {
      case CpDocumentType.reraCertificate:
      case CpDocumentType.panCard:
      case CpDocumentType.aadhaarCard:
        return 'Mandatory (KYC)';
      case CpDocumentType.gstCertificate:
      case CpDocumentType.specimenSignature:
        return 'Tax & Legal';
      case CpDocumentType.cpAgreement:
        return 'Agreements';
      case CpDocumentType.cancelledCheque:
        return 'Banking';
      case CpDocumentType.other:
        return 'General';
    }
  }
}

enum CpDocumentStatus {
  verified,
  underReview,
  missing,
  expired,
}

extension CpDocumentStatusExtension on CpDocumentStatus {
  String get displayName {
    switch (this) {
      case CpDocumentStatus.verified:
        return 'Verified';
      case CpDocumentStatus.underReview:
        return 'Under Review';
      case CpDocumentStatus.missing:
        return 'Action Required';
      case CpDocumentStatus.expired:
        return 'Expired';
    }
  }
}

class CpDocumentModel {
  final String id;
  final CpDocumentType type;
  final String title;
  final String documentNumber;
  final String? fileUrl;
  final String? fileName;
  final String? fileSize;
  final DateTime? uploadedAt;
  final DateTime? expiresAt;
  final CpDocumentStatus status;
  final bool isMandatory;
  final String? remarks;
  final List<int>? fileBytes;

  CpDocumentModel({
    required this.id,
    required this.type,
    required this.title,
    required this.documentNumber,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.uploadedAt,
    this.expiresAt,
    this.status = CpDocumentStatus.missing,
    this.isMandatory = true,
    this.remarks,
    this.fileBytes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'documentNumber': documentNumber,
    'fileUrl': fileUrl,
    'fileName': fileName,
    'fileSize': fileSize,
    'uploadedAt': uploadedAt?.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
    'status': status.name,
    'isMandatory': isMandatory,
    'remarks': remarks,
    'fileBytes': fileBytes != null ? base64Encode(fileBytes!) : null,
  };

  factory CpDocumentModel.fromJson(Map<String, dynamic> json) => CpDocumentModel(
    id: json['id']?.toString() ?? '',
    type: CpDocumentType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => CpDocumentType.other,
    ),
    title: json['title']?.toString() ?? '',
    documentNumber: json['documentNumber']?.toString() ?? '',
    fileUrl: json['fileUrl']?.toString(),
    fileName: json['fileName']?.toString(),
    fileSize: json['fileSize']?.toString(),
    uploadedAt: json['uploadedAt'] != null ? DateTime.tryParse(json['uploadedAt'].toString()) : null,
    expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'].toString()) : null,
    status: CpDocumentStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => CpDocumentStatus.missing,
    ),
    isMandatory: json['isMandatory'] == true,
    remarks: json['remarks']?.toString(),
    fileBytes: json['fileBytes'] != null
        ? base64Decode(json['fileBytes'].toString())
        : null,
  );

  CpDocumentModel copyWith({
    String? id,
    CpDocumentType? type,
    String? title,
    String? documentNumber,
    String? fileUrl,
    String? fileName,
    String? fileSize,
    DateTime? uploadedAt,
    DateTime? expiresAt,
    CpDocumentStatus? status,
    bool? isMandatory,
    String? remarks,
    List<int>? fileBytes,
  }) {
    return CpDocumentModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      documentNumber: documentNumber ?? this.documentNumber,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      isMandatory: isMandatory ?? this.isMandatory,
      remarks: remarks ?? this.remarks,
      fileBytes: fileBytes ?? this.fileBytes,
    );
  }
}

enum ReceivedInvoiceType {
  siteVisitPayout,
  bookingBrokerage,
  builderTaxInvoice,
  tdsCertificate16A,
}

extension ReceivedInvoiceTypeExtension on ReceivedInvoiceType {
  String get displayName {
    switch (this) {
      case ReceivedInvoiceType.siteVisitPayout:
        return 'Site Visit Payout';
      case ReceivedInvoiceType.bookingBrokerage:
        return 'Booking Brokerage';
      case ReceivedInvoiceType.builderTaxInvoice:
        return 'Tax Invoice';
      case ReceivedInvoiceType.tdsCertificate16A:
        return 'TDS Form 16A';
    }
  }
}

enum ReceivedInvoiceStatus {
  credited,
  processing,
  underReview,
}

extension ReceivedInvoiceStatusExtension on ReceivedInvoiceStatus {
  String get displayName {
    switch (this) {
      case ReceivedInvoiceStatus.credited:
        return 'Credited to Bank';
      case ReceivedInvoiceStatus.processing:
        return 'In Bank Processing';
      case ReceivedInvoiceStatus.underReview:
        return 'Verification Pending';
    }
  }
}

class ReceivedInvoiceModel {
  final String id;
  final String voucherNumber;
  final String invoiceNumber;
  final String leadId;
  final String clientName;
  final String projectId;
  final String projectName;
  final String? unitNumber;
  final ReceivedInvoiceType type;
  final double grossAmount;
  final double tdsRate;
  final double tdsAmount;
  final double netAmount;
  final DateTime disbursedDate;
  final ReceivedInvoiceStatus status;
  final String bankName;
  final String bankAccountNumber;
  final String utrNumber;
  final String financialYear;
  final String? notes;

  ReceivedInvoiceModel({
    required this.id,
    required this.voucherNumber,
    required this.invoiceNumber,
    required this.leadId,
    required this.clientName,
    required this.projectId,
    required this.projectName,
    this.unitNumber,
    required this.type,
    required this.grossAmount,
    this.tdsRate = 0.05,
    required this.tdsAmount,
    required this.netAmount,
    required this.disbursedDate,
    this.status = ReceivedInvoiceStatus.credited,
    required this.bankName,
    required this.bankAccountNumber,
    required this.utrNumber,
    this.financialYear = 'FY 2024-25',
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'voucherNumber': voucherNumber,
    'invoiceNumber': invoiceNumber,
    'leadId': leadId,
    'clientName': clientName,
    'projectId': projectId,
    'projectName': projectName,
    'unitNumber': unitNumber,
    'type': type.name,
    'grossAmount': grossAmount,
    'tdsRate': tdsRate,
    'tdsAmount': tdsAmount,
    'netAmount': netAmount,
    'disbursedDate': disbursedDate.toIso8601String(),
    'status': status.name,
    'bankName': bankName,
    'bankAccountNumber': bankAccountNumber,
    'utrNumber': utrNumber,
    'financialYear': financialYear,
    'notes': notes,
  };

  factory ReceivedInvoiceModel.fromJson(Map<String, dynamic> json) => ReceivedInvoiceModel(
    id: json['id']?.toString() ?? '',
    voucherNumber: json['voucherNumber']?.toString() ?? '',
    invoiceNumber: json['invoiceNumber']?.toString() ?? '',
    leadId: json['leadId']?.toString() ?? '',
    clientName: json['clientName']?.toString() ?? '',
    projectId: json['projectId']?.toString() ?? '',
    projectName: json['projectName']?.toString() ?? '',
    unitNumber: json['unitNumber']?.toString(),
    type: ReceivedInvoiceType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => ReceivedInvoiceType.siteVisitPayout,
    ),
    grossAmount: (json['grossAmount'] as num?)?.toDouble() ?? 0.0,
    tdsRate: (json['tdsRate'] as num?)?.toDouble() ?? 0.05,
    tdsAmount: (json['tdsAmount'] as num?)?.toDouble() ?? 0.0,
    netAmount: (json['netAmount'] as num?)?.toDouble() ?? 0.0,
    disbursedDate: json['disbursedDate'] != null ? DateTime.tryParse(json['disbursedDate'].toString()) ?? DateTime.now() : DateTime.now(),
    status: ReceivedInvoiceStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => ReceivedInvoiceStatus.credited,
    ),
    bankName: json['bankName']?.toString() ?? '',
    bankAccountNumber: json['bankAccountNumber']?.toString() ?? '',
    utrNumber: json['utrNumber']?.toString() ?? '',
    financialYear: json['financialYear']?.toString() ?? 'FY 2024-25',
    notes: json['notes']?.toString(),
  );
}

