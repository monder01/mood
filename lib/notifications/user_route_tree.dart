import 'package:mood01/notifications/route_node.dart';

const List<RouteNode> userRouteTree = [
  RouteNode(
    title: "الرئيسية",
    children: [
      RouteNode(title: "الصفحة الرئيسية", path: "/"),
      RouteNode(title: "التصفح الرئيسي", path: "/browse"),
      RouteNode(title: "عن التطبيق", path: "/about"),
      RouteNode(title: "الاستكشاف", path: "/discover"),
      RouteNode(title: "الإشعارات", path: "/notifications"),
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
    title: "المحادثات",
    children: [RouteNode(title: "محادثاتي", path: "/conversations")],
  ),
  RouteNode(
    title: "التصفح الأكاديمي",
    children: [RouteNode(title: "تصفح المستخدم", path: "/user-browse")],
  ),
];
