import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:mobigpt/theme/appColors.dart';

class ChatInputField extends StatefulWidget {
  final ValueChanged<Message> handleSubmitted;
  final bool supportsImages;

  const ChatInputField({
    super.key,
    required this.handleSubmitted,
    this.supportsImages = false,
  });

  @override
  ChatInputFieldState createState() => ChatInputFieldState();
}

class ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty && _selectedImageBytes == null) return;

    final message = _selectedImageBytes != null
        ? Message.withImage(
            text: text.trim(),
            imageBytes: _selectedImageBytes!,
            isUser: true,
          )
        : Message.text(
            text: text.trim(),
            isUser: true,
          );

    widget.handleSubmitted(message);
    _textController.clear();
    _clearImage();
  }

  void _clearImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
  }

  Future<void> _pickImage() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (kIsWeb) {
      // Image selection not supported on web yet
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Image selection not supported on web yet'),
        ),
      );
      return;
    }

    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = pickedFile.name;
        });
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Image selection error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Input field
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.inputBorder,
              width: 1.0,
            ),
          ),
          child: Column(children: [
            if (_selectedImageBytes != null)
              Align(
                alignment: Alignment.centerRight,
                child: _buildImagePreview(),
              ),
            Row(
              children: <Widget>[
                // Plus icon on the left
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.iconPrimary),
                  onPressed: widget.supportsImages && !kIsWeb ? _pickImage : null,
                  tooltip: 'Add image',
                ),
                Flexible(
                  child: TextField(
                    controller: _textController,
                    onSubmitted: _handleSubmitted,
                    style: const TextStyle(color: AppColors.inputText, fontSize: 18),
                    decoration: const InputDecoration(
                      hintText: 'איך אני יכול לעזור?',
                      hintStyle: TextStyle(color: AppColors.inputHint),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(

                        vertical: 12.0,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                // Send button on the right - only show when text is not empty
                if (_hasText || _selectedImageBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Material(
                      color: AppColors.sendButtonBackground,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => _handleSubmitted(_textController.text),
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.arrow_upward,
                            color: AppColors.sendButtonIcon,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 8),
              ],
            )
          ]),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: AppColors.imagePreviewBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.imagePreviewBorder,
          width: 1.0,
        ),
      ),
      child: IntrinsicWidth(
        child: Stack(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image preview
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _selectedImageBytes!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),

                // Image information
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedImageName ?? 'Image',
                      style: const TextStyle(
                        color: AppColors.imagePreviewText,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(_selectedImageBytes!.length / 1024).toStringAsFixed(1)} KB',
                      style: const TextStyle(
                        color: AppColors.imagePreviewTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 50,)
              ],
            ),
            // Close button at the top-left
            Positioned(
              top: 0,
              left: 0,
              child: Material(
                color: AppColors.imagePreviewCloseBackground,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _clearImage,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.close,
                      color: AppColors.imagePreviewCloseIcon,
                      size: 16,
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
}
