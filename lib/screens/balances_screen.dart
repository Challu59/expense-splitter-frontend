import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BalancesScreen extends StatefulWidget {
  final int groupId;
  final String groupName;

  const BalancesScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<BalancesScreen> createState() => _BalancesScreenState();
}

class _BalancesScreenState extends State<BalancesScreen> {
  bool loading = true;
  String currency = "NPR";
  List balances = [];
  List settlements = [];
  List settlementHistory = [];
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    fetchBalances();
  }

  Future<void> _loadCurrentUser() async {
    currentUserId = await ApiService.getCurrentUserId();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> fetchBalances() async {
    setState(() => loading = true);
    try {
      final data = await ApiService.getGroupBalances(widget.groupId);
      setState(() {
        currency = data["currency"] ?? "NPR";
        balances = data["balances"] ?? [];
        settlements = data["settlements"] ?? [];
        settlementHistory = data["settlement_history"] ?? [];
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load balances: $e")),
      );
    }
  }

  String _formatMoney(dynamic value) {
    final number = (value is num) ? value : num.tryParse(value.toString()) ?? 0;
    return "$currency ${number.toStringAsFixed(2)}";
  }

  Future<void> _showSettleDialog() async {
    if (currentUserId == null) return;

    final amountController = TextEditingController();
    int? selectedToUser;

    final receivers = balances.where((b) {
      final uid = b["user_id"];
      final net = b["net_balance"] ?? 0;
      return uid != currentUserId && net is num && net > 0;
    }).toList();

    if (receivers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No pending payables for you in this group")),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text("Record Settlement"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedToUser,
                    decoration: const InputDecoration(labelText: "Pay To"),
                    items: receivers
                        .map(
                          (r) => DropdownMenuItem<int>(
                            value: r["user_id"] as int,
                            child: Text(
                              "${r["name"]} (owed ${_formatMoney(r["net_balance"] ?? 0)})",
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setModalState(() => selectedToUser = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: "Amount"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedToUser == null || amountController.text.trim().isEmpty) {
                      return;
                    }
                    final error = await ApiService.createSettlement(
                      groupId: widget.groupId,
                      toUserId: selectedToUser!,
                      amount: amountController.text.trim(),
                    );
                    if (!mounted) return;
                    if (error == null) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Settlement recorded")),
                      );
                      fetchBalances();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.groupName} Balances")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSettleDialog,
        icon: const Icon(Icons.payments),
        label: const Text("Settle"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchBalances,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    "Net Balances",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...balances.map((item) {
                    final net = (item["net_balance"] ?? 0) as num;
                    final isPositive = net > 0;
                    final isNegative = net < 0;
                    return Card(
                      child: ListTile(
                        title: Text(item["name"] ?? "Unknown"),
                        subtitle: Text(
                          isPositive
                              ? "Should receive"
                              : isNegative
                                  ? "Should pay"
                                  : "Settled",
                        ),
                        trailing: Text(
                          _formatMoney(net.abs()),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPositive
                                ? Colors.green
                                : isNegative
                                    ? Colors.red
                                    : Colors.grey,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 18),
                  const Text(
                    "Who Owes Whom",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (settlements.isEmpty)
                    const Card(
                      child: ListTile(
                        title: Text("All balances are settled"),
                      ),
                    )
                  else
                    ...settlements.map((item) {
                      final fromUser = balances.firstWhere(
                        (b) => b["user_id"] == item["from_user"],
                        orElse: () => {"name": "Unknown"},
                      );
                      final toUser = balances.firstWhere(
                        (b) => b["user_id"] == item["to_user"],
                        orElse: () => {"name": "Unknown"},
                      );
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.payments_outlined),
                          title: Text("${fromUser["name"]} -> ${toUser["name"]}"),
                          trailing: Text(
                            _formatMoney(item["amount"] ?? 0),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      );
                    }).toList(),
                  const SizedBox(height: 18),
                  const Text(
                    "Settlement History",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (settlementHistory.isEmpty)
                    const Card(
                      child: ListTile(
                        title: Text("No settlements recorded yet"),
                      ),
                    )
                  else
                    ...settlementHistory.map((item) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(
                            "${item["from_user_name"]} paid ${item["to_user_name"]}",
                          ),
                          subtitle: Text(item["date"]?.toString() ?? ""),
                          trailing: Text(
                            _formatMoney(item["amount"] ?? 0),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
    );
  }
}
