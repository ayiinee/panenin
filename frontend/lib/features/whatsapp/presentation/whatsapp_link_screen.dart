import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panenin/app/theme/app_colors.dart';
import 'package:panenin/core/network/api_exception.dart';
import 'package:panenin/features/profile/data/whatsapp_service.dart';
import 'package:panenin/features/whatsapp/data/whatsapp_repository.dart';

typedef WhatsAppLinkLauncher = Future<void> Function(String linkCode);

class WhatsAppLinkScreen extends StatefulWidget {
  const WhatsAppLinkScreen({this.repository, this.openWhatsApp, super.key});

  final WhatsAppRepository? repository;
  final WhatsAppLinkLauncher? openWhatsApp;

  @override
  State<WhatsAppLinkScreen> createState() => _WhatsAppLinkScreenState();
}

class _WhatsAppLinkScreenState extends State<WhatsAppLinkScreen> {
  WhatsAppStatus? _status;
  WhatsAppLinkCode? _linkCode;
  bool _loading = false;
  bool _openingWhatsApp = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.repository != null) _refresh();
  }

  Future<void> _refresh() async {
    final repository = widget.repository;
    if (repository == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = await repository.status();
      if (!mounted) return;
      setState(() => _status = status);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createCode() async {
    final repository = widget.repository;
    if (repository == null) {
      setState(() => _error = 'Repository WhatsApp belum dikonfigurasi.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final code = await repository.createLinkCode();
      if (!mounted) return;
      setState(() => _linkCode = code);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openWhatsApp() async {
    final linkCode = _linkCode;
    if (linkCode == null || _openingWhatsApp) return;
    setState(() {
      _openingWhatsApp = true;
      _error = null;
    });
    try {
      final launcher = widget.openWhatsApp;
      if (launcher != null) {
        await launcher(linkCode.code);
      } else {
        await const WhatsAppService().openConnectionChat(
          linkCode: linkCode.code,
        );
      }
    } on WhatsAppLaunchException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Gagal membuka WhatsApp. Silakan coba lagi.';
        });
      }
    } finally {
      if (mounted) setState(() => _openingWhatsApp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final linked = _status?.linked ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hubungkan WhatsApp'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Icon(
              linked ? Icons.check_circle : Icons.chat_outlined,
              size: 72,
              color: linked ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              linked ? 'WhatsApp sudah terhubung' : 'Hubungkan akun WhatsApp',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            const Text(
              'Kode hanya berlaku singkat dan hanya dapat digunakan satu kali.',
              textAlign: TextAlign.center,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                key: const ValueKey('whatsapp-error'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
            if (_linkCode != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('Kode penghubung'),
                      const SizedBox(height: 8),
                      SelectableText(
                        _linkCode!.code,
                        key: const ValueKey('whatsapp-link-code'),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_linkCode!.instruction, textAlign: TextAlign.center),
                      Text(
                        'Berlaku hingga ${_formatTime(_linkCode!.expiresAt)}',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: const ValueKey('open-whatsapp-link'),
                          onPressed: _openingWhatsApp ? null : _openWhatsApp,
                          icon: _openingWhatsApp
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.open_in_new),
                          label: const Text('Buka WhatsApp'),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: 'HUBUNGKAN ${_linkCode!.code}'),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Instruksi disalin.')),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Salin instruksi'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const ValueKey('create-whatsapp-link-code'),
              onPressed: _loading || linked ? null : _createCode,
              icon: _loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.link),
              label: Text(linked ? 'Sudah Terhubung' : 'Buat Kode'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading ? null : _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Perbarui status'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
