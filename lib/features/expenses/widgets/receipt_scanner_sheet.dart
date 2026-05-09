import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_expense_tracker/core/services/ocr_service.dart';
import 'package:mobile_expense_tracker/core/providers/ai_provider.dart';

class ReceiptScannerSheet extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic> parsedData) onParsed;

  const ReceiptScannerSheet({super.key, required this.onParsed});

  @override
  ConsumerState<ReceiptScannerSheet> createState() =>
      _ReceiptScannerSheetState();
}

class _ReceiptScannerSheetState extends ConsumerState<ReceiptScannerSheet> {
  final OCRService _ocrService = OCRService();
  String? _imagePath;
  String _ocrText = '';
  bool _isBusy = false;
  Map<String, dynamic>? _parsedData;
  String? _provider;
  String? _error;
  bool _showFullOcr = false;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _scan(ImageSource source) async {
    setState(() {
      _error = null;
      _parsedData = null;
      _ocrText = '';
      _showFullOcr = false;
      _isBusy = true;
    });

    try {
      final image = source == ImageSource.camera
          ? await _ocrService.pickImageFromCamera()
          : await _ocrService.pickImageFromGallery();

      if (image == null) {
        if (!mounted) return;
        setState(() => _isBusy = false);
        return;
      }

      if (!mounted) return;
      setState(() => _imagePath = image.path);

      final text = await _ocrService.extractText(image);
      if (!mounted) return;
      if (text.trim().isEmpty) {
        setState(() {
          _error = 'No text found in image. Try a clearer photo.';
          _isBusy = false;
        });
        return;
      }

      setState(() {
        _ocrText = text;
        _isBusy = false;
      });

      await _parseWithAI(text);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error: $e';
        _isBusy = false;
      });
    }
  }

  Future<void> _parseWithAI(String text) async {
    final aiSettings = ref.read(aiSettingsProvider);
    if (!aiSettings.hasAnyKey) {
      return;
    }

    setState(() => _isBusy = true);
    try {
      final service = ref.read(aiSettingsProvider.notifier).service;
      final result = await service.parseReceipt(text);
      if (!mounted) return;
      setState(() {
        _parsedData = result;
        _provider = service.lastUsedProvider;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      setState(() => _error = msg.contains('401')
          ? 'Invalid API key (401). Check your keys in Settings → AI Assistant.'
          : 'AI failed: $msg');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textPrimary = scheme.onSurface;
    final textSecondary = scheme.onSurface.withAlpha(153);
    final bg = scheme.surface;

    final aiSettings = ref.watch(aiSettingsProvider);
    final hasRealKey = aiSettings.hasAnyKey;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(textPrimary),
            const SizedBox(height: 20),
            if (_imagePath != null) ...[
              _imagePreview(),
              const SizedBox(height: 20),
            ],
            if (_isBusy) ...[
              _loading(),
              const SizedBox(height: 20),
            ],
            if (_error != null) ...[
              _errorBox(_error!),
              const SizedBox(height: 20),
            ],
            if (_parsedData != null) ...[
              _ParsedCard(data: _parsedData!, provider: _provider, onUse: _useData),
              const SizedBox(height: 20),
            ],
            if (_imagePath == null && !_isBusy) ...[
              _actionButtons(),
              const SizedBox(height: 20),
            ],
            if (_ocrText.isNotEmpty && !_isBusy) ...[
              _ocrSection(_ocrText, textSecondary, hasRealKey),
              const SizedBox(height: 20),
            ],
            if (_imagePath != null && !_isBusy && _parsedData == null) ...[
              _resetButton(),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(Color textPrimary) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          Icon(Icons.document_scanner_outlined, color: textPrimary),
          const SizedBox(width: 10),
          Text('Scan Receipt',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
        ],
      ),
      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
    ],
  );

  Widget _imagePreview() => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.file(File(_imagePath!), height: 160, width: double.infinity, fit: BoxFit.cover,
      errorBuilder: (_, err, stk) => Container(height: 160, color: Colors.grey[200],
        child: const Center(child: Icon(Icons.broken_image))),
    ),
  );

  Widget _loading() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Center(child: Column(children: [
      CircularProgressIndicator(),
      SizedBox(height: 12),
      Text('Processing…'),
    ])),
  );

  Widget _errorBox(String msg) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.red.withAlpha(20),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.red.withAlpha(60)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.red, fontSize: 13))),
      ],
    ),
  );

  Widget _actionButtons() => Column(children: [
    SizedBox(width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _scan(ImageSource.camera),
        icon: const Icon(Icons.camera_alt),
        label: const Text('Take Photo'),
      ),
    ),
    const SizedBox(height: 10),
    SizedBox(width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _scan(ImageSource.gallery),
        icon: const Icon(Icons.photo_library),
        label: const Text('Choose from Gallery'),
      ),
    ),
  ]);

  Widget _ocrSection(String text, Color textSecondary, bool hasRealKey) {
    const maxLinesCollapsed = 4;
    final isLong = text.split('\n').length > maxLinesCollapsed || text.length > 200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.text_snippet_outlined, size: 16, color: textSecondary),
            const SizedBox(width: 6),
            Text('Extracted Text', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textSecondary)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(color: textSecondary, fontSize: 12, height: 1.4),
                maxLines: _showFullOcr ? null : maxLinesCollapsed,
                overflow: _showFullOcr ? null : TextOverflow.ellipsis,
              ),
              if (isLong)
                TextButton(
                  onPressed: () => setState(() => _showFullOcr = !_showFullOcr),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text(_showFullOcr ? 'Show less' : 'Show more', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
        if (!hasRealKey)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.key_off_outlined, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
            child: const Text(
              'Add your Gemini or NVIDIA API key in Settings → AI Assistant to auto-parse receipts.',
                      style: TextStyle(fontSize: 12, color: Colors.amber),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _resetButton() => SizedBox(
    width: double.infinity,
    child: TextButton(
      onPressed: () => setState(() {
        _imagePath = null; _ocrText = ''; _parsedData = null; _provider = null; _error = null; _showFullOcr = false;
      }),
      child: const Text('Scan Another'),
    ),
  );

  void _useData() {
    widget.onParsed(_parsedData!);
    Navigator.pop(context);
  }
}

class _ParsedCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? provider;
  final VoidCallback onUse;

  const _ParsedCard({required this.data, this.provider, required this.onUse});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textPrimary = scheme.onSurface;
    final textSecondary = scheme.onSurface.withAlpha(153);
    final success = const Color(0xFF4CAF50);

    final merchant = data['merchant']?.toString();
    final date = data['date']?.toString();
    final total = data['total']?.toString();
    final currency = data['currency']?.toString();

    final hasAnyValue = merchant != null || date != null || total != null || currency != null;

    return Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: success.withAlpha(12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: success.withAlpha(40)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Icon(Icons.check_circle, size: 18, color: success),
              const SizedBox(width: 8),
              Text('Parsed Receipt', style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary, fontSize: 15)),
              const Spacer(),
              if (provider != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: success.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    provider!,
                    style: TextStyle(fontSize: 11, color: success, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasAnyValue) ...[
            _row(Icons.storefront_outlined, 'Merchant', merchant, textPrimary, textSecondary),
            _row(Icons.calendar_today_outlined, 'Date', date, textPrimary, textSecondary),
            _row(Icons.attach_money_outlined, 'Total', total != null ? '$total ${currency ?? ''}'.trim() : null, textPrimary, textSecondary),
            if (currency != null && total == null)
              _row(Icons.money_outlined, 'Currency', currency, textPrimary, textSecondary),
          ] else
            Text('Could not extract details. You can still save the image with the expense.', style: TextStyle(color: textSecondary, fontSize: 13)),
        ]),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onUse,
          icon: const Icon(Icons.check),
          label: const Text('Use This Data'),
        ),
      ),
    ]);
  }

  Widget _row(IconData icon, String label, String? value, Color primary, Color secondary) {
    final valid = value != null && value.isNotEmpty && value != 'null';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: valid ? const Color(0xFF4CAF50) : secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: secondary, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  valid ? value : 'Not found',
                  style: TextStyle(
                    color: valid ? primary : secondary.withAlpha(128),
                    fontWeight: valid ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
