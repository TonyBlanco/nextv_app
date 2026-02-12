import 'package:flutter/material.dart';
import '../../core/constants/nextv_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/xtream_models.dart';
import '../../core/models/playlist_model.dart';
import '../../core/services/playlist_manager.dart';
import '../../core/services/xtream_api_service.dart';
import '../../core/providers/active_playlist_provider.dart';
import '../widgets/nextv_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKeyXtream = GlobalKey<FormState>();
  final _formKeyM3U = GlobalKey<FormState>();
  
  // Xtream Controllers
  final _xtreamNameController = TextEditingController(); // Provider name
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _xtreamFallbackController = TextEditingController(); // NUEVO: URL de respaldo para Xtream
  
  // M3U Controllers
  final _m3uNameController = TextEditingController();
  final _m3uUrlController = TextEditingController();
  final _epgUrlController = TextEditingController();
  final _fallbackUrlController = TextEditingController(); // NUEVO: URL de respaldo

  // Selection for which types to download
  // Always download all content types (Live, Movies, Series)
  final bool _includeLive = true;
  final bool _includeVOD = true;
  final bool _includeSeries = true;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _xtreamNameController.dispose();
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _xtreamFallbackController.dispose();
    _m3uNameController.dispose();
    _m3uUrlController.dispose();
    _epgUrlController.dispose();
    _fallbackUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleXtreamLogin() async {
    if (!_formKeyXtream.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final credentials = XtreamCredentials(
        serverUrl: _serverController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final api = ref.read(xtreamAPIProvider);
      api.setCredentials(credentials);
      final result = await api.authenticate();

      if (result['success'] == true) {
        final newPlaylist = Playlist(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _xtreamNameController.text.trim().isNotEmpty
              ? _xtreamNameController.text.trim()
              : result['userInfo'].username.toUpperCase(),
          type: 'xtream',
          serverUrl: credentials.serverUrl,
          username: credentials.username,
          password: credentials.password,
          selectedTypes: [
            if (_includeLive) 'live',
            if (_includeVOD) 'movies',
            if (_includeSeries) 'series',
          ],
          epgUrl: _epgUrlController.text.trim().isEmpty ? null : _epgUrlController.text.trim(),
          fallbackUrl: _xtreamFallbackController.text.trim().isEmpty ? null : _xtreamFallbackController.text.trim(),
          isActive: true,
          lastUpdated: DateTime.now(),
        );
        // Check for duplicate provider
        final manager = ref.read(playlistManagerProvider.notifier);
        final existing = manager.findDuplicate(newPlaylist);
        if (existing != null) {
          // Update existing instead of adding duplicate
          final updated = existing.copyWith(
            name: newPlaylist.name,
            epgUrl: newPlaylist.epgUrl,
            fallbackUrl: newPlaylist.fallbackUrl,
            lastUpdated: DateTime.now(),
          );
          await manager.updatePlaylist(updated);
          ref.read(activePlaylistProvider.notifier).state = updated;
        } else {
          await manager.addPlaylist(newPlaylist);
          ref.read(activePlaylistProvider.notifier).state = newPlaylist;
        }
        if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/landing', (route) => false);
      } else {
        _showError(result['error'] ?? 'Error de autenticación');
      }
    } catch (e) {
      debugPrint('Xtream login exception: $e');
      _showError('Error al conectar con el servidor. Revisa la URL y credenciales.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleM3UAdd() async {
    if (!_formKeyM3U.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final newPlaylist = Playlist(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _m3uNameController.text.trim(),
        type: 'm3u',
        m3uUrl: _m3uUrlController.text.trim(),
        epgUrl: _epgUrlController.text.trim().isEmpty ? null : _epgUrlController.text.trim(),
        fallbackUrl: _fallbackUrlController.text.trim().isEmpty ? null : _fallbackUrlController.text.trim(),
        selectedTypes: [
          if (_includeLive) 'live',
          if (_includeVOD) 'movies',
          if (_includeSeries) 'series',
        ],
        isActive: true,
        lastUpdated: DateTime.now(),
      );
      // Check for duplicate provider
      final manager = ref.read(playlistManagerProvider.notifier);
      final existing = manager.findDuplicate(newPlaylist);
      if (existing != null) {
        final updated = existing.copyWith(
          name: newPlaylist.name,
          epgUrl: newPlaylist.epgUrl,
          fallbackUrl: newPlaylist.fallbackUrl,
          lastUpdated: DateTime.now(),
        );
        await manager.updatePlaylist(updated);
        ref.read(activePlaylistProvider.notifier).state = updated;
      } else {
        await manager.addPlaylist(newPlaylist);
        ref.read(activePlaylistProvider.notifier).state = newPlaylist;
      }
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/landing', (route) => false);
    } catch (e) {
      debugPrint('M3U add exception: $e');
      _showError('Error al añadir la lista M3U. Revisa la URL.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NextvColors.background,
      appBar: AppBar(
        title: const Text('Añadir Lista'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: NextvColors.accent,
          tabs: const [
            Tab(text: 'Xtream Codes'),
            Tab(text: 'M3U Link'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildXtreamForm(),
              _buildM3UForm(),
            ],
          ),
    );
  }

  Widget _buildXtreamForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeyXtream,
        child: Column(
          children: [
            const NextvLogo(
              size: 80.0,
              showText: true,
              withGlow: false,
            ),
            const SizedBox(height: 32),
            _buildField(_xtreamNameController, 'Nombre del Proveedor', Icons.badge, required: false),
            const SizedBox(height: 16),
            _buildFieldWithPaste(_serverController, 'URL del Servidor', Icons.dns),
            const SizedBox(height: 16),
            _buildFieldWithPaste(_xtreamFallbackController, 'URL de Respaldo (opcional)', Icons.backup, required: false),
            const SizedBox(height: 16),
            _buildField(_usernameController, 'Usuario', Icons.person),
            const SizedBox(height: 16),
            _buildField(_passwordController, 'Contraseña', Icons.lock, obscure: true),
            const SizedBox(height: 32),
            _buildButton('AÑADIR CUENTA XTREAM', _handleXtreamLogin),
          ],
        ),
      ),
    );
  }

  Widget _buildM3UForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeyM3U,
        child: Column(
          children: [
            const NextvLogo(
              size: 80.0,
              showText: true,
              withGlow: false,
            ),
            const SizedBox(height: 32),
            _buildField(_m3uNameController, 'Nombre de la lista', Icons.label),
            const SizedBox(height: 16),
            _buildFieldWithPaste(_m3uUrlController, 'URL M3U', Icons.link),
            const SizedBox(height: 16),
            _buildFieldWithPaste(_fallbackUrlController, 'URL M3U de Respaldo (opcional)', Icons.backup, required: false),
            const SizedBox(height: 16),
            _buildFieldWithPaste(_epgUrlController, 'URL EPG (XMLTV - opcional)', Icons.schedule, required: false),
            const SizedBox(height: 32),
            _buildButton('AÑADIR LISTA M3U', _handleM3UAdd),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool obscure = false, bool required = true}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      enableInteractiveSelection: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: NextvColors.accent),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      validator: (v) => required && v!.isEmpty ? 'Campo requerido' : null,
    );
  }

  Widget _buildFieldWithPaste(TextEditingController controller, String label, IconData icon, {bool required = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                enableInteractiveSelection: true,
                maxLines: 3,
                minLines: 1,
                keyboardType: TextInputType.url,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: label,
                  prefixIcon: Icon(icon, color: NextvColors.accent),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                ),
                validator: (v) => required && (v == null || v.isEmpty) ? 'Campo requerido' : null,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: NextvColors.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NextvColors.accent.withOpacity(0.3)),
              ),
              child: IconButton(
                icon: const Icon(Icons.content_paste, color: NextvColors.accent, size: 24),
                tooltip: 'Pegar',
                padding: EdgeInsets.zero,
                onPressed: () async {
                  try {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null && data!.text!.isNotEmpty) {
                      setState(() {
                        controller.text = data.text!.trim();
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Texto pegado correctamente'),
                              ],
                            ),
                            backgroundColor: NextvColors.accent,
                            duration: Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('El portapapeles está vacío'),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    debugPrint('Error al pegar: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al acceder al portapapeles: $e'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: NextvColors.accent,
          foregroundColor: NextvColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

