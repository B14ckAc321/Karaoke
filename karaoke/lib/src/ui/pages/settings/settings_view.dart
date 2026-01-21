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
  final _customText1Ctrl = TextEditingController();
  final _customText2Ctrl = TextEditingController();
  final _customText3Ctrl = TextEditingController();
  final _customTextLeft1Ctrl = TextEditingController();
  final _customTextLeft2Ctrl = TextEditingController();
  final _customTextLeft3Ctrl = TextEditingController();
  
  // Font sizes for custom texts
  final _customText1SizeCtrl = TextEditingController();
  final _customText2SizeCtrl = TextEditingController();
  final _customText3SizeCtrl = TextEditingController();
  final _customTextLeft1SizeCtrl = TextEditingController();
  final _customTextLeft2SizeCtrl = TextEditingController();
  final _customTextLeft3SizeCtrl = TextEditingController();
  
  // Colors for custom texts
  Color _customText1Color = Colors.yellow;
  Color _customText2Color = Colors.white;
  Color _customText3Color = Colors.white;
  Color _customTextLeft1Color = Colors.yellow;
  Color _customTextLeft2Color = Colors.white;
  Color _customTextLeft3Color = Colors.white;

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
    _customText1Ctrl.text = themeService.getThemeSetting('customText1') ?? '';
    _customText2Ctrl.text = themeService.getThemeSetting('customText2') ?? '';
    _customText3Ctrl.text = themeService.getThemeSetting('customText3') ?? '';
    _customTextLeft1Ctrl.text = themeService.getThemeSetting('customTextLeft1') ?? '';
    _customTextLeft2Ctrl.text = themeService.getThemeSetting('customTextLeft2') ?? '';
    _customTextLeft3Ctrl.text = themeService.getThemeSetting('customTextLeft3') ?? '';
    
    // Load font sizes
    _customText1SizeCtrl.text = themeService.getThemeSetting('customText1Size') ?? '32';
    _customText2SizeCtrl.text = themeService.getThemeSetting('customText2Size') ?? '24';
    _customText3SizeCtrl.text = themeService.getThemeSetting('customText3Size') ?? '20';
    _customTextLeft1SizeCtrl.text = themeService.getThemeSetting('customTextLeft1Size') ?? '32';
    _customTextLeft2SizeCtrl.text = themeService.getThemeSetting('customTextLeft2Size') ?? '24';
    _customTextLeft3SizeCtrl.text = themeService.getThemeSetting('customTextLeft3Size') ?? '20';
    
    // Load colors
    _customText1Color = _parseColor(themeService.getThemeSetting('customText1Color') ?? '#FFD93D');
    _customText2Color = _parseColor(themeService.getThemeSetting('customText2Color') ?? '#FFFFFF');
    _customText3Color = _parseColor(themeService.getThemeSetting('customText3Color') ?? '#FFFFFF');
    _customTextLeft1Color = _parseColor(themeService.getThemeSetting('customTextLeft1Color') ?? '#FFD93D');
    _customTextLeft2Color = _parseColor(themeService.getThemeSetting('customTextLeft2Color') ?? '#FFFFFF');
    _customTextLeft3Color = _parseColor(themeService.getThemeSetting('customTextLeft3Color') ?? '#FFFFFF');
  }

  // Calculate if a color is dark (returns true) or light (returns false)
  bool _isDarkColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance < 0.5;
  }

  // Get appropriate text color for a background color
  Color _getTextColorForBackground(Color backgroundColor) {
    return _isDarkColor(backgroundColor) ? Colors.white : Colors.black;
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
    final r = ((color.r * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
    final g = ((color.g * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
    final b = ((color.b * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
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
      'customText1': _customText1Ctrl.text,
      'customText2': _customText2Ctrl.text,
      'customText3': _customText3Ctrl.text,
      'customTextLeft1': _customTextLeft1Ctrl.text,
      'customTextLeft2': _customTextLeft2Ctrl.text,
      'customTextLeft3': _customTextLeft3Ctrl.text,
      'customText1Size': _customText1SizeCtrl.text,
      'customText2Size': _customText2SizeCtrl.text,
      'customText3Size': _customText3SizeCtrl.text,
      'customTextLeft1Size': _customTextLeft1SizeCtrl.text,
      'customTextLeft2Size': _customTextLeft2SizeCtrl.text,
      'customTextLeft3Size': _customTextLeft3SizeCtrl.text,
      'customText1Color': _colorToHex(_customText1Color),
      'customText2Color': _colorToHex(_customText2Color),
      'customText3Color': _colorToHex(_customText3Color),
      'customTextLeft1Color': _colorToHex(_customTextLeft1Color),
      'customTextLeft2Color': _colorToHex(_customTextLeft2Color),
      'customTextLeft3Color': _colorToHex(_customTextLeft3Color),
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved!')));
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _backgroundColor;
    final textColor = _getTextColorForBackground(bgColor);
    final cardColor = _cardColor;
    final cardTextColor = _getTextColorForBackground(cardColor);
    final buttonColor = _buttonColor;
    final buttonTextColor = _getTextColorForBackground(buttonColor);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Settings & Customization', style: TextStyle(color: textColor)),
        backgroundColor: cardColor,
      ),
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
            TextField(
              controller: _titleSizeCtrl,
              decoration: InputDecoration(
                labelText: 'Title Font Size',
                labelStyle: TextStyle(color: cardTextColor),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cardTextColor.withValues(alpha: 0.5))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: buttonColor)),
              ),
              style: TextStyle(color: cardTextColor),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _scoreSizeCtrl,
              decoration: InputDecoration(
                labelText: 'Score Font Size',
                labelStyle: TextStyle(color: cardTextColor),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cardTextColor.withValues(alpha: 0.5))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: buttonColor)),
              ),
              style: TextStyle(color: cardTextColor),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _timerSizeCtrl,
              decoration: InputDecoration(
                labelText: 'Timer Font Size',
                labelStyle: TextStyle(color: cardTextColor),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cardTextColor.withValues(alpha: 0.5))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: buttonColor)),
              ),
              style: TextStyle(color: cardTextColor),
              keyboardType: TextInputType.number,
            ),
          ]),
          const SizedBox(height: 16),
          _section('Images', [
            ElevatedButton(
              onPressed: () => _uploadImage('backgroundImageUrl'),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: buttonTextColor,
              ),
              child: const Text('Upload Background Image'),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton(
                        onPressed: () => _uploadImage('logoImageUrl'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: buttonTextColor,
                        ),
                        child: const Text('Upload Logo Image'),
                      ),
                      if (themeService.logoImageUrl != null) ...[
                        const SizedBox(height: 8),
                        Image.network(
                          themeService.logoImageUrl!,
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Right Side Text Fields',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: cardTextColor,
                            fontFamily: themeService.fontFamily,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildCustomTextField('Custom Text 1 (Right)', _customText1Ctrl, _customText1SizeCtrl, _customText1Color, (c) => setState(() => _customText1Color = c), cardTextColor, buttonColor),
                        const SizedBox(height: 12),
                        _buildCustomTextField('Custom Text 2 (Right)', _customText2Ctrl, _customText2SizeCtrl, _customText2Color, (c) => setState(() => _customText2Color = c), cardTextColor, buttonColor),
                        const SizedBox(height: 12),
                        _buildCustomTextField('Custom Text 3 (Right)', _customText3Ctrl, _customText3SizeCtrl, _customText3Color, (c) => setState(() => _customText3Color = c), cardTextColor, buttonColor),
                        const SizedBox(height: 24),
                        Text(
                          'Left Side Text Fields',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: cardTextColor,
                            fontFamily: themeService.fontFamily,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildCustomTextField('Custom Text 1 (Left)', _customTextLeft1Ctrl, _customTextLeft1SizeCtrl, _customTextLeft1Color, (c) => setState(() => _customTextLeft1Color = c), cardTextColor, buttonColor),
                        const SizedBox(height: 12),
                        _buildCustomTextField('Custom Text 2 (Left)', _customTextLeft2Ctrl, _customTextLeft2SizeCtrl, _customTextLeft2Color, (c) => setState(() => _customTextLeft2Color = c), cardTextColor, buttonColor),
                        const SizedBox(height: 12),
                        _buildCustomTextField('Custom Text 3 (Left)', _customTextLeft3Ctrl, _customTextLeft3SizeCtrl, _customTextLeft3Color, (c) => setState(() => _customTextLeft3Color = c), cardTextColor, buttonColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: buttonTextColor,
            ),
            child: const Text('Save All Settings'),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    final cardColor = _cardColor;
    final cardTextColor = _getTextColorForBackground(cardColor);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cardTextColor)),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _colorPickerField(String label, Color color, void Function(Color) onColorChanged) {
    final cardColor = _cardColor;
    final cardTextColor = _getTextColorForBackground(cardColor);
    return InkWell(
      onTap: () => _showColorPicker(label, color, onColorChanged),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 16, color: cardTextColor)),
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
            style: TextStyle(fontSize: 14, color: cardTextColor.withValues(alpha: 0.7), fontFamily: 'monospace'),
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
    final cardColor = _cardColor;
    final cardTextColor = _getTextColorForBackground(cardColor);
    final buttonColor = _buttonColor;
    return DropdownButtonFormField<String>(
      value: _selectedFont,
      decoration: InputDecoration(
        labelText: 'Font Family',
        labelStyle: TextStyle(color: cardTextColor),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cardTextColor.withValues(alpha: 0.5))),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: buttonColor)),
      ),
      dropdownColor: cardColor,
      style: TextStyle(color: cardTextColor),
      items: fonts.map((font) => DropdownMenuItem(
        value: font,
        child: Text(font, style: TextStyle(color: cardTextColor)),
      )).toList(),
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

  Widget _buildCustomTextField(String label, TextEditingController textCtrl, TextEditingController sizeCtrl, Color color, void Function(Color) onColorChanged, Color cardTextColor, Color buttonColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: textCtrl,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: cardTextColor),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cardTextColor.withValues(alpha: 0.5))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: buttonColor)),
          ),
          style: TextStyle(color: cardTextColor),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: sizeCtrl,
                decoration: InputDecoration(
                  labelText: 'Font Size',
                  labelStyle: TextStyle(color: cardTextColor, fontSize: 12),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cardTextColor.withValues(alpha: 0.5))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: buttonColor)),
                ),
                style: TextStyle(color: cardTextColor, fontSize: 12),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _showColorPicker('$label Color', color, onColorChanged),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: _getTextColorForBackground(color),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(60, 36),
              ),
              child: const Text('Color', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }
}
