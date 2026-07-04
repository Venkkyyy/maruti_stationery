import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../features/catalog/widgets/product_card.dart';
import '../../../models/product_model.dart';
import '../../../services/algolia_service.dart';

/// Full-text search screen with live results.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  
  final AlgoliaService _algoliaService = AlgoliaService();
  Timer? _debounce;
  bool _isLoading = false;
  List<ProductModel> _results = [];

  // Mock recent searches
  final List<String> _recentSearches = [
    'Parker fountain pen',
    'Moleskine notebook',
    'Pilot G2',
    'Ink bottle blue',
  ];

  // Mock popular searches
  final List<String> _popular = [
    'Fountain Pens',
    'Notebooks A5',
    'Gel Pens',
    'Markers',
    'Desk Accessories',
    'Diaries 2026',
  ];

  void _onSearchChanged(String query) {
    setState(() => _query = query);
    
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isLoading = true);
      try {
        final results = await _algoliaService.searchProducts(query: query);
        if (mounted) {
          setState(() {
            _results = results;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _results = [];
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search products, brands, SKUs...',
            hintStyle: TextStyle(color: context.colors.textHint, fontSize: 14),
            border: InputBorder.none,
            fillColor: Colors.transparent,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: context.colors.textHint, size: 20),
                    onPressed: () {
                      _controller.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
          ),
          style: TextStyle(
            fontSize: 16,
            color: context.colors.textPrimary,
          ),
        ),
      ),
      body: _query.isEmpty ? _buildDiscovery() : _buildResults(),
    );
  }

  Widget _buildDiscovery() {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.screenHorizontal),
      children: [
        // Recent searches
        if (_recentSearches.isNotEmpty) ...[
          _SectionHeader(
            title: 'Recent Searches',
            onClear: () => setState(() => _recentSearches.clear()),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((s) => _SearchChip(
                  label: s,
                  icon: Icons.history_rounded,
                  onTap: () {
                    _controller.text = s;
                    _onSearchChanged(s);
                  },
                )).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Popular searches
        _SectionHeader(title: 'Popular Searches'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popular.map((s) => _SearchChip(
                label: s,
                icon: Icons.trending_up_rounded,
                color: context.colors.primaryLight,
                textColor: context.colors.primary,
                onTap: () {
                  _controller.text = s;
                  _onSearchChanged(s);
                },
              )).toList(),
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final results = _results;

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64, color: context.colors.border),
            SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No products match "$_query"',
              style: TextStyle(
                  color: context.colors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Result count bar
        Container(
          color: context.colors.surface,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.lg, vertical: 10),
          child: Row(
            children: [
              Text(
                '${results.length} results for "$_query"',
                style: TextStyle(
                  fontSize: 13,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Results grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(AppSizes.screenHorizontal),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: results.length,
            itemBuilder: (context, i) => ProductCard(
              product: results[i],
              onAddToCart: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Added to bag!'),
                    backgroundColor: context.colors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onClear;

  const _SectionHeader({required this.title, this.onClear});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: context.colors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        if (onClear != null)
          GestureDetector(
            onTap: onClear,
            child: Text(
              'Clear',
              style: TextStyle(
                fontSize: 12,
                color: context.colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final Color? textColor;
  final VoidCallback? onTap;

  const _SearchChip({
    required this.label,
    required this.icon,
    this.color,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color ?? context.colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: textColor ?? context.colors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor ?? context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}






