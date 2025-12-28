import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends StatefulWidget {
  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List groups = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchGroups();
  }


  Future<void> fetchGroups() async {
    setState(() => loading = true);
    final data = await ApiService.getGroups();
    setState(() {
      groups = data;
      loading = false;
    });
  }

  void showInviteSheet(int groupId) {
    final emailController = TextEditingController();
    bool inviting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Invite Member",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text("Enter their email to add them to the group",
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "User Email",
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 24),
                  inviting
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: () async {
                      if (emailController.text.isEmpty) return;
                      setModalState(() => inviting = true);

                      final error = await ApiService.inviteToGroup(
                          groupId, emailController.text.trim()
                      );

                      setModalState(() => inviting = false);

                      if (error == null) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("User invited successfully"), backgroundColor: Colors.green),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
                        );
                      }
                    },
                    child: const Text("Send Invitation"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void showCreateGroupSheet() {
    final nameController = TextEditingController();
    final currencyController = TextEditingController(text: "NPR");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("New Expense Group",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Group Name",
                  prefixIcon: Icon(Icons.group_outlined),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: currencyController,
                decoration: const InputDecoration(
                  labelText: "Currency (e.g. NPR, USD)",
                  prefixIcon: Icon(Icons.currency_exchange),
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty) return;
                  final success = await ApiService.createGroup(
                    nameController.text,
                    currencyController.text,
                  );
                  if (success) {
                    Navigator.pop(context);
                    fetchGroups();
                  }
                },
                child: const Text("Create Group"),
              ),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("My Groups",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Color(0xFFD32F2F)),
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: fetchGroups,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD32F2F),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: showCreateGroupSheet,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : groups.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: fetchGroups,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            return _buildGroupCard(groups[index]);
          },
        ),
      ),
    );
  }

  Widget _buildGroupCard(Map group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFD32F2F).withOpacity(0.1),
          child: const Icon(Icons.groups_outlined, color: Color(0xFFD32F2F)),
        ),
        title: Text(
          group["name"],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        subtitle: Text("${group['members_count']} members • ${group['currency'] ?? 'NPR'}"),
        trailing: group["is_creator"] == true
            ? IconButton(
          icon: const Icon(Icons.person_add_alt_1, color: Color(0xFFD32F2F)),
          onPressed: () => showInviteSheet(group["id"]),
        )
            : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupDetailScreen(
                groupId: group["id"],
                groupName: group["name"],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No groups found",
              style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text("Tap + to create your first group",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}