import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../constants/app_constants.dart';
import '../styles/app_styles.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  Map<String, dynamic>? _storageStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStorageStatus();
  }

  Future<void> _loadStorageStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    final status = await StorageService.getStorageStatus();
    setState(() {
      _storageStatus = status;
      _isLoading = false;
    });
  }

  Future<void> _validateStorage() async {
    setState(() {
      _isLoading = true;
    });
    
    final result = await StorageService.validateAndRepairStorage();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ? 'Storage validated successfully' : 'Storage validation failed'),
          backgroundColor: result ? Colors.green : Colors.red,
        ),
      );
    }
    
    // Refresh status after validation
    await _loadStorageStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Storage Debug'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _storageStatus == null
              ? const Center(child: Text('Failed to load storage status'))
              : ListView(
                  padding: AppStyles.standardPadding,
                  children: [
                    _buildInfoCard('Storage Overview', [
                      _buildInfoRow('Local Path', _storageStatus!['localPath'] ?? 'Unknown'),
                      _buildInfoRow('Photo Directory', _storageStatus!['photoDirectoryPath'] ?? 'Unknown'),
                      _buildInfoRow('Directory Exists', _storageStatus!['photoDirectoryExists']?.toString() ?? 'Unknown'),
                      _buildInfoRow('Timestamp', _storageStatus!['timestamp'] ?? 'Unknown'),
                    ]),
                    
                    AppStyles.largeVerticalSpace,
                    
                    _buildInfoCard('Data Summary', [
                      _buildInfoRow('Photo Files Count', _storageStatus!['photoFilesCount']?.toString() ?? '0'),
                      _buildInfoRow('Markers in Preferences', _storageStatus!['markersInPreferences']?.toString() ?? '0'),
                      _buildInfoRow('Valid Markers', _storageStatus!['validMarkersCount']?.toString() ?? '0'),
                      _buildInfoRow('Missing Photos', _storageStatus!['missingPhotosCount']?.toString() ?? '0'),
                      _buildInfoRow('Has SharedPrefs Data', _storageStatus!['sharedPreferencesHasData']?.toString() ?? 'false'),
                    ]),
                    
                    if (_storageStatus!['missingPhotosCount'] != null && _storageStatus!['missingPhotosCount'] > 0) ...[
                      AppStyles.largeVerticalSpace,
                      _buildInfoCard('Missing Photo Paths', 
                        (_storageStatus!['missingPhotoPaths'] as List<dynamic>? ?? [])
                            .map((path) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    path.toString(),
                                    style: AppStyles.smallText.copyWith(color: Colors.red),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                    
                    if (_storageStatus!.containsKey('error')) ...[
                      AppStyles.largeVerticalSpace,
                      _buildInfoCard('Error', [
                        Text(
                          _storageStatus!['error'].toString(),
                          style: AppStyles.standardText.copyWith(color: Colors.red),
                        ),
                      ]),
                    ],
                    
                    AppStyles.largeVerticalSpace,
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _loadStorageStatus,
                            child: const Text('Refresh Status'),
                          ),
                        ),
                        AppStyles.standardHorizontalSpace,
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _validateStorage,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            child: const Text(
                              'Validate & Repair',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      decoration: AppStyles.settingsCardShadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppStyles.standardPadding,
            child: Text(
              title,
              style: AppStyles.mediumText.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: AppStyles.standardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppStyles.boldTitle,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppStyles.standardText,
            ),
          ),
        ],
      ),
    );
  }
}