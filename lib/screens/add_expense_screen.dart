import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final int groupId;

  const AddExpenseScreen({super.key, required this.groupId});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  final Map<int, TextEditingController> splitControllers = {};

  String splitType = "equal";
  bool loading = false;
  bool loadingMembers = true;
  List members = [];

  @override
  void initState() {
    super.initState();
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    try {
      final groupData = await ApiService.getGroupDetail(widget.groupId);
      setState(() {
        members = groupData['members'] ?? [];
        for (var member in members) {
          splitControllers[member['user_id']] = TextEditingController();
        }
        loadingMembers = false;
      });
    } catch (e) {
      setState(() => loadingMembers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load members")),
      );
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    for (var controller in splitControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<Map<String, dynamic>> buildSplits() {
    List<Map<String, dynamic>> splits = [];
    for (var member in members) {
      final userId = member['user_id'];
      final controller = splitControllers[userId];
      if (controller != null && controller.text.isNotEmpty) {
        splits.add({
          "user": userId,
          "value": controller.text,
        });
      }
    }
    return splits;
  }

  Future<void> addExpense() async {
    if (amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter amount")),
      );
      return;
    }

    if (descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter description")),
      );
      return;
    }

    if (splitType == "custom" || splitType == "percentage") {
      bool allFilled = true;
      for (var member in members) {
        final controller = splitControllers[member['user_id']];
        if (controller == null || controller.text.isEmpty) {
          allFilled = false;
          break;
        }
      }
      if (!allFilled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              splitType == "custom"
                  ? "Please enter amount for all members"
                  : "Please enter percentage for all members",
            ),
          ),
        );
        return;
      }
    }

    setState(() => loading = true);

    List<Map<String, dynamic>> splits = [];
    if (splitType == "custom" || splitType == "percentage") {
      splits = buildSplits();
    }

    final error = await ApiService.addExpense(
      groupId: widget.groupId,
      amount: amountController.text,
      description: descriptionController.text,
      splitType: splitType,
      splits: splits,
    );

    setState(() => loading = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Expense added successfully")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Expense")),
      body: loadingMembers
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: "Amount"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: "Description"),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField(
                    value: splitType,
                    decoration: const InputDecoration(labelText: "Split Type"),
                    items: const [
                      DropdownMenuItem(value: "equal", child: Text("Equal")),
                      DropdownMenuItem(value: "custom", child: Text("Custom")),
                      DropdownMenuItem(
                          value: "percentage", child: Text("Percentage")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        splitType = value!;
                        for (var controller in splitControllers.values) {
                          controller.clear();
                        }
                      });
                    },
                  ),
                  if (splitType == "custom" || splitType == "percentage") ...[
                    const SizedBox(height: 24),
                    Text(
                      splitType == "custom"
                          ? "Enter amount for each member:"
                          : "Enter percentage for each member:",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...members.map((member) {
                      final userId = member['user_id'];
                      final controller = splitControllers[userId];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: "${member['name']} (${splitType == "custom" ? "Amount" : "Percentage"})",
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      );
                    }).toList(),
                    if (splitType == "percentage")
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          "Total must equal 100%",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (splitType == "custom")
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          "Total must equal expense amount",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 24),
                  loading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: addExpense,
                            child: const Text("Add Expense"),
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}
