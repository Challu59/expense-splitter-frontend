import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'add_expense_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final int groupId;
  final String groupName;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  bool loading = true;

  List expenses = [];
  List members = [];
  double totalExpense = 0;

  @override
  void initState() {
    super.initState();
    fetchGroupData();
  }

  Future<void> fetchGroupData() async {
    try {
      final groupData =
      await ApiService.getGroupDetail(widget.groupId);
      final expenseData =
      await ApiService.getGroupExpenses(widget.groupId);

      double total = 0;
      for (var e in expenseData) {
        total += double.parse(e["amount"].toString());
      }

      setState(() {
        members = groupData["members"] ?? [];
        expenses = expenseData;
        totalExpense = total;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load group details")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpenseScreen(groupId: widget.groupId),
            ),
          );

          if (added == true) {
            fetchGroupData();
          }
        },
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.groupName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    "Members (${members.length})",
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    children: members.map<Widget>((m) {
                      return Chip(
                        label: Text(m["username"]),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "Total Expense: Rs. $totalExpense",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// EXPENSE LIST
          Expanded(
            child: expenses.isEmpty
                ? const Center(
              child: Text(
                "No expenses yet.\nTap + to add one",
                textAlign: TextAlign.center,
              ),
            )
                : ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(expense["description"]),
                    subtitle: Text(
                      "Paid by ${expense["paid_by_name"]}",
                    ),
                    trailing: Text(
                      "Rs. ${expense["amount"]}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
