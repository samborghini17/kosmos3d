import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/gopro_service.dart';
import '../services/project_service.dart';

import 'capture_session.dart';

class ProjectFlowScreen extends StatefulWidget {
  const ProjectFlowScreen({super.key});

  @override
  State<ProjectFlowScreen> createState() => _ProjectFlowScreenState();
}

class _ProjectFlowScreenState extends State<ProjectFlowScreen> {
  int _currentStep = 0;
  final _nameController = TextEditingController();
  String _captureMode = 'photo';
  bool _smartCapture = false;

  // Camera settings for the project
  String _resolution = '4K';
  String _fps = '30';
  String _lens = 'Linear';
  String _isoMax = '400';
  String _shutter = 'Auto';
  String _whiteBalance = '5500K';
  String _bitrate = 'High';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final goPro = context.watch<GoProService>();
    final connectedCams = goPro.devices.where((d) => d.isConnected).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(settings.translate('new_project')),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0 && _nameController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter a project name.')),
            );
            return;
          }
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            // Final step: Create the project and navigate to capture session
            _createProjectAndStart(context);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        controlsBuilder: (BuildContext context, ControlsDetails details) {
          final isLastStep = _currentStep == 2;
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  child: Text(isLastStep ? settings.translate('start_capture') : settings.translate('next')),
                ),
                const SizedBox(width: 8),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: Text(settings.translate('back'), style: const TextStyle(color: Colors.white70)),
                  ),
              ],
            ),
          );
        },
        steps: [
          // Step 1: Project Name & Mode
          Step(
            title: Text(settings.translate('project_name'), style: const TextStyle(color: Colors.white)),
            content: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: settings.translate('enter_project_name'),
                    border: const OutlineInputBorder(),
                    hintText: 'e.g. Living Room Scan',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                ),
                const SizedBox(height: 16),
                // Capture Mode Selection
                Text(settings.translate('capture_mode'), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildModeChip('photo', Icons.photo_camera, settings.translate('single_frames')),
                    const SizedBox(width: 8),
                    _buildModeChip('video', Icons.videocam, settings.translate('record_videos')),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(settings.translate('smart_capture')),
                  subtitle: Text(settings.translate('smart_capture_desc'), style: const TextStyle(color: Colors.white54)),
                  value: _smartCapture,
                  activeTrackColor: Theme.of(context).primaryColor,
                  onChanged: (bool value) {
                    setState(() => _smartCapture = value);
                  },
                ),
              ],
            ),
            isActive: _currentStep >= 0,
          ),

          // Step 2: Camera Settings
          Step(
            title: Text(settings.translate('camera_settings'), style: const TextStyle(color: Colors.white)),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (connectedCams.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            settings.translate('no_cameras_warning'),
                            style: const TextStyle(color: Colors.orange, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Theme.of(context).primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${connectedCams.length} camera${connectedCams.length > 1 ? 's' : ''} connected',
                          style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                _buildSettingDropdown('Resolution', _resolution, ['1080p', '2.7K', '4K', '5.3K'], (v) => setState(() => _resolution = v)),
                _buildSettingDropdown('FPS', _fps, ['24', '30', '60', '120'], (v) => setState(() => _fps = v)),
                _buildSettingDropdown('Lens', _lens, ['Linear', 'Wide', 'SuperView'], (v) => setState(() => _lens = v)),
                _buildSettingDropdown('ISO Max', _isoMax, ['100', '200', '400', '800', '1600'], (v) => setState(() => _isoMax = v)),
                _buildSettingDropdown('Shutter', _shutter, ['Auto', '1/60', '1/120', '1/240', '1/480'], (v) => setState(() => _shutter = v)),
                _buildSettingDropdown('White Balance', _whiteBalance, ['Auto', '3200K', '4000K', '5500K', '6500K'], (v) => setState(() => _whiteBalance = v)),
                _buildSettingDropdown('Bitrate', _bitrate, ['Standard', 'High'], (v) => setState(() => _bitrate = v)),
              ],
            ),
            isActive: _currentStep >= 1,
          ),

          // Step 3: Summary & Start
          Step(
            title: Text(settings.translate('summary'), style: const TextStyle(color: Colors.white)),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow(Icons.folder, 'Project', _nameController.text.isEmpty ? '—' : _nameController.text),
                _buildSummaryRow(Icons.camera, 'Mode', _captureMode == 'photo' ? 'Single Frames' : 'Video'),
                _buildSummaryRow(Icons.aspect_ratio, 'Resolution', _resolution),
                _buildSummaryRow(Icons.speed, 'FPS', _fps),
                _buildSummaryRow(Icons.camera_alt, 'Lens', _lens),
                _buildSummaryRow(Icons.linked_camera, 'Cameras', '${connectedCams.length} connected'),
                const SizedBox(height: 12),
                Text(
                  settings.translate('start_capture_hint'),
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            isActive: _currentStep >= 2,
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(String mode, IconData icon, String label) {
    final isSelected = _captureMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _captureMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Theme.of(context).primaryColor : Colors.white24,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.white54, size: 28),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingDropdown(String label, String currentValue, List<String> options, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currentValue,
                  dropdownColor: const Color(0xFF2A2A2A),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  isExpanded: true,
                  items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                  onChanged: (v) { if (v != null) onChanged(v); },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _createProjectAndStart(BuildContext context) async {
    final projectService = context.read<ProjectService>();
    final goPro = context.read<GoProService>();

    final cameraSettings = {
      'Resolution': _resolution,
      'FPS': _fps,
      'Lens': _lens,
      'ISO Max': _isoMax,
      'Shutter': _shutter,
      'White Balance': _whiteBalance,
      'Bitrate': _bitrate,
    };

    // Show a loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Applying settings to cameras...'), duration: Duration(seconds: 2)),
      );
    }

    // 1. Switch all cameras to the correct mode (Photo or Video)
    await goPro.setAllCamerasMode(_captureMode);

    // 2. Apply all individual settings via BLE
    await goPro.applySettingsToAll(cameraSettings);

    // 3. Update local state
    for (final cam in goPro.devices.where((d) => d.isConnected)) {
      goPro.updateCameraSettings(cam.id, cameraSettings);
    }

    final project = await projectService.createProject(
      _nameController.text.trim(),
      captureMode: _captureMode,
      smartCapture: _smartCapture,
      cameraSettings: cameraSettings,
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CaptureSessionScreen(project: project)),
      );
    }
  }
}
