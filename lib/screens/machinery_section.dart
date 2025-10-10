import 'package:flutter/material.dart';
import '../services/master_service.dart';

class MachinerySection extends StatefulWidget {
  final bool isUpdateMode;
  final List<int> selectedIds;
  final Function(List<int>) onSelectionChanged;

  const MachinerySection({
    super.key,
    required this.isUpdateMode,
    required this.selectedIds,
    required this.onSelectionChanged,
  });

  @override
  State<MachinerySection> createState() => _MachinerySectionState();
}

class _MachinerySectionState extends State<MachinerySection> {
  Map<int, String> machineries = {};
  late Set<int> selectedMachineries;

  @override
  void initState() {
    super.initState();
    selectedMachineries = widget.selectedIds.toSet();
    _loadMachineries();
  }

  Future<void> _loadMachineries() async {
    final data = await MasterService.getMachineries(); // ✅ Wrapper call
    setState(() {
      machineries = data;
    });
  }

  String get selectedMachineryNames =>
      selectedMachineries.map((id) => machineries[id] ?? "").join(", ");

  @override
  Widget build(BuildContext context) {
    if (machineries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Machinery", style: TextStyle(fontWeight: FontWeight.bold)),
        ...machineries.entries.map((entry) {
          return CheckboxListTile(
            title: Text(entry.value),
            value: selectedMachineries.contains(entry.key),
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  selectedMachineries.add(entry.key);
                } else {
                  selectedMachineries.remove(entry.key);
                }
              });
              widget.onSelectionChanged(selectedMachineries.toList());
            },
          );
        }),
        if (widget.isUpdateMode)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "Selected Machinery: $selectedMachineryNames",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }
}
