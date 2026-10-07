import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/location_service.dart';
import '../../../../services/search_service.dart';
import '../../../places/domain/models/place.dart';
import '../../domain/models/search_result.dart';

class FloatingSearchBar extends StatefulWidget {
  final LatLng? userLocation;
  final LatLng? mapCenter;
  final List<Place> nearbyPlaces;
  final ValueChanged<SearchResult> onResultSelected;
  final ValueChanged<String>? onCategorySelected;
  final ValueChanged<bool>? onOpenStateChanged;
  final VoidCallback onClear;

  const FloatingSearchBar({
    super.key,
    this.userLocation,
    this.mapCenter,
    this.nearbyPlaces = const [],
    required this.onResultSelected,
    this.onCategorySelected,
    this.onOpenStateChanged,
    required this.onClear,
  });

  @override
  State<FloatingSearchBar> createState() => FloatingSearchBarState();
}

class FloatingSearchBarState extends State<FloatingSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _otherResultsLoaded = false;
  bool _showFarResults = false;
  List<SearchResult> _allResults = [];
  bool _showDropdown = false;
  int _searchToken = 0;

  List<SearchResult> get _nearResults =>
      _allResults.where((r) => (r.distanceMeters ?? 0) <= 50000).toList();

  List<SearchResult> get _farResults =>
      _allResults.where((r) => (r.distanceMeters ?? 0) > 50000).toList();

  List<SearchResult> get _displayedResults =>
      _showFarResults ? _allResults : _nearResults;

  LatLng get _effectiveLocation =>
      widget.userLocation ??
      widget.mapCenter ??
      LocationService.defaultLocation;

  static const List<Map<String, dynamic>> _quickCategories = [
    {
      'name': 'Кафе',
      'icon': Icons.local_cafe_rounded,
      'color': Color(0xFFFF9800)
    },
    {
      'name': 'Магазины',
      'icon': Icons.shopping_bag_rounded,
      'color': Color(0xFF4CAF50)
    },
    {
      'name': 'Аптеки',
      'icon': Icons.local_pharmacy_rounded,
      'color': Color(0xFFE91E63)
    },
    {
      'name': 'АЗС',
      'icon': Icons.local_gas_station_rounded,
      'color': Color(0xFFFF5722)
    },
    {
      'name': 'Рестораны',
      'icon': Icons.restaurant_rounded,
      'color': Color(0xFF9C27B0)
    },
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      final isOpen = _focusNode.hasFocus;
      if (mounted) {
        setState(() {
          _showDropdown = isOpen;
        });
      }
      widget.onOpenStateChanged?.call(isOpen);
    });
  }

  /// Закрыть поиск и скрыть выпадающее меню
  void closeSearch() {
    _searchToken++;
    _debounce?.cancel();
    _focusNode.unfocus();
    if (mounted) {
      setState(() {
        _showDropdown = false;
      });
    }
    widget.onOpenStateChanged?.call(false);
  }

  /// Очистить текст и закрыть меню
  void clearAndClose() {
    _searchToken++;
    _debounce?.cancel();
    _controller.clear();
    _focusNode.unfocus();
    if (mounted) {
      setState(() {
        _allResults = [];
        _showFarResults = false;
        _isLoading = false;
        _isLoadingMore = false;
        _otherResultsLoaded = false;
        _showDropdown = false;
      });
    }
    widget.onClear();
    widget.onOpenStateChanged?.call(false);
  }

  void _onQueryChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    final token = ++_searchToken;

    if (query.trim().isEmpty) {
      setState(() {
        _allResults = [];
        _showFarResults = false;
        _isLoading = false;
        _isLoadingMore = false;
        _otherResultsLoaded = false;
        _showDropdown = _focusNode.hasFocus;
      });
      widget.onClear();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted || token != _searchToken) return;
      setState(() {
        _isLoading = true;
        _isLoadingMore = false;
        _otherResultsLoaded = false;
        _showFarResults = false;
      });

      try {
        final results = await SearchService.search(
          query,
          proximity: _effectiveLocation,
        );
        if (!mounted || token != _searchToken) return;
        setState(() {
          _allResults = results;
          _isLoading = false;
          _showDropdown = true;
        });
      } catch (e) {
        if (!mounted || token != _searchToken) return;
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _loadOtherResults() async {
    final query = _controller.text.trim();
    if (query.isEmpty || _isLoadingMore) return;

    final token = _searchToken;
    setState(() {
      _isLoadingMore = true;
      _showFarResults = true;
    });

    try {
      final additional = await SearchService.search(
        query,
        proximity: _effectiveLocation,
        limit: 25,
      );
      if (!mounted || token != _searchToken) return;

      final existingKeys = _allResults
          .map((r) =>
              '${r.position.latitude.toStringAsFixed(5)},${r.position.longitude.toStringAsFixed(5)}')
          .toSet();

      final newItems = <SearchResult>[];
      for (final r in additional) {
        final key =
            '${r.position.latitude.toStringAsFixed(5)},${r.position.longitude.toStringAsFixed(5)}';
        if (!existingKeys.contains(key)) {
          newItems.add(r);
          existingKeys.add(key);
        }
      }

      final merged = [..._allResults, ...newItems];
      merged.sort((a, b) {
        final da = a.distanceMeters ?? double.infinity;
        final db = b.distanceMeters ?? double.infinity;
        return da.compareTo(db);
      });

      setState(() {
        _allResults = merged;
        _isLoadingMore = false;
        _otherResultsLoaded = true;
        _showFarResults = true;
      });
    } catch (_) {
      if (!mounted || token != _searchToken) return;
      setState(() {
        _isLoadingMore = false;
        _otherResultsLoaded = true;
        _showFarResults = true;
      });
    }
  }

  void _selectCategory(String cat) {
    _controller.text = cat;
    _focusNode.unfocus();
    setState(() {
      _showDropdown = false;
    });
    widget.onOpenStateChanged?.call(false);
    if (widget.onCategorySelected != null) {
      widget.onCategorySelected!(cat);
    } else {
      _onQueryChanged(cat);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_showDropdown,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _showDropdown) {
          clearAndClose();
        }
      },
      child: TapRegion(
        groupId: 'search_bar_group',
        onTapOutside: (_) {
          if (_showDropdown) {
            closeSearch();
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Поисковая строка с эффектом Glassmorphism
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withAlpha(220),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _showDropdown
                            ? AppTheme.accent.withAlpha(180)
                            : Colors.white.withAlpha(35),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: AppStrings.searchPlaceholder,
                        hintStyle: const TextStyle(
                            color: Colors.white54, fontSize: 14),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppTheme.accent,
                          size: 22,
                        ),
                        suffixIcon: _isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.primary,
                                    ),
                                  ),
                                ),
                              )
                            : (_showDropdown || _controller.text.isNotEmpty)
                                ? IconButton(
                                    icon: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(20),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    tooltip: 'Закрыть поиск',
                                    onPressed: clearAndClose,
                                  )
                                : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 8,
                        ),
                      ),
                      onChanged: _onQueryChanged,
                    ),
                  ),
                ),
              ),
            ),

            // Выпадающее меню: результаты или предложения мест рядом
            if (_showDropdown)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 330),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withAlpha(245),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: _controller.text.trim().isEmpty
                            ? _buildNearbySuggestions()
                            : _buildSearchResults(),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Виджет предложений «Рядом с вами», когда поле ввода пустое
  Widget _buildNearbySuggestions() {
    final nearbyPlaces = widget.nearbyPlaces;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Заголовок с кнопкой закрытия
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Row(
              children: [
                const Icon(Icons.near_me_rounded,
                    color: AppTheme.accent, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Рядом с вашей геолокацией',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'GPS',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: clearAndClose,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Быстрые категории
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: _quickCategories.map((cat) {
                final String name = cat['name'] as String;
                final IconData icon = cat['icon'] as IconData;
                final Color color = cat['color'] as Color;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _selectCategory(name),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: color.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: color.withAlpha(80), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, color: color, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              name,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          if (nearbyPlaces.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Ближайшие заведения (${nearbyPlaces.length.clamp(0, 5)})',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...(() {
              final sorted = List<Place>.from(nearbyPlaces);
              sorted.sort((a, b) {
                final da = const Distance()
                    .as(LengthUnit.Meter, _effectiveLocation, a.position);
                final db = const Distance()
                    .as(LengthUnit.Meter, _effectiveLocation, b.position);
                return da.compareTo(db);
              });
              return sorted.take(5);
            })()
                .map((place) {
              final dist = const Distance().as(
                LengthUnit.Meter,
                _effectiveLocation,
                place.position,
              );
              final distFormatted = dist < 1000
                  ? '${dist.round()} м'
                  : '${(dist / 1000).toStringAsFixed(1)} км';

              return ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                leading: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: place.color.withAlpha(35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(place.icon, color: place.color, size: 18),
                ),
                title: Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withAlpha(35),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        distFormatted,
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        place.address ?? place.type,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      place.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  _focusNode.unfocus();
                  setState(() {
                    _showDropdown = false;
                    _controller.text = place.name;
                  });
                  widget.onOpenStateChanged?.call(false);
                  final result = SearchResult(
                    title: place.name,
                    subtitle: place.address ?? 'Рядом с вами',
                    position: place.position,
                    type: place.type,
                    distanceMeters: dist,
                  );
                  widget.onResultSelected(result);
                },
              );
            }),
          ],

          // Кнопка свернуть поиск внизу
          const SizedBox(height: 6),
          Center(
            child: InkWell(
              onTap: clearAndClose,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.keyboard_arrow_up_rounded,
                        size: 16, color: Colors.white60),
                    SizedBox(width: 4),
                    Text(
                      'Свернуть поиск',
                      style: TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Виджет результатов поиска по введенному тексту
  Widget _buildSearchResults() {
    if (_displayedResults.isEmpty) {
      if (_isLoading) {
        return const SizedBox(
          height: 90,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
            ),
          ),
        );
      }

      // Если в радиусе города до 50 км ничего нет, но найдены совпадения дальше
      if (_farResults.isNotEmpty && !_showFarResults) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.travel_explore_rounded,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'В районе города (до 50 км) ничего не найдено',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Найдено дальше 50 км: ${_farResults.length}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 12),
              _buildShowOtherButton(),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ничего не найдено рядом с вами',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: clearAndClose,
              icon: const Icon(Icons.close_rounded,
                  size: 16, color: AppTheme.accent),
              label: const Text('Закрыть',
                  style: TextStyle(color: AppTheme.accent, fontSize: 12)),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Шапка результатов с кнопкой Закрыть
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              Text(
                _showFarResults
                    ? 'Все результаты: ${_displayedResults.length}'
                    : 'В районе города: ${_displayedResults.length}',
                style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
              if (!_showFarResults && _farResults.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 11,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${_farResults.length} дальше 50 км',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              InkWell(
                onTap: clearAndClose,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close_rounded,
                          size: 14, color: Colors.white70),
                      SizedBox(width: 4),
                      Text('Закрыть',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white10, height: 1),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: _displayedResults.length,
            separatorBuilder: (_, __) =>
                const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, index) {
              final item = _displayedResults[index];
              final isFar = (item.distanceMeters ?? 0) > 50000;
              return ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Icon(item.icon,
                      color: isFar ? Colors.amber : AppTheme.accent, size: 20),
                ),
                title: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      if (item.distanceFormatted != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isFar
                                ? Colors.amber.withAlpha(30)
                                : AppTheme.accent.withAlpha(35),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: isFar
                                  ? Colors.amber.withAlpha(80)
                                  : AppTheme.accent.withAlpha(80),
                              width: 0.6,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.near_me_rounded,
                                size: 9,
                                color: isFar ? Colors.amber : AppTheme.accent,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                item.distanceFormatted!,
                                style: TextStyle(
                                  color: isFar ? Colors.amber : AppTheme.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  _focusNode.unfocus();
                  setState(() {
                    _showDropdown = false;
                    _controller.text = item.title;
                  });
                  widget.onOpenStateChanged?.call(false);
                  widget.onResultSelected(item);
                },
              );
            },
          ),
        ),
        if (!_showFarResults &&
            (_farResults.isNotEmpty || !_otherResultsLoaded)) ...[
          const Divider(color: Colors.white10, height: 1),
          _buildShowOtherButton(),
        ],
      ],
    );
  }

  Widget _buildShowOtherButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: InkWell(
        onTap: _isLoadingMore ? null : _loadOtherResults,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: AppTheme.accent.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.accent.withAlpha(70),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoadingMore) ...[
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ] else ...[
                const Icon(
                  Icons.travel_explore_rounded,
                  size: 16,
                  color: AppTheme.accent,
                ),
                const SizedBox(width: 8),
              ],
              const Flexible(
                child: Text(
                  'Показать другие результаты',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
