import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:karaoke/src/services/theme_service.dart';

final class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final themeService = ThemeService.getInstance();
  final _primaryColorCtrl = TextEditingController();
  final _secondaryColorCtrl = TextEditingController();
  final _backgroundColorCtrl = TextEditingController();
  final _cardColorCtrl = TextEditingController();
  final _textColorCtrl = TextEditingController();
  final _accentColorCtrl = TextEditingController();
  final _fontFamilyCtrl = TextEditingController();
  final _titleSizeCtrl = TextEditingController();
  final _scoreSizeCtrl = TextEditingController();
  final _timerSizeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    themeService.addListener(_onUpdate);
    _loadValues();
  }

  @override
  void dispose() {
    themeService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    setState(() => _loadValues());
  }

  void _loadValues() {
    _primaryColorCtrl.text = themeService.primaryColor;
    _secondaryColorCtrl.text = themeService.secondaryColor;
    _backgroundColorCtrl.text = themeService.backgroundColor;
    _cardColorCtrl.text = themeService.cardColor;
    _textColorCtrl.text = themeService.textColor;
    _accentColorCtrl.text = themeService.accentColor;
    _fontFamilyCtrl.text = themeService.fontFamily;
    _titleSizeCtrl.text = themeService.titleFontSize.toInt().toString();
    _scoreSizeCtrl.text = themeService.scoreFontSize.toInt().toString();
    _timerSizeCtrl.text = themeService.timerFontSize.toInt().toString();
  }

  Future<void> _uploadImage(String key) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result?.files.single.bytes != null) {
      final bytes = result!.files.single.bytes!;
      final filename = result.files.single.name;
      final url = await themeService.uploadImage(bytes, filename);
      if (url != null) {
        await themeService.saveSettings({key: url});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image uploaded!')));
      }
    }
  }

  Future<void> _saveSettings() async {
    await themeService.saveSettings({
      'primaryColor': _primaryColorCtrl.text,
      'secondaryColor': _secondaryColorCtrl.text,
      'backgroundColor': _backgroundColorCtrl.text,
      'cardColor': _cardColorCtrl.text,
      'textColor': _textColorCtrl.text,
      'accentColor': _accentColorCtrl.text,
      'fontFamily': _fontFamilyCtrl.text,
      'titleFontSize': _titleSizeCtrl.text,
      'scoreFontSize': _scoreSizeCtrl.text,
      'timerFontSize': _timerSizeCtrl.text,
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Customization')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Colors', [
            _colorField('Primary Color', _primaryColorCtrl),
            _colorField('Secondary Color', _secondaryColorCtrl),
            _colorField('Background Color', _backgroundColorCtrl),
            _colorField('Card Color', _cardColorCtrl),
            _colorField('Text Color', _textColorCtrl),
            _colorField('Accent Color', _accentColorCtrl),
          ]),
          const SizedBox(height: 16),
          _section('Fonts', [
            TextField(controller: _fontFamilyCtrl, decoration: const InputDecoration(labelText: 'Font Family (e.g., Roboto, Arial)')),
            TextField(controller: _titleSizeCtrl, decoration: const InputDecoration(labelText: 'Title Font Size'), keyboardType: TextInputType.number),
            TextField(controller: _scoreSizeCtrl, decoration: const InputDecoration(labelText: 'Score Font Size'), keyboardType: TextInputType.number),
            TextField(controller: _timerSizeCtrl, decoration: const InputDecoration(labelText: 'Timer Font Size'), keyboardType: TextInputType.number),
          ]),
          const SizedBox(height: 16),
          _section('Images', [
            ElevatedButton(onPressed: () => _uploadImage('backgroundImageUrl'), child: const Text('Upload Background Image')),
            ElevatedButton(onPressed: () => _uploadImage('logoImageUrl'), child: const Text('Upload Logo Image')),
            if (themeService.backgroundImageUrl != null) ...[
              const SizedBox(height: 8),
              Text('Background: ${themeService.backgroundImageUrl}'),
            ],
            if (themeService.logoImageUrl != null) ...[
              const SizedBox(height: 8),
              Text('Logo: ${themeService.logoImageUrl}'),
            ],
          ]),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _saveSettings, child: const Text('Save All Settings')),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF11182b), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _colorField(String label, TextEditingController ctrl) {
    return Row(children: [
      Expanded(child: TextField(controller: ctrl, decoration: InputDecoration(labelText: label))),
      const SizedBox(width: 8),
      Container(width: 40, height: 40, decoration: BoxDecoration(color: _parseColor(ctrl.text), border: Border.all(), borderRadius: BorderRadius.circular(4))),
    ]);
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.white;
    }
  }
}
