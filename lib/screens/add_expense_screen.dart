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

  String splitType = "equal";
  bool loading = false;

  Future<void> addExpense() async {
    setState(() => loading = true);

    final error = await ApiService.addExpense(
      groupId: widget.groupId,
      amount: amountController.text,
      description: descriptionController.text,
      splitType: splitType,
    );

    setState(() => loading = false);

    if (error == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Expense added successfully")),
      );
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
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
                DropdownMenuItem(value: "percentage", child: Text("Percentage")),
              ],
              onChanged: (value) {
                setState(() => splitType = value!);
              },
            ),

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
