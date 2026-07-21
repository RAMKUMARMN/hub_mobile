// lib/mixins/workspace_aware.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workspace_provider.dart';
import '../models/workspace/workspace.dart';

mixin WorkspaceAware<T extends StatefulWidget> on State<T> {
  WorkspaceProvider? _workspaceProvider;
  
  WorkspaceProvider get workspaceProvider {
    _workspaceProvider ??= Provider.of<WorkspaceProvider>(context, listen: false);
    return _workspaceProvider!;
  }
  
  Workspace? get currentWorkspace => workspaceProvider.currentWorkspace;
  
  List<Workspace> get workspaces => workspaceProvider.workspaces;
  
  bool get hasWorkspace => currentWorkspace != null;
  
  void switchWorkspace(String workspaceId) {
    final workspace = workspaces.firstWhere((w) => w.id == workspaceId);
    workspaceProvider.selectWorkspace(workspace);
  }
  
  void refreshWorkspaces() async {
    await workspaceProvider.loadWorkspaces();
    if (mounted) setState(() {});
  }
  
  Future<bool> createWorkspace(String name, {String icon = '📁', Color color = Colors.blue}) async {
    return await workspaceProvider.createWorkspace(name, icon: icon, color: color);
  }
  
  Future<bool> updateCurrentWorkspace({String? name, String? icon, Color? color}) async {
    if (currentWorkspace == null) return false;
    return await workspaceProvider.updateWorkspace(
      currentWorkspace!.id,
      name: name,
      icon: icon,
      color: color,
    );
  }
  
  Future<bool> deleteCurrentWorkspace() async {
    if (currentWorkspace == null) return false;
    return await workspaceProvider.deleteWorkspace(currentWorkspace!.id);
  }
  
  void showWorkspaceSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Workspace', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...workspaces.map((workspace) => ListTile(
              leading: Text(workspace.icon, style: const TextStyle(fontSize: 24)),
              title: Text(workspace.name),
              trailing: currentWorkspace?.id == workspace.id
                  ? const Icon(Icons.check_circle, color: Colors.blue)
                  : null,
              onTap: () {
                switchWorkspace(workspace.id);
                Navigator.pop(context);
                if (mounted) setState(() {});
              },
            )),
          ],
        ),
      ),
    );
  }
}