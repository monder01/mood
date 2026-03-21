import 'package:go_router/go_router.dart';
import 'package:mood01/global/browse_page.dart';
import 'package:mood01/auth/signin_page.dart';
import 'package:mood01/auth/signup_page.dart';
import 'package:mood01/designs/about_us_page.dart';
import 'package:mood01/notifications/my_notifications_page.dart';
import 'package:mood01/designs/home_page.dart';
import 'package:mood01/auth/splash_page.dart';
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
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),

      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const Homepage(),
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
    ],
  );

  // ========= مسارات جاهزة =========

  static const String splash = '/';
  static const String signin = '/signin';
  static const String signup = '/signup';
  static const String browse = '/browse';
  static const String about = '/about';
  static const String discover = '/discover';
  static const String browseColleges = '/browse-colleges';
  static const String searchFriends = '/search-friends';
  static const String fellows = '/fellows';
  static const String conversations = '/conversations';
  static const String notifications = '/notifications';
  static const String home = '/home';

  static String chatPath(String otherUserId) {
    return '/chat/${Uri.encodeComponent(otherUserId)}';
  }

  static String departmentsPath({
    required String collegeId,
    required String collegeName,
  }) {
    return '/departments/${Uri.encodeComponent(collegeId)}/${Uri.encodeComponent(collegeName)}';
  }

  static String coursesPath({
    required String departmentId,
    required String departmentName,
  }) {
    return '/courses/${Uri.encodeComponent(departmentId)}/${Uri.encodeComponent(departmentName)}';
  }

  static String commentsPath(String courseId) {
    return '/comments/${Uri.encodeComponent(courseId)}';
  }

  static String buildDynamicRoute(String template, Map<String, String> values) {
    String result = template;

    values.forEach((key, value) {
      result = result.replaceAll(':$key', Uri.encodeComponent(value));
    });

    return result;
  }
}
