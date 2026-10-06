import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../app_theme.dart';
import '../models/search_result.dart';
import '../services/search_service.dart';

class FloatingSearchBar extends StatefulWidget {
  final LatLng? userLocation;
  final ValueChanged<SearchResult> onResultSelected;
  final VoidCallback onClear;

  const FloatingSearchBar({
    super.key,
    this.userLocation,
    required this.onResultSelected,
    required this.onClear,
  });

  @override
  State<FloatingSearchBar> createState() => _FloatingSearchBarState();
}

class _FloatingSearchBarState extends State<FloatingSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _isLoading = false;
  List<SearchResult> _results = [];
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _showDropdown = _focusNode.hasFocus && _results.isNotEmpty;
      });
    });
  }

  void _onQueryChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
        _showDropdown = false;
      });
      widget.onClear();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() {
        _isLoading = true;
      });

      try {
        final results = await SearchService.search(
          query,
          proximity: widget.userLocation,
        );
        if (!mounted) return;
        setState(() {
          _results = results;
          _isLoading = false;
          _showDropdown = true;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _results = [];
      _isLoading = false;
      _showDropdown = false;
    });
    _focusNode.unfocus();
    widget.onClear();
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface.withAlpha(200),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withAlpha(35), width: 1.2),
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
              hintText: 'Поиск мест, адресов, улиц...',
              hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
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
                  : _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            color: Colors.white60,
                            size: 20,
                          ),
                          onPressed: _clearSearch,
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
        if (_showDropdown && _results.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: _results.length,
              separatorBuilder: (_, _) =>
                  const Divider(color: Colors.white10, height: 1),
              itemBuilder: (context, index) {
                final item = _results[index];
                return ListTile(
                  dense: true,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: AppTheme.accent, size: 20),
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
                  subtitle: Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  onTap: () {
                    _focusNode.unfocus();
                    setState(() {
                      _showDropdown = false;
                      _controller.text = item.title;
                    });
                    widget.onResultSelected(item);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
