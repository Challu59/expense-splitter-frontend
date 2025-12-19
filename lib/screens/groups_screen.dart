import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GroupsScreen extends StatefulWidget{
  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>{
  List groups = [];
  bool loading = true;

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
        onPressed: (){

          // Add group ui

        },
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
                  "${group[members_count]} members"
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
