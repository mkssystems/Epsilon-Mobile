import 'package:flutter/material.dart';

class CreateGameSessionDialog extends StatefulWidget {
  final Function(int size, String scenario, int maxPlayers) onCreate;

  const CreateGameSessionDialog({super.key, required this.onCreate});

  @override
  _CreateGameSessionDialogState createState() => _CreateGameSessionDialogState();
}

class _CreateGameSessionDialogState extends State<CreateGameSessionDialog> {
  final List<String> scenarioOptions = ['Epsilon267-Fulcrum Incident'];
  String selectedScenario = 'Epsilon267-Fulcrum Incident';
  int selectedSize = 6;
  int selectedMaxPlayers = 4;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Create Game Session"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Scenario"),
            value: selectedScenario,
            items: scenarioOptions
                .map((scenario) => DropdownMenuItem(value: scenario, child: Text(scenario)))
                .toList(),
            onChanged: (value) => setState(() => selectedScenario = value!),
          ),
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: "Map Size"),
            value: selectedSize,
            items: List.generate(7, (i) => i + 4)
                .map((size) => DropdownMenuItem(value: size, child: Text(size.toString())))
                .toList(),
            onChanged: (value) => setState(() => selectedSize = value!),
          ),
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: "Max Players"),
            value: selectedMaxPlayers,
            items: List.generate(6, (i) => i + 1)
                .map((count) => DropdownMenuItem(value: count, child: Text(count.toString())))
                .toList(),
            onChanged: (value) => setState(() => selectedMaxPlayers = value!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onCreate(selectedSize, selectedScenario, selectedMaxPlayers);
            Navigator.pop(context);
          },
          child: const Text("Create"),
        ),
      ],
    );
  }
}
