import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'models/photo.dart';
import 'services/unsplash_api.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  List<Photo> _photos = [];
  String _query = '';
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _page = 1;
  int _totalPages = 1;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search(); // initial "popular" load
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _query = value.trim();
      _page = 1;
      _photos = [];
      _search();
    });
  }

  void _onScroll() {
    if (_isLoadingMore || _isLoading) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      if (_page < _totalPages) _loadMore();
    }
  }

  Future<void> _search() async {
    setState(() => _isLoading = true);
    try {
      final data = await UnsplashApi.search(query: _query, page: _page);
      setState(() {
        _photos = data.items;
        _totalPages = data.totalPages;
      });
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _page + 1;
      final data = await UnsplashApi.search(query: _query, page: nextPage);
      setState(() {
        _page = nextPage;
        _photos.addAll(data.items);
      });
    } catch (e) {
      _showSnack('Error loading more: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: topPadding == 0 ? 8 : 0),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: _SearchBar(
                controller: _controller,
                onChanged: _onChanged,
                onClear: () {
                  _controller.clear();
                  _onChanged('');
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading && _photos.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () async {
                        _page = 1;
                        _photos = [];
                        await _search();
                      },
                      child: GridView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _photos.length + (_isLoadingMore ? 2 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _photos.length) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final p = _photos[index];
                          return _PhotoTile(photo: p);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search images…',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.clear),
                tooltip: 'Clear',
              ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final Photo photo;
  const _PhotoTile({required this.photo});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openDetails(context, photo),
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Hero(
                tag: photo.id,
                child: CachedNetworkImage(
                  imageUrl: photo.fullUrl,
                  fit: BoxFit.cover,
                  placeholder: (c, _) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (c, _, __) => const Center(child: Icon(Icons.broken_image)),
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(
                    photo.altDescription.isNotEmpty ? photo.altDescription : photo.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetails(BuildContext context, Photo p) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _DetailsPage(photo: p),
    ));
  }
}

class _DetailsPage extends StatelessWidget {
  final Photo photo;
  const _DetailsPage({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: Center(
        child: Hero(
          tag: photo.id,
          child: CachedNetworkImage(
            imageUrl: photo.fullUrl,
            fit: BoxFit.contain,
            placeholder: (c, _) => const Center(child: CircularProgressIndicator()),
            errorWidget: (c, _, __) => const Icon(Icons.broken_image),
          ),
        ),
      ),
    );
  }
}
