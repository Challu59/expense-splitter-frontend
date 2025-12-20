import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GroupsScreen extends StatefulWidget{
  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>{
  List groups = [];
  bool loading = true;
  void showInviteSheet(int groupId) {
    final emailController = TextEditingController();
    bool inviting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Invite Member",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "User Email",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  inviting
                      ? const CircularProgressIndicator()
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      child: const Text("Invite"),
                      onPressed: () async {
                        setModalState(() => inviting = true);

                        final error =
                        await ApiService.inviteToGroup(
                          groupId,
                          emailController.text.trim(),
                        );

                        setModalState(() => inviting = false);

                        if (error == null) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("User invited successfully"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
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
      builder: (_) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Create Group",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Group Name"),
              ),
              TextField(
                controller: currencyController,
                decoration: const InputDecoration(labelText: "Currency"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final success = await ApiService.createGroup(
                    nameController.text,
                    currencyController.text,
                  );

                  if (success) {
                    Navigator.pop(context);
                    fetchGroups(); // refresh list
                  }
                },
                child: const Text("Create"),
              ),
            ],
          ),
        );
      },
    );
  }


  @override
  void initState() {
    super.initState();
    fetchGroups();
  }

  Future<void> fetchGroups() async{
    final data = await ApiService.getGroups();
    setState(() {
      groups = data;
      loading = false;
    });

  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Groups"),),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: showCreateGroupSheet
      ),
      body: loading?
      const Center(
        child: CircularProgressIndicator(),
      ): ListView.builder(
          itemCount: groups.length,
          itemBuilder: (context,index){
            final group = groups[index];
            // return Card(
            //   child: ListTile(
            //     title: Text(group["name"]),
            //     subtitle: Text(
            //       "${group['members_count']} members"
            //     ),
            //     onTap: (){
            //       // group details ui
            //     },
            //   ),
            // );

            return Card(
              child: ListTile(
                title: Text(group["name"]),
                subtitle: Text("${group['members_count']} members"),
                trailing: IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: () {
                    showInviteSheet(group["id"]);
                  },
                ),
              ),
            );

          })
      ,
    );
  }

}
