import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cp_crm/core/models/app_models.dart';
import 'package:cp_crm/core/state/app_state.dart';
import 'package:cp_crm/features/chat/chat_list_screen.dart';
import 'package:cp_crm/features/chat/chat_conversation_screen.dart';
import 'package:cp_crm/features/chat/create_group_chat_modal.dart';
import 'package:cp_crm/features/chat/group_info_sheet.dart';
import 'package:cp_crm/features/dashboard/dashboard_screen.dart';
import 'package:cp_crm/features/home/main_navigation_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CP Chat & Messaging Models Serialization Tests', () {
    test('ChatMessageModel toJson and fromJson match correctly', () {
      final now = DateTime(2025, 6, 15, 10, 30);
      final msg = ChatMessageModel(
        id: 'msg_101',
        conversationId: 'conv_group_hyd',
        senderId: 'usr_cp_1',
        senderName: 'Rajesh Sharma',
        senderFirm: 'Apex Real Estate',
        text: 'Anyone has ready-to-move 3BHK inventory?',
        timestamp: now,
        isSystemMessage: false,
        status: MessageStatus.delivered,
      );

      final json = msg.toJson();
      final decoded = ChatMessageModel.fromJson(json);

      expect(decoded.id, 'msg_101');
      expect(decoded.conversationId, 'conv_group_hyd');
      expect(decoded.senderId, 'usr_cp_1');
      expect(decoded.senderName, 'Rajesh Sharma');
      expect(decoded.senderFirm, 'Apex Real Estate');
      expect(decoded.text, 'Anyone has ready-to-move 3BHK inventory?');
      expect(decoded.isSystemMessage, false);
      expect(decoded.status, MessageStatus.delivered);
    });

    test('ChatConversationModel toJson and fromJson match correctly for Group', () {
      final now = DateTime(2025, 6, 15, 9, 0);
      final conv = ChatConversationModel(
        id: 'conv_group_luxury',
        title: 'Hyderabad West Luxury Network',
        isGroup: true,
        description: 'Villas & High-Ticket Co-Broking',
        creatorId: 'usr_creator',
        participantIds: ['usr_creator', 'usr_p1', 'usr_p2'],
        adminIds: ['usr_creator'],
        lastMessage: 'Welcome to the group!',
        lastMessageTime: now,
        lastSenderName: 'Admin',
        unreadCount: 2,
        avatarColorIndex: 3,
        createdAt: now,
      );

      final json = conv.toJson();
      final decoded = ChatConversationModel.fromJson(json);

      expect(decoded.id, 'conv_group_luxury');
      expect(decoded.title, 'Hyderabad West Luxury Network');
      expect(decoded.isGroup, true);
      expect(decoded.description, 'Villas & High-Ticket Co-Broking');
      expect(decoded.creatorId, 'usr_creator');
      expect(decoded.participantIds.length, 3);
      expect(decoded.adminIds, contains('usr_creator'));
      expect(decoded.unreadCount, 2);
      expect(decoded.avatarColorIndex, 3);
    });
  });

  group('AppState Chat & Group Management Logic Tests', () {
    test('createGroupChat initializes group with creator as admin and initial system announcement', () {
      final state = AppState();
      final peer1 = UserModel(
        id: 'cp_test_1',
        name: 'Kavita Reddy',
        firmName: 'Kavita Realty',
        reraNumber: 'RERA-001',
        phone: '9880198765',
        email: 'kavita@realty.com',
        city: 'Bangalore',
        isAgency: true,
      );
      final peer2 = UserModel(
        id: 'cp_test_2',
        name: 'Rajesh Sharma',
        firmName: 'Apex Advisors',
        reraNumber: 'RERA-002',
        phone: '9849012345',
        email: 'rajesh@apex.com',
        city: 'Hyderabad',
        isAgency: true,
      );

      final group = state.createGroupChat(
        groupName: 'Bangalore Commercial Mastermind',
        description: 'Co-broking tech parks and Grade A office spaces',
        selectedMembers: [peer1, peer2],
        colorIndex: 2,
      );

      expect(group.title, 'Bangalore Commercial Mastermind');
      expect(group.isGroup, true);
      expect(group.description, 'Co-broking tech parks and Grade A office spaces');
      expect(group.participantIds, contains('cp_test_1'));
      expect(group.participantIds, contains('cp_test_2'));

      // Check that conversation exists in state
      expect(state.conversations.any((c) => c.id == group.id), true);

      // Check that system message was created
      final messages = state.getMessagesForConversation(group.id);
      expect(messages.length, 1);
      expect(messages.first.isSystemMessage, true);
      expect(messages.first.text, contains('Bangalore Commercial Mastermind'));
    });

    test('sendChatMessage posts message, updates conversation snippet, and moves thread to top', () {
      final state = AppState();
      final peer = UserModel(
        id: 'cp_direct_test',
        name: 'Vikram Joshi',
        firmName: 'Deccan Property',
        reraNumber: 'RERA-PUNE',
        phone: '9765432109',
        email: 'vikram@deccan.com',
        city: 'Pune',
        isAgency: false,
      );

      final conv = state.getOrCreateDirectChat(peer);
      final initialCount = state.getMessagesForConversation(conv.id).length;

      final sentMsg = state.sendChatMessage(
        conversationId: conv.id,
        text: 'Do you have buyers for 3BHK east facing in Avatar?',
      );

      expect(sentMsg.text, 'Do you have buyers for 3BHK east facing in Avatar?');
      final updatedMessages = state.getMessagesForConversation(conv.id);
      expect(updatedMessages.length, initialCount + 1);
      expect(updatedMessages.last.text, 'Do you have buyers for 3BHK east facing in Avatar?');

      // Conversation must be bumped to top
      expect(state.conversations.first.id, conv.id);
      expect(state.conversations.first.lastMessage, 'Do you have buyers for 3BHK east facing in Avatar?');
    });

    test('addMembersToGroup appends members and logs system announcement', () {
      final state = AppState();
      final peer1 = UserModel(
        id: 'cp_mem_1',
        name: 'Member One',
        firmName: 'Firm 1',
        reraNumber: 'RERA-1',
        phone: '9111111111',
        email: 'm1@firm.com',
        city: 'City 1',
        isAgency: false,
      );

      final group = state.createGroupChat(
        groupName: 'Test Circle',
        selectedMembers: [peer1],
      );

      final peer2 = UserModel(
        id: 'cp_mem_2',
        name: 'Member Two',
        firmName: 'Firm 2',
        reraNumber: 'RERA-2',
        phone: '9222222222',
        email: 'm2@firm.com',
        city: 'City 2',
        isAgency: false,
      );

      state.addMembersToGroup(group.id, [peer2]);

      final updatedConv = state.conversations.firstWhere((c) => c.id == group.id);
      expect(updatedConv.participantIds, contains('cp_mem_2'));

      final messages = state.getMessagesForConversation(group.id);
      expect(messages.any((m) => m.isSystemMessage && m.text.contains('Member Two')), true);
    });

    test('leaveGroup removes user from participantIds', () {
      final state = AppState();
      final peer = UserModel(
        id: 'cp_leave_peer',
        name: 'Peer CP',
        firmName: 'Peer Firm',
        reraNumber: 'RERA-PEER',
        phone: '9333333333',
        email: 'peer@firm.com',
        city: 'City',
        isAgency: false,
      );

      final group = state.createGroupChat(
        groupName: 'Exit Test Group',
        selectedMembers: [peer],
      );

      final currentUid = state.currentUser?.id ?? 'usr_guest';
      expect(group.participantIds, contains(currentUid));

      state.leaveGroup(group.id);

      final updatedConv = state.conversations.firstWhere((c) => c.id == group.id);
      expect(updatedConv.participantIds.contains(currentUid), false);
    });

    test('markConversationAsRead clears unread count', () {
      final state = AppState();
      if (state.conversations.isNotEmpty) {
        final targetConv = state.conversations.first;
        state.markConversationAsRead(targetConv.id);

        final updated = state.conversations.firstWhere((c) => c.id == targetConv.id);
        expect(updated.unreadCount, 0);
      }
    });
  });

  group('CP Chat UI & Strict No-Call Policy Widget Tests', () {
    testWidgets('ChatListScreen renders tabs, banner, and conversation cards', (tester) async {
      final state = AppState();
      await tester.pumpWidget(
        MaterialApp(
          home: ChatListScreen(state: state),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header & Compliance Banner
      expect(find.text('CP Community & Chats'), findsOneWidget);
      expect(find.textContaining('Text-Only Network'), findsOneWidget);

      // Verify Filter Tabs
      expect(find.textContaining('All Chats'), findsOneWidget);
      expect(find.textContaining('Direct ('), findsOneWidget);
      expect(find.textContaining('Groups ('), findsOneWidget);

      // Verify Floating Action Button
      expect(find.text('New Chat'), findsOneWidget);
    });

    testWidgets('ChatConversationScreen strictly contains NO phone call or video call buttons', (tester) async {
      final state = AppState();
      // Ensure at least one conversation exists
      if (state.conversations.isEmpty) {
        final peer = UserModel(
          id: 'cp_w_test',
          name: 'Widget Test Partner',
          firmName: 'Firm ABC',
          reraNumber: 'RERA-ABC',
          phone: '9444444444',
          email: 'abc@firm.com',
          city: 'Hyderabad',
          isAgency: false,
        );
        state.getOrCreateDirectChat(peer);
      }

      final testConv = state.conversations.first;

      await tester.pumpWidget(
        MaterialApp(
          home: ChatConversationScreen(
            state: state,
            conversationId: testConv.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Conversation title is rendered
      expect(find.text(testConv.title), findsOneWidget);

      // STRICT NO-CALL ASSERTION: Zero call icons
      expect(find.byIcon(Icons.phone), findsNothing);
      expect(find.byIcon(Icons.call), findsNothing);
      expect(find.byIcon(Icons.phone_enabled), findsNothing);
      expect(find.byIcon(Icons.videocam), findsNothing);
      expect(find.byIcon(Icons.video_call), findsNothing);

      // Verify input field and send button are present
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      // Verify Text-Only security pill is shown
      expect(find.textContaining('Text-Only Verified CP Network'), findsOneWidget);
    });

    testWidgets('GroupInfoSheet displays members and has NO call buttons', (tester) async {
      final state = AppState();
      final group = state.conversations.firstWhere(
        (c) => c.isGroup,
        orElse: () => state.createGroupChat(
          groupName: 'Widget Group Test',
          selectedMembers: state.networkCps.take(2).toList(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupInfoSheet(
              state: state,
              conversationId: group.id,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Group Title & Leave Group button
      expect(find.text(group.title), findsOneWidget);
      expect(find.text('Leave Group'), findsOneWidget);

      // STRICT NO-CALL ASSERTION inside Group Info: Zero call icons
      expect(find.byIcon(Icons.phone), findsNothing);
      expect(find.byIcon(Icons.call), findsNothing);
      expect(find.byIcon(Icons.videocam), findsNothing);

      // Verify text-only policy notice inside info sheet
      expect(find.textContaining('Direct phone calls are disabled'), findsOneWidget);
    });

    testWidgets('CreateGroupChatModal renders name input and member selection', (tester) async {
      final state = AppState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreateGroupChatModal(state: state),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create New CP Group Chat'), findsOneWidget);
      expect(find.text('Group Name *'), findsOneWidget);
      expect(find.text('Group Color Badge'), findsOneWidget);
      expect(find.textContaining('Select Channel Partners'), findsOneWidget);
      expect(find.textContaining('Create Group'), findsOneWidget);
    });

    testWidgets('Dashboard top bar does NOT contain chat icon button (moved to bottom nav)', (tester) async {
      final state = AppState();
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(
            state: state,
            onNavigateTab: (_) {},
            onOpenAddLead: () {},
            onOpenScheduleVisit: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure top bar has no forum/chat icon
      expect(find.byIcon(Icons.forum_outlined), findsNothing);
    });

    testWidgets('MainNavigationShell renders Chats tab in bottom nav and navigates to ChatListScreen on tap', (tester) async {
      final state = AppState();
      await tester.pumpWidget(
        MaterialApp(
          home: MainNavigationShell(state: state),
        ),
      );
      await tester.pumpAndSettle();

      // Bottom nav should display 'Chats'
      expect(find.text('Chats'), findsOneWidget);
      expect(find.byIcon(Icons.forum_outlined), findsOneWidget);

      // Tap 'Chats' tab
      await tester.tap(find.text('Chats'));
      await tester.pumpAndSettle();

      // Should now display ChatListScreen content
      expect(find.text('CP Community & Chats'), findsOneWidget);
      expect(find.textContaining('Text-Only Network'), findsOneWidget);
    });
  });
}
