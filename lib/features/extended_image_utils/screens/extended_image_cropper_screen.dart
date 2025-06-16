import 'dart:io';
import 'dart:typed_data';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:image_editor/image_editor.dart'; 
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as developer;

class ExtendedImageCropperScreen extends StatefulWidget {
  final XFile imageFile;

  const ExtendedImageCropperScreen({super.key, required this.imageFile});

  @override
  State<ExtendedImageCropperScreen> createState() =>
      _ExtendedImageCropperScreenState();
}

class _ExtendedImageCropperScreenState
    extends State<ExtendedImageCropperScreen> {
  final GlobalKey<ExtendedImageEditorState> _editorKey =
      GlobalKey<ExtendedImageEditorState>();
  double? _currentCropAspectRatio = CropAspectRatios.ratio1_1;

  @override
  void initState() {
    super.initState();
    developer.log('ExtendedImageCropperScreen: initState with imageFile: ${widget.imageFile.path}', name: 'ExtendedImageCropperScreen');
  }

  @override
  Widget build(BuildContext context) {
    developer.log('ExtendedImageCropperScreen: build method called. Image path: ${widget.imageFile.path}', name: 'ExtendedImageCropperScreen');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Image (Extended)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _cropImage, // This now directly confirms and pops
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ExtendedImage.file(
              File(widget.imageFile.path),
              fit: BoxFit.contain,
              mode: ExtendedImageMode.editor,
              extendedImageEditorKey: _editorKey,
              initEditorConfigHandler: (ExtendedImageState? state) {
                developer.log('ExtendedImageCropperScreen: initEditorConfigHandler called. Aspect ratio: $_currentCropAspectRatio', name: 'ExtendedImageCropperScreen');
                return EditorConfig(
                  maxScale: 8.0,
                  cropRectPadding: const EdgeInsets.all(20.0),
                  hitTestSize: 20.0,
                  cropAspectRatio: _currentCropAspectRatio,
                  cornerColor: Colors.blue,
                  cornerSize: const Size(20, 5),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildFunctions(),
    );
  }

  Widget _buildFunctions() {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.flip),
          label: 'Flip',
        ),
        // BottomNavigationBarItem(
        //   icon: Icon(Icons.rotate_left),
        //   label: 'Rotate Left',
        // ),
        // BottomNavigationBarItem(
        //   icon: Icon(Icons.rotate_right),
        //   label: 'Rotate Right',
        // ),
        BottomNavigationBarItem(
          icon: Icon(Icons.aspect_ratio),
          label: 'Aspect Ratio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restore),
          label: 'Reset',
        ),
      ],
      onTap: (int index) {
        final editor = _editorKey.currentState;
        if (editor == null) return;

        switch (index) {
          case 0: // Was Flip
            editor.flip();
            break;
          // case 1: // Was Rotate Left
          //   // editor.rotate(right: false); 
          //   break;
          // case 2: // Was Rotate Right
          //   // editor.rotate(right: true); 
          //   break;
          case 1: // Now Aspect Ratio (index adjusted)
            _showAspectRatioDialog();
            break;
          case 2: // Now Reset (index adjusted)
            editor.reset();
            break;
        }
      },
      currentIndex: 0,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
    );
  }

  Future<void> _cropImage() async {
    developer.log('ExtendedImageCropperScreen: _cropImage started.', name: 'ExtendedImageCropperScreen');
    final ExtendedImageEditorState? editor = _editorKey.currentState;
    if (editor == null) {
      developer.log('ExtendedImageCropperScreen: Editor not ready.', name: 'ExtendedImageCropperScreen');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Editor not ready.')),
      );
      return;
    }

    final Rect? cropRect = editor.getCropRect();
    developer.log('ExtendedImageCropperScreen: Crop rect: $cropRect', name: 'ExtendedImageCropperScreen');
    if (cropRect == null) {
      developer.log('ExtendedImageCropperScreen: Crop rectangle is not set.', name: 'ExtendedImageCropperScreen');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Crop rectangle is not set.')),
      );
      return;
    }

    final Uint8List? imgData = editor.rawImageData;
    developer.log('ExtendedImageCropperScreen: Raw image data length: ${imgData?.lengthInBytes}', name: 'ExtendedImageCropperScreen');
    if (imgData == null) {
      developer.log('ExtendedImageCropperScreen: Could not get image data.', name: 'ExtendedImageCropperScreen');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Could not get image data.')),
      );
      return;
    }

    Uint8List? result;
    try {
      developer.log('ExtendedImageCropperScreen: Calling ImageEditor.editImage', name: 'ExtendedImageCropperScreen');
      // Define the crop option
      final ImageEditorOption option = ImageEditorOption();
      option.addOption(ClipOption(
        x: cropRect.left.toDouble(),
        y: cropRect.top.toDouble(),
        width: cropRect.width.toDouble(),
        height: cropRect.height.toDouble(),
      ));

      result = await ImageEditor.editImage(
        image: imgData,
        imageEditorOption: option, // Pass the defined option
      );
      developer.log('ExtendedImageCropperScreen: ImageEditor.editImage result length: ${result?.lengthInBytes}', name: 'ExtendedImageCropperScreen');

    } catch (e, s) { 
      developer.log('ExtendedImageCropperScreen: Error during cropping: $e\n$s', name: 'ExtendedImageCropperScreen', error: e, stackTrace: s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during cropping: $e')),
      );
      return;
    }

    if (result == null) {
      developer.log('ExtendedImageCropperScreen: Cropping failed, result is null.', name: 'ExtendedImageCropperScreen');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Cropping failed, result is null.')),
      );
      return;
    }

    final tempDir = await Directory.systemTemp.createTemp('extended_image_crop');
    final File tempFile = File(
        '${tempDir.path}/cropped_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(result);
    developer.log('ExtendedImageCropperScreen: Cropped image saved to ${tempFile.path}', name: 'ExtendedImageCropperScreen');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image cropped successfully! Returning...')),
    );
    
    // Pop with the cropped file directly
    // Adding a small delay for the SnackBar to be visible, then pop.
    // If no SnackBar is desired, this can be removed and pop immediately.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pop(context, tempFile);
      }
    });

  }

  void _showAspectRatioDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Aspect Ratio'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                ListTile(
                  title: const Text('Custom'),
                  onTap: () {
                    _setAspectRatio(null);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Original'),
                  onTap: () {
                    _setAspectRatio(CropAspectRatios.original);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('1:1'),
                  onTap: () {
                    _setAspectRatio(CropAspectRatios.ratio1_1);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('4:3'),
                  onTap: () {
                    _setAspectRatio(CropAspectRatios.ratio4_3);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('3:4'),
                  onTap: () {
                    _setAspectRatio(CropAspectRatios.ratio3_4);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('16:9'),
                  onTap: () {
                    _setAspectRatio(CropAspectRatios.ratio16_9);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('9:16'),
                  onTap: () {
                    _setAspectRatio(CropAspectRatios.ratio9_16);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _setAspectRatio(double? aspectRatio) {
    setState(() {
      _currentCropAspectRatio = aspectRatio;
    });
  }
}

class CropAspectRatios {
  static const double? custom = null;
  static const double original = 0.0;
  static const double ratio1_1 = 1.0;
  static const double ratio4_3 = 4.0 / 3.0;
  static const double ratio3_4 = 3.0 / 4.0;
  static const double ratio16_9 = 16.0 / 9.0;
  static const double ratio9_16 = 9.0 / 16.0;
}
