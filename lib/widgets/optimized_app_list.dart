import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import '../models/app_info.dart';
import '../services/app_service.dart';

/// Highly optimized app list widget with lazy loading and efficient rendering
class OptimizedAppList extends StatefulWidget {
  final List<AppInfo> apps;
  final Function(AppInfo)? onAppTap;
  final Function(AppInfo)? onAppLongPress;
  final bool showIcons;
  final double itemHeight;

  const OptimizedAppList({
    super.key,
    required this.apps,
    this.onAppTap,
    this.onAppLongPress,
    this.showIcons = true,
    this.itemHeight = 72.0,
  });

  @override
  State<OptimizedAppList> createState() => _OptimizedAppListState();
}

class _OptimizedAppListState extends State<OptimizedAppList> 
    with AutomaticKeepAliveClientMixin {
  
  final Map<String, Uint8List?> _iconCache = {};
  final Set<String> _loadingIcons = {};
  late ScrollController _scrollController;
  
  // Performance optimization: Only load icons for visible items
  final Set<int> _visibleIndices = {};
  static const int _preloadBuffer = 5; // Load icons 5 items ahead

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Listen to scroll events for lazy loading
    _scrollController.addListener(_onScroll);
    
    // Pre-load first few icons
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadVisibleIcons();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Calculate visible range and preload icons
    final scrollOffset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;
    
    final startIndex = (scrollOffset / widget.itemHeight).floor();
    final endIndex = ((scrollOffset + viewportHeight) / widget.itemHeight).ceil();
    
    // Update visible indices
    _visibleIndices.clear();
    for (int i = startIndex; i <= endIndex + _preloadBuffer && i < widget.apps.length; i++) {
      if (i >= 0) {
        _visibleIndices.add(i);
      }
    }
    
    // Load icons for visible items
    _loadVisibleIcons();
  }

  void _preloadVisibleIcons() {
    // Load first 10 icons immediately
    for (int i = 0; i < 10 && i < widget.apps.length; i++) {
      _visibleIndices.add(i);
    }
    _loadVisibleIcons();
  }

  void _loadVisibleIcons() {
    if (!widget.showIcons) return;
    
    for (final index in _visibleIndices) {
      if (index < widget.apps.length) {
        final app = widget.apps[index];
        _loadIconIfNeeded(app.packageName);
      }
    }
  }

  Future<void> _loadIconIfNeeded(String packageName) async {
    if (_iconCache.containsKey(packageName) || _loadingIcons.contains(packageName)) {
      return;
    }

    _loadingIcons.add(packageName);
    
    try {
      final icon = await AppService.getAppIcon(packageName);
      if (mounted) {
        setState(() {
          _iconCache[packageName] = icon;
        });
      }
    } catch (e) {
      print('Error loading icon for $packageName: $e');
    } finally {
      _loadingIcons.remove(packageName);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (widget.apps.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apps, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'কোন অ্যাপ পাওয়া যায়নি',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.apps.length,
      itemExtent: widget.itemHeight, // Fixed height for better performance
      cacheExtent: widget.itemHeight * 20, // Cache 20 items
      physics: const BouncingScrollPhysics(), // Smooth scrolling
      itemBuilder: (context, index) {
        return _OptimizedAppListItem(
          key: ValueKey(widget.apps[index].packageName),
          app: widget.apps[index],
          icon: _iconCache[widget.apps[index].packageName],
          showIcon: widget.showIcons,
          onTap: widget.onAppTap,
          onLongPress: widget.onAppLongPress,
          isIconLoading: _loadingIcons.contains(widget.apps[index].packageName),
        );
      },
    );
  }
}

/// Optimized individual app list item
class _OptimizedAppListItem extends StatelessWidget {
  final AppInfo app;
  final Uint8List? icon;
  final bool showIcon;
  final Function(AppInfo)? onTap;
  final Function(AppInfo)? onLongPress;
  final bool isIconLoading;

  const _OptimizedAppListItem({
    super.key,
    required this.app,
    this.icon,
    required this.showIcon,
    this.onTap,
    this.onLongPress,
    this.isIconLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      color: Colors.grey[900],
      child: InkWell(
        onTap: onTap != null ? () => onTap!(app) : null,
        onLongPress: onLongPress != null ? () => onLongPress!(app) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // App Icon with optimized loading
              if (showIcon) ...[
                SizedBox(
                  width: 48,
                  height: 48,
                  child: _buildAppIcon(),
                ),
                const SizedBox(width: 12),
              ],
              
              // App Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      app.displayName ?? app.appName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app.packageName,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Status indicators
              if (app.isCloned) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 152, 0, 0.2),***********************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange, width: 1),
                  ),
                  child: Text(
                    'Clone ${app.cloneCount ?? 1}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppIcon() {
    if (isIconLoading) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
        ),
      );
    }

    if (icon != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          icon!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
        ),
      );
    }

    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: app.color ?? Colors.grey[700],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.android,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
