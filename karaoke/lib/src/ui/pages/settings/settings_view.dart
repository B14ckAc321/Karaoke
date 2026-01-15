import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:karaoke/src/services/theme_service.dart';

final class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final themeService = ThemeService.getInstance();
  final _titleSizeCtrl = TextEditingController();
  final _scoreSizeCtrl = TextEditingController();
  final _timerSizeCtrl = TextEditingController();

  Color _primaryColor = Colors.pink;
  Color _secondaryColor = Colors.deepPurple;
  Color _backgroundColor = const Color(0xFF0b0f1a);
  Color _cardColor = const Color(0xFF11182b);
  Color _textColor = Colors.white;
  Color _accentColor = Colors.yellow;
  Color _buttonColor = Colors.blue;
  String _selectedFont = 'Roboto';

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
    _primaryColor = _parseColor(themeService.primaryColor);
    _secondaryColor = _parseColor(themeService.secondaryColor);
    _backgroundColor = _parseColor(themeService.backgroundColor);
    _cardColor = _parseColor(themeService.cardColor);
    _textColor = _parseColor(themeService.textColor);
    _accentColor = _parseColor(themeService.accentColor);
    _buttonColor = _parseColor(themeService.buttonColor);
    _selectedFont = themeService.fontFamily;
    _titleSizeCtrl.text = themeService.titleFontSize.toInt().toString();
    _scoreSizeCtrl.text = themeService.scoreFontSize.toInt().toString();
    _timerSizeCtrl.text = themeService.timerFontSize.toInt().toString();
  }

  Future<void> _uploadImage(String key) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result?.files.single.bytes != null) {
      final bytes = result!.files.single.bytes!;
      final filename = result.files.single.name;
      // Determine image type from key
      final imageType = key == 'logoImageUrl' ? 'logo' : 'background';
      final url = await themeService.uploadImage(bytes, filename, type: imageType);
      if (url != null) {
        // Save with the correct key name (backgroundImageUrl or logoImageUrl)
        final settingsMap = <String, String>{key: url};
        await themeService.saveSettings(settingsMap);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${imageType == 'logo' ? 'Logo' : 'Background'} image uploaded and replaced!'))
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image'))
          );
        }
      }
    }
  }

  String _colorToHex(Color color) {
    final argb = color.value; // Using value for hex conversion
    return '#${argb.toRadixString(16).substring(2).toUpperCase()}';
  }

  Future<void> _showColorPicker(String label, Color currentColor, void Function(Color) onColorChanged) async {
    Color selectedColor = currentColor;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pick $label'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: (color) => selectedColor = color,
            enableAlpha: false,
            displayThumbColor: true,
            paletteType: PaletteType.hslWithSaturation,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onColorChanged(selectedColor);
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    await themeService.saveSettings({
      'primaryColor': _colorToHex(_primaryColor),
      'secondaryColor': _colorToHex(_secondaryColor),
      'backgroundColor': _colorToHex(_backgroundColor),
      'cardColor': _colorToHex(_cardColor),
      'textColor': _colorToHex(_textColor),
      'accentColor': _colorToHex(_accentColor),
      'buttonColor': _colorToHex(_buttonColor),
      'fontFamily': _selectedFont,
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
            _colorPickerField('Primary Color', _primaryColor, (color) => setState(() => _primaryColor = color)),
            _colorPickerField('Secondary Color', _secondaryColor, (color) => setState(() => _secondaryColor = color)),
            _colorPickerField('Background Color', _backgroundColor, (color) => setState(() => _backgroundColor = color)),
            _colorPickerField('Card Color', _cardColor, (color) => setState(() => _cardColor = color)),
            _colorPickerField('Text Color', _textColor, (color) => setState(() => _textColor = color)),
            _colorPickerField('Accent Color', _accentColor, (color) => setState(() => _accentColor = color)),
            _colorPickerField('Button Color', _buttonColor, (color) => setState(() => _buttonColor = color)),
          ]),
          const SizedBox(height: 16),
          _section('Fonts', [
            _fontPickerField(),
            const SizedBox(height: 12),
            TextField(controller: _titleSizeCtrl, decoration: const InputDecoration(labelText: 'Title Font Size'), keyboardType: TextInputType.number),
            TextField(controller: _scoreSizeCtrl, decoration: const InputDecoration(labelText: 'Score Font Size'), keyboardType: TextInputType.number),
            TextField(controller: _timerSizeCtrl, decoration: const InputDecoration(labelText: 'Timer Font Size'), keyboardType: TextInputType.number),
          ]),
          const SizedBox(height: 16),
          _section('Images', [
            ElevatedButton(onPressed: () => _uploadImage('backgroundImageUrl'), child: const Text('Upload Background Image')),
            ElevatedButton(onPressed: () => _uploadImage('logoImageUrl'), child: const Text('Upload Logo Image')),
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

  Widget _colorPickerField(String label, Color color, void Function(Color) onColorChanged) {
    return InkWell(
      onTap: () => _showColorPicker(label, color, onColorChanged),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.grey, width: 2),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 2),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _colorToHex(color),
            style: TextStyle(fontSize: 14, color: Colors.grey[400], fontFamily: 'monospace'),
          ),
        ]),
      ),
    );
  }

  Widget _fontPickerField() {
    final fonts = [
      'Roboto',
      'Arial',
      'Helvetica',
      'Times New Roman',
      'Courier New',
      'Verdana',
      'Georgia',
      'Palatino',
      'Comic Sans MS',
      'Impact',
      'Trebuchet MS',
      'Lucida Console',
    ];
    return DropdownButtonFormField<String>(
      value: _selectedFont,
      decoration: const InputDecoration(labelText: 'Font Family'),
      items: fonts.map((font) => DropdownMenuItem(value: font, child: Text(font))).toList(),
      onChanged: (value) {
        if (value != null) setState(() => _selectedFont = value);
      },
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.white;
    }
  }
}
