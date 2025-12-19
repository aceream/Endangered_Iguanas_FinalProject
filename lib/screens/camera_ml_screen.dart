import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class CameraMlScreen extends StatefulWidget {
  final int? selectedClassId;
  final String? selectedClassName;

  const CameraMlScreen({
    super.key,
    this.selectedClassId,
    this.selectedClassName,
  });

  @override
  State<CameraMlScreen> createState() => _CameraMlScreenState();
}

class _CameraMlScreenState extends State<CameraMlScreen> {
  final ImagePicker _picker = ImagePicker();
  Interpreter? _interpreter;
  List<String> _labels = [];
  Map<String, double>? _predictions;
  File? _imageFile;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadModelAndLabels();
  }

  Future<void> _loadModelAndLabels() async {
    try {
      final byteData = await rootBundle.load('assets/model/model_unquant.tflite');
      final buffer = byteData.buffer.asUint8List();
      final tempDir = Directory.systemTemp;
      final modelFile = File('${tempDir.path}/model_unquant.tflite');
      await modelFile.writeAsBytes(buffer);

      _interpreter = Interpreter.fromFile(modelFile);

      final labelsRaw = await rootBundle.loadString('assets/model/labels.txt');
      _labels = labelsRaw
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint('Error loading model/labels: $e');
      if (mounted) {
        setState(() {
          _predictions = {'Failed to load model': 1.0};
        });
      }
    }
  }

  Future<void> _pickImage({required ImageSource source}) async {
    if (_interpreter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model not loaded yet')),
      );
      return;
    }

    final XFile? picked = await _picker.pickImage(source: source, maxWidth: 640);
    if (picked == null) return;

    setState(() {
      _busy = true;
      _imageFile = File(picked.path);
      _predictions = null;
    });

    try {
      await _runInference(_imageFile!);
    } catch (e) {
      debugPrint('Inference error: $e');
      setState(() {
        _predictions = {'Error': 1.0};
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _runInference(File imageFile) async {
    const int inputSize = 224;
    const double meanR = 0.485;
    const double meanG = 0.456;
    const double meanB = 0.406;
    const double stdR = 0.229;
    const double stdG = 0.224;
    const double stdB = 0.225;

    final bytes = await imageFile.readAsBytes();
    var decoded = img.decodeImage(bytes);
    if (decoded == null) {
      setState(() {
        _predictions = {'Failed to decode image': 1.0};
      });
      return;
    }

    decoded = img.bakeOrientation(decoded);

    img.Image processed = decoded;
    if (decoded.width != inputSize || decoded.height != inputSize) {
      final aspectRatio = decoded.width / decoded.height;
      int newWidth, newHeight;
      
      if (aspectRatio > 1) {
        newHeight = inputSize;
        newWidth = (inputSize * aspectRatio).toInt();
      } else {
        newWidth = inputSize;
        newHeight = (inputSize / aspectRatio).toInt();
      }
      
      processed = img.copyResize(decoded, width: newWidth, height: newHeight);
      
      final cropX = ((newWidth - inputSize) / 2).toInt().clamp(0, newWidth);
      final cropY = ((newHeight - inputSize) / 2).toInt().clamp(0, newHeight);
      processed = img.copyCrop(processed, x: cropX, y: cropY, width: inputSize, height: inputSize);
    }

    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = processed.getPixel(x, y);
            final r = (pixel.r / 255.0 - meanR) / stdR;
            final g = (pixel.g / 255.0 - meanG) / stdG;
            final b = (pixel.b / 255.0 - meanB) / stdB;
            return [r, g, b];
          },
        ),
      ),
    );

    final output = [List.filled(_labels.length, 0.0)];

    _interpreter!.run(input, output);

    final scores = output[0];
    // ... [existing logic for processing scores]

    final predictions = <String, double>{};
    int bestIndex = 0;
    double bestScore = scores[0];
    
    for (var i = 0; i < scores.length; i++) {
        // Simple softmax approximation or just raw scores if model output is already prob
        // Assuming model output is raw logits or pre-softmax, or just verifying standard logic
        // The previous code did clamp(0,100), usually tflite output is 0-255 (quant) or 0-1 (float)
        // If float 0-1, multiplying by 100 is correct.
      final percentage = (scores[i] * 100).clamp(0, 100).toDouble();
      predictions[_labels[i]] = percentage;
      if (scores[i] > bestScore) {
        bestScore = scores[i];
        bestIndex = i;
      }
    }
    
    // Sort predictions
    final sortedEntries = predictions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedPredictions = Map.fromEntries(sortedEntries);

    if (mounted) {
      setState(() {
        _predictions = sortedPredictions;
      });
    }

    final bestLabel = _labels[bestIndex];
    if (bestScore > 0.5) { // Only save if confident enough
        await _saveToFirestore(label: bestLabel, score: bestScore, imagePath: imageFile.path);
    }
  }

  Future<void> _saveToFirestore({required String label, required double score, required String imagePath}) async {
    try {
      await FirebaseFirestore.instance.collection('predictions').add({
        'label': label,
        'score': score,
        'imagePath': imagePath, // Note: This is local path, in real app should upload to Storage
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving to Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Content
          Column(
            children: [
              // Image Area
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  color: Colors.black,
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'No image selected',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                ),
              ),
              
              // Results Area
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: _buildResultsPanel(theme),
                ),
              ),
            ],
          ),
          
          // Loading Overlay
          if (_busy)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsPanel(ThemeData theme) {
    if (_imageFile == null) {
      final canRun = _interpreter != null;
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Start Identification',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a photo or upload one to identify the iguana species.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: theme.colorScheme.primary,
                    textColor: theme.colorScheme.secondary,
                    onTap: canRun ? () => _pickImage(source: ImageSource.camera) : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    color: theme.colorScheme.surfaceContainerHighest,
                    textColor: theme.colorScheme.onSurfaceVariant,
                    onTap: canRun ? () => _pickImage(source: ImageSource.gallery) : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    
    // Results
    if (_predictions == null) {
       return const SizedBox(); // Should be busy state handled by overlay
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Analysis Results',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _imageFile = null;
                    _predictions = null;
                  });
                },
                icon: const Icon(Icons.refresh),
                tooltip: 'Scan another',
              ),
            ],
          ),
          const SizedBox(height: 24),
          ..._predictions!.entries.take(3).map((entry) {
            final isTop = entry.key == _predictions!.keys.first;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                          color: isTop ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${entry.value.toStringAsFixed(1)}%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isTop ? theme.colorScheme.primary : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: entry.value / 100,
                      backgroundColor: Colors.grey[200],
                      color: isTop ? theme.colorScheme.secondary : Colors.grey[400],
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: onTap != null ? color : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: onTap != null ? textColor : Colors.grey.shade500),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: onTap != null ? textColor : Colors.grey.shade500,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
