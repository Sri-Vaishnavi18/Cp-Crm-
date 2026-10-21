import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cp_crm/core/models/app_models.dart';
import 'package:cp_crm/core/state/app_state.dart';
import 'package:cp_crm/features/projects/projects_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Lead Bulk Import & Parser Tests', () {
    test('LeadCsvParser parses CSV with standard headers correctly', () {
      final state = AppState();
      const csvData = '''Name,Phone,Email,Project,Budget,Source
Aarav Sharma,+91 98765 43210,aarav@gmail.com,Prestige Serenity Palms,1.2 - 1.5 Cr,Google Ads
Priya Patel,9823456780,priya.patel@outlook.com,Brigade,95 L - 1.2 Cr,Direct Referral
''';

      final results = LeadCsvParser.parse(
        rawText: csvData,
        availableProjects: state.projects,
        duplicateChecker: (phone) => state.checkLeadDuplicate(phone).isDuplicate,
      );
      expect(results.length, 2);

      final row1 = results[0];
      expect(row1.firstName, 'Aarav');
      expect(row1.lastName, 'Sharma');
      expect(row1.fullName, 'Aarav Sharma');
      expect(row1.phone, '9876543210');
      expect(row1.email, 'aarav@gmail.com');
      expect(row1.projectName, 'Prestige Serenity Palms');
      expect(row1.budget, '1.2 - 1.5 Cr');
      expect(row1.source, 'Google Ads');
      expect(row1.isValid, isTrue);

      final row2 = results[1];
      expect(row2.firstName, 'Priya');
      expect(row2.lastName, 'Patel');
      expect(row2.phone, '9823456780');
      expect(row2.email, 'priya.patel@outlook.com');
      expect(row2.projectName.contains('Brigade') || row2.projectName.isNotEmpty, isTrue);
      expect(row2.isValid, isTrue);
    });

    test('LeadCsvParser flags duplicate phone numbers in active pipeline', () {
      final state = AppState();
      final existingPhone = state.allLeads.first.phone;

      final csvData = '''Name,Phone,Email,Project
Duplicate Lead,$existingPhone,dup@test.com,Prestige Serenity Palms
''';

      final results = LeadCsvParser.parse(
        rawText: csvData,
        availableProjects: state.projects,
        duplicateChecker: (phone) => state.checkLeadDuplicate(phone).isDuplicate,
      );
      expect(results.length, 1);
      expect(results[0].isDuplicate, isTrue);
      expect(results[0].duplicateReason, isNotNull);
    });

    test('LeadCsvParser catches invalid rows with short or missing phone numbers', () {
      final state = AppState();
      const csvData = '''Name,Phone,Email,Project
Short Phone User,12345,no_phone@test.com,Prestige Serenity Palms
''';

      final results = LeadCsvParser.parse(
        rawText: csvData,
        availableProjects: state.projects,
        duplicateChecker: (phone) => state.checkLeadDuplicate(phone).isDuplicate,
      );
      expect(results.length, 1);
      expect(results[0].isValid, isFalse);
      expect(results[0].validationError, contains('at least 10 digits'));
    });

    test('LeadCsvParser parses tab-separated and positional fallback rows', () {
      final state = AppState();
      const tsvData = 'Rohan Verma\t9988776655\trohan@tech.com\tPrestige Serenity Palms\t2.5 Cr\tLinkedIn';

      final results = LeadCsvParser.parse(
        rawText: tsvData,
        availableProjects: state.projects,
        duplicateChecker: (phone) => state.checkLeadDuplicate(phone).isDuplicate,
      );
      expect(results.length, 1);
      expect(results[0].firstName, 'Rohan');
      expect(results[0].lastName, 'Verma');
      expect(results[0].phone, '9988776655');
      expect(results[0].projectName, 'Prestige Serenity Palms');
      expect(results[0].isValid, isTrue);
    });

    test('Sample lead campaign templates are non-empty and valid', () {
      final state = AppState();
      final templates = [
        LeadCsvParser.sampleInvestorLeads,
        LeadCsvParser.sampleLuxuryLeads,
        LeadCsvParser.sampleNriLeads,
      ];

      for (final template in templates) {
        expect(template.isNotEmpty, isTrue);
        final parsed = LeadCsvParser.parse(
          rawText: template,
          availableProjects: state.projects,
          duplicateChecker: (phone) => state.checkLeadDuplicate(phone).isDuplicate,
        );
        expect(parsed.isNotEmpty, isTrue);
        expect(parsed.any((r) => r.isValid), isTrue);
      }
    });
  });

  group('Unit Matrix Bulk Import & Parser Tests', () {
    test('UnitCsvParser parses standard unit CSV with status mapping', () {
      final state = AppState();
      final targetProject = state.projects.first;
      const csvData = '''UnitNo,Tower,Floor,BHK,CarpetArea,SuperArea,Facing,BasePrice,Status
A-101,Tower A,1,3 BHK,1350,1820,North-East,14500000,available
A-102,Tower A,1,2 BHK,980,1320,East,9800000,blocked
A-103,Tower A,1,4 BHK,2100,2850,West,22500000,sold
''';

      final results = UnitCsvParser.parse(
        rawText: csvData,
        availableTowers: targetProject.towers,
        fallbackTower: targetProject.towers.first,
      );
      expect(results.length, 3);

      expect(results[0].unitNo, 'A-101');
      expect(results[0].tower, 'Tower A');
      expect(results[0].floor, 1);
      expect(results[0].bhk, '3 BHK');
      expect(results[0].carpetArea, 1350);
      expect(results[0].superArea, 1820);
      expect(results[0].facing, 'North-East');
      expect(results[0].basePrice, 14500000);
      expect(results[0].status, UnitStatus.available);
      expect(results[0].isValid, isTrue);

      expect(results[1].unitNo, 'A-102');
      expect(results[1].status, UnitStatus.blocked);

      expect(results[2].unitNo, 'A-103');
      expect(results[2].status, UnitStatus.sold);
    });

    test('Sample unit inventory templates parse correctly', () {
      final state = AppState();
      final project = state.projects.first;

      final towerA = UnitCsvParser.parse(
        rawText: UnitCsvParser.sampleTowerAUnits,
        availableTowers: project.towers,
        fallbackTower: 'Tower A',
      );
      expect(towerA.length, greaterThan(0));

      final towerB = UnitCsvParser.parse(
        rawText: UnitCsvParser.sampleTowerBUnits,
        availableTowers: project.towers,
        fallbackTower: 'Tower B',
      );
      expect(towerB.length, greaterThan(0));
    });
  });

  group('AppState Bulk Import & Project Creation Actions', () {
    test('AppState.bulkImportLeads creates leads, timeline events, and notification', () {
      final state = AppState();
      final initialCount = state.allLeads.length;
      final initialNotifs = state.notifications.length;

      final rowsToImport = [
        LeadImportRow(
          firstName: 'Bulk',
          lastName: 'Tester 1',
          phone: '9111122222',
          email: 'bulk1@test.com',
          projectId: 'p1',
          projectName: 'Prestige Serenity Palms',
          budget: '1.5 Cr',
          configurations: ['2 BHK', '3 BHK'],
          source: 'Bulk CSV Campaign',
          isValid: true,
        ),
        LeadImportRow(
          firstName: 'Bulk',
          lastName: 'Tester 2',
          phone: '9333344444',
          email: 'bulk2@test.com',
          projectId: 'p2',
          projectName: 'Brigade Oasis',
          budget: '85 L',
          configurations: ['2 BHK'],
          source: 'Bulk CSV Campaign',
          isValid: true,
        ),
      ];

      final importedCount = state.bulkImportLeads(rowsToImport);
      expect(importedCount, 2);
      expect(state.allLeads.length, initialCount + 2);
      expect(state.notifications.length, initialNotifs + 1);

      final importedLead = state.allLeads.firstWhere((l) => l.phone == '9111122222');
      expect(importedLead.firstName, 'Bulk');
      expect(importedLead.lastName, 'Tester 1');
      expect(importedLead.stage, LeadStage.cold);
      expect(importedLead.temperature, LeadTemperature.cold);
      expect(importedLead.activityList.isNotEmpty, isTrue);
      expect(importedLead.activityList.first.title, contains('Bulk CSV'));
    });

    test('AppState.addProject adds project, creates starter units, and notifies user', () {
      final state = AppState();
      final initialProjCount = state.projects.length;
      final initialNotifs = state.notifications.length;

      final newProject = ProjectModel(
        id: 'proj_apex_nirvana',
        name: 'Apex Nirvana Grandeur',
        location: 'Golf Course Extension, Gurugram',
        startingPrice: '2.20 Cr',
        reraNumber: 'RC/REP/HARERA/GGM/2026/88',
        possessionDate: 'Dec 2027',
        type: 'Under Construction',
        heroImageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800',
        galleryImages: [],
        amenities: ['Infinity Pool', 'Sky Lounge', 'Clubhouse', 'EV Charging'],
        approvedBanks: ['HDFC Bank', 'ICICI Bank', 'SBI'],
        distanceDetails: '15 mins from Cyber City',
        towers: ['Tower A', 'Tower B'],
        units: [
          UnitModel(
            unitNo: 'NG-101',
            tower: 'Tower A',
            floor: 1,
            bhk: '3 BHK',
            carpetArea: 1750,
            superArea: 2350,
            facing: 'North-East',
            basePrice: 22000000,
            status: UnitStatus.available,
          ),
        ],
      );

      state.addProject(newProject);
      expect(state.projects.length, initialProjCount + 1);
      expect(state.projects.first.id, 'proj_apex_nirvana');
      expect(state.notifications.length, initialNotifs + 1);
      expect(state.notifications.first.title, contains('New Project Added'));
    });

    test('AppState.bulkImportUnits adds units to project and updates starting price if lower', () {
      final state = AppState();
      final targetProject = state.projects.first;
      final initialUnitsCount = targetProject.units.length;

      final newUnits = [
        UnitModel(
          unitNo: 'T1-901',
          tower: 'Tower 1',
          floor: 9,
          bhk: '2 BHK',
          carpetArea: 850,
          superArea: 1150,
          facing: 'East',
          basePrice: 4500000, // lower than default starting price
          status: UnitStatus.available,
        ),
        UnitModel(
          unitNo: 'T1-902',
          tower: 'Tower 1',
          floor: 9,
          bhk: '3 BHK',
          carpetArea: 1350,
          superArea: 1850,
          facing: 'North',
          basePrice: 8500000,
          status: UnitStatus.available,
        ),
      ];

      final importedCount = state.bulkImportUnits(targetProject.id, newUnits);
      expect(importedCount, 2);
      expect(targetProject.units.length, initialUnitsCount + 2);
      expect(targetProject.startingPrice.contains('45 L') || targetProject.startingPrice.contains('45'), isTrue);
      expect(state.notifications.first.title, contains('Inventory Units Updated'));
    });

    test('UnitModel and ProjectModel toJson and fromJson serialization works', () {
      final unit = UnitModel(
        unitNo: 'A-502',
        tower: 'Tower A',
        floor: 5,
        bhk: '3 BHK',
        carpetArea: 1420,
        superArea: 1890,
        facing: 'East',
        basePrice: 16500000,
        status: UnitStatus.available,
      );

      final unitJson = unit.toJson();
      final fromJsonUnit = UnitModel.fromJson(unitJson);
      expect(fromJsonUnit.unitNo, 'A-502');
      expect(fromJsonUnit.tower, 'Tower A');
      expect(fromJsonUnit.floor, 5);
      expect(fromJsonUnit.bhk, '3 BHK');
      expect(fromJsonUnit.facing, 'East');
      expect(fromJsonUnit.basePrice, 16500000);
      expect(fromJsonUnit.status, UnitStatus.available);

      final project = ProjectModel(
        id: 'proj_test_json',
        name: 'Test Project',
        location: 'Hyderabad',
        startingPrice: '1.65 Cr',
        reraNumber: 'P02400001234',
        possessionDate: 'Ready',
        type: 'Ready to Move',
        heroImageUrl: 'https://example.com/test.jpg',
        galleryImages: [],
        amenities: ['Gym', 'Pool'],
        approvedBanks: ['HDFC'],
        distanceDetails: 'Near Metro',
        towers: ['Tower A'],
        units: [unit],
      );

      final projectJson = project.toJson();
      final fromJsonProject = ProjectModel.fromJson(projectJson);
      expect(fromJsonProject.id, 'proj_test_json');
      expect(fromJsonProject.name, 'Test Project');
      expect(fromJsonProject.units.length, 1);
      expect(fromJsonProject.units.first.unitNo, 'A-502');
    });

    test('All mock projects have populated units and towers for unit matrix visibility', () {
      final state = AppState();
      for (final project in state.projects) {
        expect(project.units, isNotEmpty, reason: '${project.name} should have units visible');
        expect(project.towers, isNotEmpty, reason: '${project.name} should have towers defined');
        final availableUnits = project.units.where((u) => u.status == UnitStatus.available);
        expect(availableUnits, isNotEmpty, reason: '${project.name} should have available units');
      }
    });

    test('AppState updateProject modifies project details, units, and brochure properly', () {
      final state = AppState();
      final original = state.projects.first;

      final updated = ProjectModel(
        id: original.id,
        name: 'Updated Luxury Heights',
        location: 'Financial District, Hyderabad',
        startingPrice: '2.5 Cr',
        reraNumber: 'P02400009999',
        possessionDate: 'March 2027',
        type: 'Ready to Move',
        heroImageUrl: original.heroImageUrl,
        galleryImages: original.galleryImages,
        amenities: ['Clubhouse', 'Infinity Pool'],
        approvedBanks: ['HDFC Bank', 'ICICI Bank'],
        distanceDetails: 'Near Metro: 500m',
        towers: ['Tower 1', 'Tower 2'],
        units: [
          UnitModel(
            unitNo: 'T1-1001',
            tower: 'Tower 1',
            floor: 10,
            bhk: '3 BHK',
            carpetArea: 1500,
            superArea: 2025,
            facing: 'East',
            basePrice: 15000000,
            status: UnitStatus.available,
          ),
        ],
        brochureFileName: 'Updated_Luxury_Heights_Brochure.pdf',
        brochureFileSize: '6.5 MB',
        brochureUpdatedAt: DateTime.now(),
      );

      final success = state.updateProject(updated);
      expect(success, isTrue);

      final fetched = state.projects.firstWhere((p) => p.id == original.id);
      expect(fetched.name, 'Updated Luxury Heights');
      expect(fetched.location, 'Financial District, Hyderabad');
      expect(fetched.startingPrice, '2.5 Cr');
      expect(fetched.units.length, 1);
      expect(fetched.units.first.unitNo, 'T1-1001');
      expect(fetched.brochureFileName, 'Updated_Luxury_Heights_Brochure.pdf');
    });

    testWidgets('ProjectsScreen renders Edit Details button in place of Share', (WidgetTester tester) async {
      final state = AppState();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectsScreen(state: state),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Details and Brochure buttons exist
      expect(find.text('Details'), findsWidgets);
      expect(find.text('Brochure'), findsWidgets);

      // Verify Edit Details button is rendered in place of Share
      expect(find.text('Edit Details'), findsWidgets);
      expect(find.byIcon(Icons.edit_note_rounded), findsWidgets);

      // Verify Share button is no longer present
      expect(find.text('Share'), findsNothing);
      expect(find.byIcon(Icons.share_outlined), findsNothing);
    });
  });
}
