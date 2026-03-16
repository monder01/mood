import 'package:flutter/material.dart';
import 'package:mood01/notifications/route_node.dart';

class RoutePickerPage extends StatefulWidget {
  final List<RouteNode> routesTree;

  const RoutePickerPage({super.key, required this.routesTree});

  @override
  State<RoutePickerPage> createState() => _RoutePickerPageState();
}

class _RoutePickerPageState extends State<RoutePickerPage> {
  late List<RouteNode> currentNodes;
  final List<RouteNode> navigationStack = [];
  RouteNode? selectedNode;

  @override
  void initState() {
    super.initState();
    currentNodes = widget.routesTree;
  }

  void openFolder(RouteNode node) {
    if (!node.isFolder) return;

    navigationStack.add(node);
    currentNodes = node.children;
    selectedNode = null;
    setState(() {});
  }

  void goBackFolder() {
    if (navigationStack.isEmpty) return;

    navigationStack.removeLast();

    if (navigationStack.isEmpty) {
      currentNodes = widget.routesTree;
    } else {
      currentNodes = navigationStack.last.children;
    }

    selectedNode = null;
    setState(() {});
  }

  String getCurrentPathView() {
    if (navigationStack.isEmpty) return "المسارات";
    return navigationStack.map((e) => e.title).join(" / ");
  }

  void confirmSelection() {
    if (selectedNode == null || !selectedNode!.isPage) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("يرجى اختيار صفحة أولاً")));
      return;
    }

    Navigator.pop(context, {
      "title": selectedNode!.title,
      "path": selectedNode!.path,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("اختيار مسار الإشعار"),
        centerTitle: true,
        backgroundColor: Colors.greenAccent[200],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.greenAccent),
              ),
              child: Text(
                getCurrentPathView(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (navigationStack.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: goBackFolder,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("رجوع"),
                ),
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(10),
              itemCount: currentNodes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final node = currentNodes[index];
                final isSelected = selectedNode == node;

                return GestureDetector(
                  onTap: () {
                    if (node.isFolder) {
                      openFolder(node);
                    } else {
                      selectedNode = node;
                      setState(() {});
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.greenAccent.withValues(alpha: 0.18)
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.green : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          node.isFolder ? Icons.folder : Icons.description,
                          color: node.isFolder
                              ? Colors.amber
                              : Colors.blueAccent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            node.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (node.isFolder)
                          const Icon(Icons.keyboard_double_arrow_right),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: confirmSelection,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              "تأكيد الاختيار",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
