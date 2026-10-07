import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../search/data/repositories/search_repository_impl.dart';
import '../../domain/models/saved_marker.dart';

class AddMarkerSheet extends ConsumerStatefulWidget {
  final LatLng position;
  final ValueChanged<SavedMarker> onSave;

  const AddMarkerSheet({
    super.key,
    required this.position,
    required this.onSave,
  });

  @override
  ConsumerState<AddMarkerSheet> createState() => _AddMarkerSheetState();
}

class _AddMarkerSheetState extends ConsumerState<AddMarkerSheet> {
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoadingAddress = true;
  String? _street;
  String? _fullAddress;
  bool _userEditedTitle = false;

  @override
  void initState() {
    super.initState();
    _resolveAddress();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _resolveAddress() async {
    try {
      final repo = ref.read(searchRepositoryProvider);
      final result = await repo.reverseGeocode(widget.position);
      if (!mounted) return;

      result.when(
        success: (geocode) {
          setState(() {
            _isLoadingAddress = false;
            _street = geocode.street;
            _fullAddress = geocode.fullAddress;
            if (!_userEditedTitle) {
              _titleController.text = geocode.street;
            }
          });
        },
        error: (_) {
          setState(() {
            _isLoadingAddress = false;
            _street = 'Точка на карте';
            _fullAddress =
                'Координаты: ${widget.position.latitude.toStringAsFixed(5)}, ${widget.position.longitude.toStringAsFixed(5)}';
            if (!_userEditedTitle) {
              _titleController.text = _street!;
            }
          });
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingAddress = false;
        _street = 'Точка на карте';
        _fullAddress =
            'Координаты: ${widget.position.latitude.toStringAsFixed(5)}, ${widget.position.longitude.toStringAsFixed(5)}';
        if (!_userEditedTitle) {
          _titleController.text = _street!;
        }
      });
    }
  }

  void _submit() {
    final entered = _titleController.text.trim();
    final title = entered.isNotEmpty ? entered : (_street ?? 'Точка на карте');
    final marker = SavedMarker(
      id: 'marker_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      position: widget.position,
      address: _fullAddress ?? _street,
      description:
          'Координаты: ${widget.position.latitude.toStringAsFixed(5)}, ${widget.position.longitude.toStringAsFixed(5)}',
    );
    widget.onSave(marker);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Material(
        color: Colors.transparent,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Верхний хэндл
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Шапка
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_location_alt_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Новая метка',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Сохранить точку на карте',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon:
                        const Icon(Icons.close_rounded, color: Colors.white60),
                    tooltip: 'Закрыть',
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Поле ввода названия метки
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Название метки',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _titleController,
                    focusNode: _focusNode,
                    onChanged: (val) {
                      _userEditedTitle = true;
                      setState(() {});
                    },
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.surfaceSubtle,
                      hintText: _isLoadingAddress
                          ? 'Определяем улицу...'
                          : 'Введите название',
                      hintStyle:
                          const TextStyle(color: Colors.white38, fontSize: 14),
                      prefixIcon: const Icon(Icons.edit_note_rounded,
                          color: AppTheme.accent, size: 22),
                      suffixIcon: _titleController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  color: Colors.white38, size: 18),
                              onPressed: () {
                                _titleController.clear();
                                _userEditedTitle = true;
                                setState(() {});
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'По умолчанию соответствует улице. Можно изменить сразу.',
                    style: TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Карточка: Улица / Адрес
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.location_on_rounded,
                          color: Colors.redAccent, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Улица / Адрес',
                            style:
                                TextStyle(fontSize: 11, color: Colors.white38),
                          ),
                          const SizedBox(height: 2),
                          if (_isLoadingAddress)
                            const Row(
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Определяем адрес...',
                                  style: TextStyle(
                                      color: Colors.white60, fontSize: 13),
                                ),
                              ],
                            )
                          else
                            Text(
                              _fullAddress ?? _street ?? 'Точка на карте',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Карточка: Дополнительная информация (Координаты)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.explore_outlined,
                        color: Colors.white54, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Координаты (дополнительная информация)',
                            style:
                                TextStyle(fontSize: 11, color: Colors.white38),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.position.latitude.toStringAsFixed(6)}, ${widget.position.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded,
                          size: 16, color: Colors.white38),
                      tooltip: 'Скопировать координаты',
                      onPressed: () {
                        final text =
                            '${widget.position.latitude}, ${widget.position.longitude}';
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Координаты скопированы'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Кнопки действий: Отмена и Сохранить
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.bookmark_add_rounded, size: 20),
                      label: const Text(
                        'Сохранить метку',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
