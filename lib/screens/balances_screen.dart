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

  @override
  void initState() {
    super.initState();
    fetchBalances();
  }

  Future<void> fetchBalances() async {
    setState(() => loading = true);
    try {
      final data = await ApiService.getGroupBalances(widget.groupId);
      setState(() {
        currency = data["currency"] ?? "NPR";
        balances = data["balances"] ?? [];
        settlements = data["settlements"] ?? [];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.groupName} Balances")),
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
                ],
              ),
            ),
    );
  }
}
