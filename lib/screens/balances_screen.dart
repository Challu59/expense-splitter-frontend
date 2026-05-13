import 'package:flutter/material.dart';
import '../services/api_service.dart';

int _intFromJson(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value.toString()) ?? 0;
}

num _numFromJson(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  return num.tryParse(value.toString()) ?? 0;
}

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
  List<dynamic> balances = [];
  List<dynamic> settlements = [];
  List<dynamic> settlementHistory = [];
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
      if (!mounted) return;
      setState(() {
        currency = data["currency"] as String? ?? "NPR";
        balances = data["balances"] as List<dynamic>? ?? [];
        settlements = data["settlements"] as List<dynamic>? ?? [];
        settlementHistory = data["settlement_history"] as List<dynamic>? ?? [];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load balances: $e")),
      );
    }
  }

  String _formatMoney(dynamic value) {
    final number = _numFromJson(value);
    return "$currency ${number.toStringAsFixed(2)}";
  }

  String _formatSettlementDate(dynamic raw) {
    if (raw == null) return "";
    final s = raw.toString();
    final dt = DateTime.tryParse(s);
    if (dt == null) return s;
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, "0");
    final d = dt.day.toString().padLeft(2, "0");
    final h = dt.hour.toString().padLeft(2, "0");
    final min = dt.minute.toString().padLeft(2, "0");
    return "$y-$m-$d $h:$min";
  }

  String _nameForUserId(int userId) {
    for (final b in balances) {
      if (b is Map && _intFromJson(b["user_id"]) == userId) {
        return (b["name"] as String?) ?? "Unknown";
      }
    }
    return "Unknown";
  }

  Future<void> _showSettleDialog() async {
    try {
      int? uid = currentUserId;
      if (uid == null) {
        uid = await ApiService.getCurrentUserId();
        if (mounted) {
          setState(() => currentUserId = uid);
        }
      }
      if (uid == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Could not load your account. Log out and log in again to record settlements.",
            ),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      final receivers = balances.where((b) {
        if (b is! Map) return false;
        final otherId = _intFromJson(b["user_id"]);
        if (otherId == uid) return false;
        return _numFromJson(b["net_balance"]) > 0;
      }).toList();

      if (receivers.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "You are not paying anyone in this group right now. "
              "Only members who owe money can record a settlement to someone who is owed.",
            ),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      final amountController = TextEditingController();
      final noteController = TextEditingController();
      bool submitting = false;

      try {
        if (!mounted) return;
        await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          int? selectedToUser;
          return StatefulBuilder(
            builder: (context, setModalState) {
              return AlertDialog(
                title: const Text("Record settlement"),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "Pay to",
                          border: OutlineInputBorder(),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            hint: const Text("Select recipient"),
                            value: selectedToUser,
                            items: receivers
                                .map((r) {
                                  if (r is! Map) return null;
                                  final id = _intFromJson(r["user_id"]);
                                  return DropdownMenuItem<int>(
                                    value: id,
                                    child: Text(
                                      "${r["name"] ?? "Unknown"} (owed ${_formatMoney(r["net_balance"])})",
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                })
                                .whereType<DropdownMenuItem<int>>()
                                .toList(),
                            onChanged: submitting
                                ? null
                                : (value) => setModalState(() => selectedToUser = value),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        enabled: !submitting,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: "Amount",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteController,
                        enabled: !submitting,
                        maxLines: 2,
                        maxLength: 255,
                        decoration: const InputDecoration(
                          labelText: "Note (optional)",
                          hintText: "e.g. Cash, UPI reference",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: submitting ? null : () => Navigator.pop(dialogContext),
                    child: const Text("Cancel"),
                  ),
                  FilledButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            if (selectedToUser == null ||
                                amountController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(content: Text("Choose recipient and amount")),
                              );
                              return;
                            }
                            setModalState(() => submitting = true);
                            final err = await ApiService.createSettlement(
                              groupId: widget.groupId,
                              toUserId: selectedToUser!,
                              amount: amountController.text.trim(),
                              note: noteController.text.trim().isEmpty
                                  ? null
                                  : noteController.text.trim(),
                            );
                            if (!dialogContext.mounted) return;
                            if (err == null) {
                              Navigator.pop(dialogContext);
                              if (!mounted) return;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Settlement recorded")),
                                );
                                fetchBalances();
                              });
                            } else {
                              setModalState(() => submitting = false);
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text(err)),
                              );
                            }
                          },
                    child: submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Save"),
                  ),
                ],
              );
            },
          );
        },
      );
      } finally {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          amountController.dispose();
          noteController.dispose();
        });
      }
    } catch (e, st) {
      assert(() {
        debugPrint("Settle dialog error: $e\n$st");
        return true;
      }());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not open settlement: $e"),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.groupName} - Balances"),
      ),
      floatingActionButton: loading
          ? null
          : FloatingActionButton.extended(
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
                    "Net balances",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...balances.map((item) {
                    if (item is! Map) return const SizedBox.shrink();
                    final net = _numFromJson(item["net_balance"]);
                    final isPositive = net > 0;
                    final isNegative = net < 0;
                    return Card(
                      child: ListTile(
                        title: Text(item["name"]?.toString() ?? "Unknown"),
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
                  }),
                  const SizedBox(height: 18),
                  const Text(
                    "Who owes whom",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (settlements.isEmpty)
                    const Card(
                      child: ListTile(
                        title: Text("All suggested transfers are settled"),
                      ),
                    )
                  else
                    ...settlements.map((item) {
                      if (item is! Map) return const SizedBox.shrink();
                      final fromId = _intFromJson(item["from_user"]);
                      final toId = _intFromJson(item["to_user"]);
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.swap_horiz),
                          title: Text("${_nameForUserId(fromId)} → ${_nameForUserId(toId)}"),
                          trailing: Text(
                            _formatMoney(item["amount"]),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 18),
                  const Text(
                    "Settlement history",
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
                      if (item is! Map) return const SizedBox.shrink();
                      final note = item["note"]?.toString().trim() ?? "";
                      final dateStr = _formatSettlementDate(item["date"]);
                      return Card(
                        child: ListTile(
                          isThreeLine: note.isNotEmpty,
                          leading: const Icon(Icons.history),
                          title: Text(
                            "${item["from_user_name"] ?? "?"} paid ${item["to_user_name"] ?? "?"}",
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (dateStr.isNotEmpty) Text(dateStr),
                              if (note.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text("Note: $note"),
                                ),
                            ],
                          ),
                          trailing: Text(
                            _formatMoney(item["amount"]),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
