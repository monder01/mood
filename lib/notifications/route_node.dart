class RouteNode {
  final String title;
  final String? path;
  final List<RouteNode> children;

  const RouteNode({required this.title, this.path, this.children = const []});

  bool get isFolder => children.isNotEmpty;
  bool get isPage => path != null;
}
