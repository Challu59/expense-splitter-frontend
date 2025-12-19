import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GroupsScreen extends StatefulWidget{
  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>{
  List groups = [];
  bool loading = true;

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
            return Card(
              child: ListTile(
                title: Text(group["name"]),
                subtitle: Text(
                  "${group['members_count']} members"
                ),
                onTap: (){
                  // group details ui
                },
              ),
            );

          })
      ,
    );
  }

}
