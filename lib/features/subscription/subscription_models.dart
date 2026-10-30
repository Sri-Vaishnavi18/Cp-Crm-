enum SubscriptionTier {
  monthly,
  halfYearly,
  annual,
}

class SubscriptionPlanModel {
  final SubscriptionTier tier;
  final String id;
  final String title;
  final String subtitle;
  final int durationDays;
  final int durationMonths;
  final double price;
  final double monthlyEquivalent;
  final double? originalPrice;
  final String? savingsText;
  final String? badgeText;
  final bool isPopular;
  final bool isBestValue;
  final List<String> features;

  const SubscriptionPlanModel({
    required this.tier,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.durationDays,
    required this.durationMonths,
    required this.price,
    required this.monthlyEquivalent,
    this.originalPrice,
    this.savingsText,
    this.badgeText,
    this.isPopular = false,
    this.isBestValue = false,
    required this.features,
  });

  String get formattedPrice => '₹${price.toStringAsFixed(0)}';
  String get formattedMonthlyEquivalent => '₹${monthlyEquivalent.toStringAsFixed(0)}/mo';
  String get formattedOriginalPrice => originalPrice != null ? '₹${originalPrice!.toStringAsFixed(0)}' : '';

  static const List<SubscriptionPlanModel> availablePlans = [
    SubscriptionPlanModel(
      tier: SubscriptionTier.monthly,
      id: 'plan_1_month',
      title: '1 Month Starter',
      subtitle: 'Flexible monthly billing for individual CP brokers',
      durationDays: 30,
      durationMonths: 1,
      price: 1000.0,
      monthlyEquivalent: 1000.0,
      originalPrice: null,
      savingsText: null,
      badgeText: null,
      isPopular: false,
      isBestValue: false,
      features: [
        'Unlimited Leads & Client Management',
        'Zero-OTP Site Visits & Cab Tracking',
        'Real-time Project Inventory & Unit Matrix',
        'Text-Only Verified Broker Network Chat',
        'Commission Claims & Disbursal Tracking',
        'RERA & KYC Document Vault',
        'Standard Support via Helpdesk',
      ],
    ),
    SubscriptionPlanModel(
      tier: SubscriptionTier.halfYearly,
      id: 'plan_6_months',
      title: '6 Months Pro',
      subtitle: 'Most chosen by active brokers & growing firms',
      durationDays: 180,
      durationMonths: 6,
      price: 5000.0,
      monthlyEquivalent: 833.33,
      originalPrice: 6000.0,
      savingsText: 'Save ₹1,000 (16.7% OFF)',
      badgeText: 'MOST POPULAR ⭐',
      isPopular: true,
      isBestValue: false,
      features: [
        'Everything in 1 Month Starter Plan',
        'Save ₹1,000 compared to monthly billing',
        'Priority SPOC Helpdesk & Faster Response',
        'Direct Builder Disbursal Voucher Approval',
        'Multi-lead Bulk CSV Import & Team Export',
        'Pro Partner Badge on Community Chat',
        'Automated RERA Document Expiry Alerts',
      ],
    ),
    SubscriptionPlanModel(
      tier: SubscriptionTier.annual,
      id: 'plan_1_year',
      title: '1 Year Elite',
      subtitle: 'Maximum savings & full VIP privileges for established firms',
      durationDays: 365,
      durationMonths: 12,
      price: 10000.0,
      monthlyEquivalent: 833.33,
      originalPrice: 12000.0,
      savingsText: 'Save ₹2,000 (2 Months FREE)',
      badgeText: 'BEST VALUE 🏆',
      isPopular: false,
      isBestValue: true,
      features: [
        'Everything in 6 Months Pro Plan',
        'Save ₹2,000 — 2 Months completely FREE',
        'Verified Gold Broker Badge on Chat Network',
        'Dedicated VIP Account Concierge',
        'Unlimited Cloud Document & Invoice Storage',
        'Priority Co-broking Deal Matchmaker',
        'Annual GST Input Tax Invoices & Reports',
      ],
    ),
  ];
}

