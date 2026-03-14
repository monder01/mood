import 'package:go_router/go_router.dart';
import 'package:mood01/auth/auth.dart';
import 'package:mood01/global/browse_page.dart';
import 'package:mood01/auth/signin_page.dart';
import 'package:mood01/auth/signup_page.dart';
import 'package:mood01/screens/about_us_page.dart';
import 'package:mood01/notifications/my_notifications_page.dart';
import 'package:mood01/student/discover_page.dart';
import 'package:mood01/student/user_browse_page.dart';
import 'package:mood01/student/user_browse_department_page.dart';
import 'package:mood01/student/user_browse_courses_page.dart';
import 'package:mood01/student/user_browse_sections_page.dart';
import 'package:mood01/friends/search_for_friends_page.dart';
import 'package:mood01/friends/user_fellows_page.dart';
import 'package:mood01/chats/my_conversations_page.dart';
import 'package:mood01/chats/chat_page.dart';

class NaviGo {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'authWrapper',
        builder: (context, state) => const AuthWrapper(),
      ),

      GoRoute(
        path: '/signin',
        name: 'signin',
        builder: (context, state) => const Signinpage(),
      ),

      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const Signuppage(),
      ),

      GoRoute(
        path: '/browse',
        name: 'browse',
        builder: (context, state) => const Browsepage(),
      ),

      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => AboutAppPage(),
      ),

      GoRoute(
        path: '/discover',
        name: 'discover',
        builder: (context, state) => const DiscoverPage(),
      ),

      GoRoute(
        path: '/user-browse',
        name: 'userBrowse',
        builder: (context, state) => const UserBrowsePage(),
      ),

      GoRoute(
        path: '/search-friends',
        name: 'searchFriends',
        builder: (context, state) => const SearchForFriendsPage(),
      ),

      GoRoute(
        path: '/fellows',
        name: 'fellows',
        builder: (context, state) => const UserFellowsPage(),
      ),

      GoRoute(
        path: '/conversations',
        name: 'conversations',
        builder: (context, state) => const MyConversationsPage(),
      ),

      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const MyNotificationsPage(),
      ),

      GoRoute(
        path: '/chat/:otherUserId',
        name: 'chat',
        builder: (context, state) {
          final otherUserId = state.pathParameters['otherUserId']!;
          return ChatPage(otherUserId: otherUserId);
        },
      ),

      GoRoute(
        path: '/departments/:collegeId/:collegeName',
        name: 'departments',
        builder: (context, state) {
          final collegeId = state.pathParameters['collegeId']!;
          final collegeName = state.pathParameters['collegeName']!;

          return UserBrowseDepartmentPage(
            collegeId: collegeId,
            collegeName: collegeName,
          );
        },
      ),

      GoRoute(
        path: '/courses/:departmentId/:departmentName',
        name: 'courses',
        builder: (context, state) {
          final departmentId = state.pathParameters['departmentId']!;
          final departmentName = state.pathParameters['departmentName']!;

          return UserBrowseCoursesPage(
            departmentId: departmentId,
            departmentName: departmentName,
          );
        },
      ),

      GoRoute(
        path: '/sections/:sectionId/:sectionName',
        name: 'sections',
        builder: (context, state) {
          final sectionId = state.pathParameters['sectionId']!;
          final sectionName = state.pathParameters['sectionName']!;

          return UserBrowseSectionsPage(
            sectionId: sectionId,
            sectionName: sectionName,
          );
        },
      ),
    ],
  );
  String buildDynamicRoute(String template, Map<String, String> values) {
    String result = template;

    values.forEach((key, value) {
      result = result.replaceAll(':$key', Uri.encodeComponent(value));
    });

    return result;
  }
}
