import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  final bool showCoordinates;
  final double defaultZoom;
  final bool enableHaptics;
  
  const SettingsScreen({
    super.key,
    required this.showCoordinates,
    required this.defaultZoom,
    required this.enableHaptics,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _enableHaptics;
  late bool _showCoordinatesInInfo;
  late String _defaultMapZoom;
  
  @override
  void initState() {
    super.initState();
    _showCoordinatesInInfo = widget.showCoordinates;
    _defaultMapZoom = widget.defaultZoom.toString();
    _enableHaptics = widget.enableHaptics;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, {
              'showCoordinates': _showCoordinatesInInfo,
              'defaultZoom': double.parse(_defaultMapZoom),
              'enableHaptics': _enableHaptics,
            });
          },
        ),
      ),
      body: ListView(
        children: [
          _buildSection(
            title: 'Map Settings',
            children: [
              _buildSwitchTile(
                title: 'Show Coordinates',
                subtitle: 'Display GPS coordinates in info banner',
                value: _showCoordinatesInInfo,
                onChanged: (value) {
                  setState(() {
                    _showCoordinatesInInfo = value;
                  });
                },
                icon: Icons.location_on,
              ),
              _buildTile(
                title: 'Default Zoom Level',
                subtitle: _defaultMapZoom,
                icon: Icons.zoom_in,
                onTap: () => _showZoomSelector(),
              ),
            ],
          ),
          
          
          _buildSection(
            title: 'Experience',
            children: [
              _buildSwitchTile(
                title: 'Haptic Feedback',
                subtitle: 'Vibrate when taking photos or placing markers',
                value: _enableHaptics,
                onChanged: (value) {
                  setState(() {
                    _enableHaptics = value;
                  });
                },
                icon: Icons.vibration,
              ),
            ],
          ),
          
          _buildSection(
            title: 'Storage',
            children: [
              _buildTile(
                title: 'Clear All Data',
                subtitle: 'Delete all photos and markers',
                icon: Icons.delete_forever,
                iconColor: Colors.red,
                onTap: () => _showClearDataDialog(),
              ),
            ],
          ),
          
          _buildSection(
            title: 'Help & Info',
            children: [
              _buildTile(
                title: 'FAQ',
                subtitle: 'Frequently asked questions',
                icon: Icons.help,
                onTap: () => _showFAQ(),
              ),
              _buildTile(
                title: 'About',
                subtitle: 'App information and developer',
                icon: Icons.info,
                onTap: () => _showAbout(),
              ),
            ],
          ),
          
          const SizedBox(height: 50),
        ],
      ),
    );
  }
  
  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
  
  Widget _buildTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.blue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.blue,
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
  
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.blue,
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue,
      ),
    );
  }
  
  void _showZoomSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Default Zoom Level', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...['8.0', '10.0', '12.0', '14.0', '16.0'].map((zoom) =>
              ListTile(
                title: Text('${zoom} ${zoom == '8.0' ? '(Far)' : zoom == '16.0' ? '(Close)' : ''}'),
                trailing: _defaultMapZoom == zoom ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () {
                  setState(() {
                    _defaultMapZoom = zoom;
                  });
                  Navigator.pop(context);
                },
              ),
            ).toList(),
          ],
        ),
      ),
    );
  }
  
  
  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your photos and markers. This action cannot be undone.\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await StorageService.clearAllData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared successfully')),
                );
                Navigator.pop(context); // Return to main screen
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
  
  
  void _showFAQ() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Frequently Asked Questions'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Q: How do I add photos to the map?', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('A: Tap the blue camera button and choose to take a photo or select from gallery. Photos are placed at the red crosshair location.\n'),
              
              Text('Q: Why don\'t I see my current location?', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('A: Make sure you\'ve granted location permission. Tap the location button and allow access in Settings.\n'),
              
              Text('Q: Can I move existing photos?', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('A: Currently, photos cannot be moved. You can delete and re-add them at a new location.\n'),
              
              Text('Q: How do I view my photos?', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('A: Tap any photo marker on the map to view the full image and details.\n'),
              
              Text('Q: Are my photos backed up?', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('A: Photos are stored locally on your device. Enable auto-backup in Settings for cloud storage.\n'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Map Photo App'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Map Photo App',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text('Version 1.0.0\n'),
            
            const Text(
              'A simple and elegant way to capture and organize your photos on a map. Perfect for travel memories, location scouting, and documenting your adventures.\n',
            ),
            
            const Text('🗺️ Powered by OpenStreetMap'),
            const Text('📱 Built with Flutter\n'),
            
            const Text(
              'Developer',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('Filip Stehlik\n'),
            
            const Text(
              'Features',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• Take photos and place them on map'),
            const Text('• View photo thumbnails as markers'),
            const Text('• GPS location support'),
            const Text('• Local storage with no cloud dependency'),
            const Text('• Clean, modern interface'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}