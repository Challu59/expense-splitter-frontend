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
  int totalExpense = 0;

  @override
  void initState() {
    super.initState();
    fetchGroupDetails();
  }

  Future<void> fetchGroupDetails() async {
    setState(() => loading = true);

    try {
      final groupData = await ApiService.getGroupDetail(widget.groupId);
      setState(() {
        members = groupData['members'] ?? [];
        totalExpense = groupData['total_expense'] ?? 0;
      });
    } catch (e) {
      setState(() {
        members = [];
        totalExpense = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load group details: ${e.toString()}")),
      );
    }

    try {
      final expenseData = await ApiService.getGroupExpenses(widget.groupId);
      setState(() {
        expenses = expenseData;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load expenses: ${e.toString()}")),
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
            fetchGroupDetails();
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
                    "Members (${members.length}): " +
                        members.map((m) => m['name'] ?? 'Unknown').join(', '),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Total Expense: Rs. $totalExpense",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

          // Expenses List
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
                    horizontal: 12,
                    vertical: 6,
                  ),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),

                    title: Text(
                      expense["description"] ?? "No description",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),

                        Text(
                          "Paid by ${expense["paid_by_name"] ?? "Unknown"}",
                          style: const TextStyle(fontSize: 13),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          "Split: ${(expense["split_type"] ?? "equal").toString().toUpperCase()}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    trailing: Text(
                      "Rs. ${expense["amount"] ?? "0.00"}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),

                    onTap: () {
                    },
                  ),
                );
              },
            ),
          )

        ],
      ),
    );
  }
}
