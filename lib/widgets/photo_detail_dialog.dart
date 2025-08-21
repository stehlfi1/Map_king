import 'dart:io';
import 'package:flutter/material.dart';
import '../models/photo_marker.dart';
import '../constants/app_constants.dart';
import '../styles/app_styles.dart';

class PhotoDetailDialog extends StatefulWidget {
  final PhotoMarker photoMarker;
  final VoidCallback onDelete;
  final Function(PhotoMarker) onUpdate;

  const PhotoDetailDialog({
    super.key,
    required this.photoMarker,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<PhotoDetailDialog> createState() => _PhotoDetailDialogState();
}

class _PhotoDetailDialogState extends State<PhotoDetailDialog> {
  late TextEditingController _commentController;
  bool _isEditingComment = false;
  late PhotoMarker _currentMarker;

  @override
  void initState() {
    super.initState();
    _currentMarker = widget.photoMarker;
    _commentController = TextEditingController(text: _currentMarker.comment ?? '');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            title: const Text(AppConstants.photoDetailsTitle),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _showDeleteConfirmation(context);
                },
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppConstants.standardBorderRadius),
                    child: Image.file(
                      File(_currentMarker.imagePath),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, size: AppConstants.extraLargeIconSize, color: Colors.grey),
                                Text('Image not found'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: AppStyles.standardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_currentMarker.description != null) ...[
                          const Text(
                            'Description',
                            style: AppStyles.boldTitle,
                          ),
                          AppStyles.smallVerticalSpace,
                          Text(
                            _currentMarker.description!,
                            style: AppStyles.standardText,
                          ),
                          AppStyles.mediumVerticalSpace,
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Comment',
                              style: AppStyles.boldTitle,
                            ),
                            IconButton(
                              icon: Icon(_isEditingComment ? Icons.check : Icons.edit),
                              onPressed: _isEditingComment ? _saveComment : () {
                                setState(() {
                                  _isEditingComment = true;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        AppStyles.smallVerticalSpace,
                        if (_isEditingComment)
                          TextField(
                            controller: _commentController,
                            decoration: AppStyles.commentInputDecoration,
                            maxLines: 3,
                            autofocus: true,
                          )
                        else
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isEditingComment = true;
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              padding: AppStyles.largePadding,
                              decoration: AppStyles.commentContainer,
                              child: Text(
                                _currentMarker.comment?.isEmpty == false 
                                    ? _currentMarker.comment! 
                                    : 'Tap to add a comment...',
                                style: _currentMarker.comment?.isEmpty == false 
                                    ? AppStyles.standardText
                                    : AppStyles.greyText(context),
                              ),
                            ),
                          ),
                        AppStyles.mediumVerticalSpace,
                        const Text(
                          'Location',
                          style: AppStyles.boldTitle,
                        ),
                        AppStyles.smallVerticalSpace,
                        Text(
                          'Lat: ${_currentMarker.latitude.toStringAsFixed(6)}\nLng: ${_currentMarker.longitude.toStringAsFixed(6)}',
                          style: AppStyles.standardText,
                        ),
                        AppStyles.mediumVerticalSpace,
                        const Text(
                          'Taken',
                          style: AppStyles.boldTitle,
                        ),
                        AppStyles.smallVerticalSpace,
                        Text(
                          _formatDateTime(_currentMarker.timestamp),
                          style: AppStyles.standardText,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: AppStyles.standardPadding,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveComment() {
    final updatedMarker = _currentMarker.copyWith(
      comment: _commentController.text.trim(),
    );
    widget.onUpdate(updatedMarker);
    setState(() {
      _currentMarker = updatedMarker;
      _isEditingComment = false;
    });
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppConstants.deletePhotoTitle),
        content: const Text('Are you sure you want to delete this photo marker? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close confirmation dialog
              Navigator.of(context).pop(); // Close photo detail dialog
              widget.onDelete();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$month $day, $year at $hour:$minute';
  }
}