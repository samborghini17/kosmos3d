import 'package:flutter/material.dart';

class ProjectFlowScreen extends StatefulWidget {
  const ProjectFlowScreen({super.key});

  @override
  State<ProjectFlowScreen> createState() => _ProjectFlowScreenState();
}

class _ProjectFlowScreenState extends State<ProjectFlowScreen> {
  int _currentStep = 0;
  bool _isRecording = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neues Projekt'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 3) {
            setState(() => _currentStep++);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        controlsBuilder: (BuildContext context, ControlsDetails details) {
          final isLastStep = _currentStep == 3;
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                if (!isLastStep)
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: const Text('Weiter'),
                  ),
                if (isLastStep)
                  ElevatedButton(
                    onPressed: () {
                      // Finalize Project / Start processing
                      Navigator.pop(context);
                    },
                    child: const Text('Fertigstellen'),
                  ),
                const SizedBox(width: 8),
                if (_currentStep > 0 && !isLastStep)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Zurück', style: TextStyle(color: Colors.white70)),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Name', style: TextStyle(color: Colors.white)),
            content: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Projektname vergeben',
                border: OutlineInputBorder(),
              ),
            ),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('Projekt Einstellungen', style: TextStyle(color: Colors.white)),
            content: Column(
              children: [
                SwitchListTile(
                  title: const Text('Videos aufzeichnen'),
                  value: true,
                  onChanged: (bool value) {},
                ),
                SwitchListTile(
                  title: const Text('Einzelbilder'),
                  value: false,
                  onChanged: (bool value) {},
                ),
                SwitchListTile(
                  title: const Text('Smart Image Capture (AI)'),
                  subtitle: const Text('Hilft beim intelligenten Auslösen'),
                  value: true,
                  onChanged: (bool value) {},
                ),
              ],
            ),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('Kamera Settings', style: TextStyle(color: Colors.white)),
            content: ListTile(
              title: const Text('Aktuelle Kameras: 2 verbunden'),
              trailing: ElevatedButton(
                onPressed: () {
                  // Open specific config page layout
                },
                child: const Text('Anpassen'),
              ),
            ),
            isActive: _currentStep >= 2,
          ),
          Step(
            title: const Text('Aufnahme & Sync', style: TextStyle(color: Colors.white)),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isRecording ? Icons.pause_circle_filled : Icons.play_circle_fill,
                        color: _isRecording ? Colors.amber : Theme.of(context).primaryColor,
                      ),
                      iconSize: 64,
                      onPressed: () {
                        setState(() {
                          _isRecording = !_isRecording;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.stop_circle, color: Colors.redAccent),
                      iconSize: 64,
                      onPressed: () {
                        if (_isRecording) {
                          setState(() {
                            _isRecording = false;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Medienübertragung', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const LinearProgressIndicator(value: 0.0), // Placeholder for Sync Progress
                const SizedBox(height: 8),
                const Center(child: Text('Warte auf Aufzeichnung...', style: TextStyle(color: Colors.white54))),
              ],
            ),
            isActive: _currentStep >= 3,
          ),
        ],
      ),
    );
  }
}
