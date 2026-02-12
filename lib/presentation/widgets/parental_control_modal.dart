import 'package:flutter/material.dart';
import '../../core/constants/nextv_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/parental_provider.dart';

class ParentalControlModal extends ConsumerStatefulWidget {
  const ParentalControlModal({super.key});

  @override
  ConsumerState<ParentalControlModal> createState() => _ParentalControlModalState();
}

class _ParentalControlModalState extends ConsumerState<ParentalControlModal> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  bool _showPin = false;
  bool _isAuthenticated = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final parentalSettings = ref.read(parentalProvider);
    _isAuthenticated = !parentalSettings.enabled;
  }

  @override
  Widget build(BuildContext context) {
    final parentalSettings = ref.watch(parentalProvider);

    return Dialog(
      backgroundColor: NextvColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.lock, color: NextvColors.accent, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Control Parental',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content
            if (!_isAuthenticated) ...[
              // PIN Authentication
              const Text(
                'Ingresa el PIN para acceder',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                obscureText: !_showPin,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'PIN',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: NextvColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: NextvColors.accent),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: NextvColors.accent),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPin ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                    ),
                    onPressed: () => setState(() => _showPin = !_showPin),
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _verifyPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NextvColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Verificar PIN',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ] else ...[
              // Settings
              // Enable/Disable
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Habilitar Control Parental',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Switch(
                    value: parentalSettings.enabled,
                    onChanged: (value) {
                      ref.read(parentalProvider.notifier).setEnabled(value);
                      if (!value) {
                        setState(() => _isAuthenticated = true);
                      }
                    },
                    activeThumbColor: NextvColors.accent,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // PIN Setup
              const Text(
                'PIN de Acceso',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _newPinController,
                obscureText: !_showPin,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Establece un PIN (4-6 dígitos)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: NextvColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: NextvColors.accent),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: NextvColors.accent),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPin ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                    ),
                    onPressed: () => setState(() => _showPin = !_showPin),
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                onChanged: (value) {
                  ref.read(parentalProvider.notifier).setPin(value);
                },
              ),
              const SizedBox(height: 24),

              // Blocked Categories
              const Text(
                'Categorías Bloqueadas',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _getCommonCategories().map((category) {
                  final isBlocked = parentalSettings.blockedCategories.contains(category);
                  return FilterChip(
                    label: Text(category),
                    selected: isBlocked,
                    onSelected: (selected) {
                      ref.read(parentalProvider.notifier).toggleCategory(category);
                    },
                    backgroundColor: NextvColors.background,
                    selectedColor: NextvColors.accent.withOpacity(0.2),
                    checkmarkColor: NextvColors.accent,
                    labelStyle: TextStyle(
                      color: isBlocked ? NextvColors.accent : Colors.white,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Guardar Configuración',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _verifyPin() {
    final parentalNotifier = ref.read(parentalProvider.notifier);
    if (parentalNotifier.verifyPin(_pinController.text)) {
      setState(() {
        _isAuthenticated = true;
        _error = null;
      });
    } else {
      setState(() => _error = 'PIN incorrecto');
    }
  }

  List<String> _getCommonCategories() {
    return [
      'Adult', 'XXX', 'Erotic', 'Porn', 'Sex', 'Nude', '18+', 'Adult Content',
      'Movies', 'Series', 'TV Shows', 'Sports', 'News', 'Kids', 'Family'
    ];
  }

  @override
  void dispose() {
    _pinController.dispose();
    _newPinController.dispose();
    super.dispose();
  }
}