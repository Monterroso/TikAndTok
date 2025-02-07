import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/search.dart';
import '../models/video.dart';
import '../services/firestore_service.dart';

class SearchController extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final SharedPreferences _prefs;
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 5;
  Timer? _debounceTimer;

  SearchState _state = SearchState.initial();
  SearchState get state => _state;

  SearchController({
    required FirestoreService firestoreService,
    required SharedPreferences prefs,
  })  : _firestoreService = firestoreService,
        _prefs = prefs {
    _loadRecentSearches();
  }

  void _loadRecentSearches() {
    final searches = _prefs.getStringList(_recentSearchesKey) ?? [];
    _state = _state.copyWith(recentSearches: searches);
    notifyListeners();
  }

  Future<void> search(String query) async {
    if (query.length < 2) {
      _state = SearchState.initial();
      notifyListeners();
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        _state = SearchState.loading(query);
        notifyListeners();

        final videoResults = await _firestoreService.searchVideos(query);
        final userResults = await _firestoreService.searchUsers(query);

        _state = _state.copyWith(
          isLoading: false,
          videoResults: videoResults,
          userResults: userResults,
        );

        await _addToRecentSearches(query);
      } catch (e) {
        _state = SearchState.error(query, e.toString());
      } finally {
        notifyListeners();
      }
    });
  }

  Future<void> _addToRecentSearches(String query) async {
    if (query.isEmpty) return;

    final searches = List<String>.from(_state.recentSearches);
    
    // Remove if exists and add to front
    searches.remove(query);
    searches.insert(0, query);
    
    // Keep only the most recent searches
    if (searches.length > _maxRecentSearches) {
      searches.removeRange(_maxRecentSearches, searches.length);
    }

    await _prefs.setStringList(_recentSearchesKey, searches);
    _state = _state.copyWith(recentSearches: searches);
  }

  Future<void> clearRecentSearches() async {
    await _prefs.remove(_recentSearchesKey);
    _state = _state.copyWith(recentSearches: []);
    notifyListeners();
  }

  Future<List<Video>> loadMoreVideos() async {
    if (_state.query.isEmpty || _state.isLoading) return [];

    try {
      final moreVideos = await _firestoreService.searchVideos(
        _state.query,
        startAfter: _state.videoResults.lastOrNull,
      );

      _state = _state.copyWith(
        videoResults: [..._state.videoResults, ...moreVideos],
      );
      notifyListeners();

      return moreVideos;
    } catch (e) {
      // Don't update state for pagination errors
      debugPrint('Error loading more videos: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
} 