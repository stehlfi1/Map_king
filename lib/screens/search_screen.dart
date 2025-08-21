import 'dart:async';
import 'package:flutter/material.dart';
import '../models/search_result.dart';
import '../services/search_service.dart';
import '../constants/app_constants.dart';
import '../styles/app_styles.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<SearchResult> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: AppConstants.debounceDelayMs), () {
      _performSearch(_searchController.text);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = '';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await SearchService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppConstants.searchFailedMessage;
          _isLoading = false;
          _searchResults = [];
        });
      }
    }
  }

  void _selectResult(SearchResult result) {
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: AppConstants.searchBarHeight,
          decoration: AppStyles.searchBarDecoration,
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: 'Search places...',
              hintStyle: AppStyles.lightGreyText(context),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey.shade500),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _errorMessage = '';
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppConstants.largePadding, 
                vertical: AppConstants.compactPadding
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_isLoading)
            Container(
              padding: AppStyles.standardPadding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: AppConstants.mediumIconSize,
                    height: AppConstants.mediumIconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: AppConstants.circularProgressStrokeWidth,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                    ),
                  ),
                  AppStyles.standardHorizontalSpace,
                  Text(
                    'Searching...',
                    style: AppStyles.subtitleText(context),
                  ),
                ],
              ),
            ),
          
          if (_errorMessage.isNotEmpty)
            Container(
              padding: AppStyles.standardPadding,
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600, size: AppConstants.mediumIconSize),
                  AppStyles.standardHorizontalSpace,
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: AppStyles.errorText(context),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _searchResults.isEmpty && !_isLoading && _errorMessage.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, index) => Divider(
                      height: AppConstants.dividerHeight,
                      color: Colors.grey.shade200,
                    ),
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      return _buildSearchResultTile(result);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: AppConstants.extraLargeIconSize,
            color: Colors.grey.shade400,
          ),
          AppStyles.largeVerticalSpace,
          Text(
            'Search for places',
            style: AppStyles.largeTitle.copyWith(color: Colors.grey.shade600),
          ),
          AppStyles.smallVerticalSpace,
          Text(
            'Find restaurants, landmarks, cities, and more',
            style: AppStyles.subtitleText(context).copyWith(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultTile(SearchResult result) {
    return ListTile(
      leading: Container(
        width: AppConstants.listTileIconSize,
        height: AppConstants.listTileIconSize,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(AppConstants.listTileIconSize / 2),
        ),
        child: Icon(
          _getIconForType(result.type),
          color: Colors.blue.shade600,
          size: AppConstants.mediumIconSize,
        ),
      ),
      title: Text(
        result.shortName,
        style: AppStyles.listTileTitle,
        maxLines: AppConstants.maxLinesSingle,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        result.subtitle.isNotEmpty ? result.subtitle : result.displayName,
        style: AppStyles.listTileSubtitle(context),
        maxLines: AppConstants.maxLinesDouble,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(
        Icons.north_west,
        color: Colors.grey,
        size: AppConstants.mediumIconSize,
      ),
      onTap: () => _selectResult(result),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'restaurant':
      case 'cafe':
      case 'food':
        return Icons.restaurant;
      case 'hotel':
      case 'accommodation':
        return Icons.hotel;
      case 'shop':
      case 'retail':
        return Icons.shopping_bag;
      case 'hospital':
      case 'clinic':
        return Icons.local_hospital;
      case 'school':
      case 'university':
        return Icons.school;
      case 'park':
      case 'leisure':
        return Icons.park;
      case 'museum':
      case 'tourism':
        return Icons.museum;
      case 'church':
      case 'place_of_worship':
        return Icons.church;
      case 'city':
      case 'town':
      case 'village':
        return Icons.location_city;
      default:
        return Icons.place;
    }
  }
}