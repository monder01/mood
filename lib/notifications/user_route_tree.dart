import 'package:mood01/notifications/route_node.dart';

const List<RouteNode> userRouteTree = [
  RouteNode(
    title: "الحساب",
    children: [
      RouteNode(title: "حسابي", path: "/my-account"),
      RouteNode(title: "الإعدادات", path: "/setting"),
      RouteNode(title: "الاشتراك", path: "/subscription"),
    ],
  ),

  RouteNode(
    title: "التصفح",
    children: [
      RouteNode(title: "الصفحة الرئيسية", path: "/browse"),
      RouteNode(title: "صفحة البحث", path: "/discover"),
      RouteNode(title: "عن التطبيق", path: "/about"),
    ],
  ),

  RouteNode(
    title: "الأصدقاء",
    children: [
      RouteNode(title: "البحث عن أصدقاء", path: "/search-friends"),
      RouteNode(title: "زملائي", path: "/fellows"),
    ],
  ),

  RouteNode(
    title: "المحادثات والإشعارات",
    children: [
      RouteNode(title: "محادثاتي", path: "/conversations"),
      RouteNode(title: "الإشعارات", path: "/notifications"),
    ],
  ),
];
