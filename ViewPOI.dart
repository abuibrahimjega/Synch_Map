import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import './DBConnection.dart';
import './ApiService.dart'; // Import the ApiService

/// This widget allows the user to view information about a Point of Interest (POI).
/// It includes a text field for entering the POI ID, a button to fetch the information,
class ViewPOI extends StatefulWidget {
  const ViewPOI({super.key});

  @override
  State<ViewPOI> createState() => _ViewPOIState();
}

class _ViewPOIState extends State<ViewPOI> {
  final TextEditingController _poiIdController = TextEditingController();
  String _poiInfo = '';
  bool _isLoading = false;
  bool _isConverting = false;
  IconData? _poiIcon;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _poiName = '';
  bool _isPlaying = false;
  String? _audioUrl;

  // Map of icon values to IconData
  final Map<String, IconData> _iconMap = {
    'wc': Icons.wc,
    'elevator': Icons.elevator,
    'stairs': Icons.stairs,
    'exit': Icons.exit_to_app,
    'restaurant': Icons.restaurant,
    'cafe': Icons.local_cafe,
    'store': Icons.shopping_cart,
    'info': Icons.info,
    'medical': Icons.local_hospital,
    'office': Icons.work,
  };

  Future<void> _getPOIInfo() async {
    final poiId = _poiIdController.text.trim();

    if (poiId.isEmpty) {
      setState(() {
        _poiInfo = 'Please enter a POI ID';
        _poiIcon = null;
        _poiName = '';
        _audioUrl = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _poiInfo = '';
      _poiIcon = null;
      _poiName = '';
      _audioUrl = null;
    });

    try {
      final int parsedPoiId = int.parse(poiId);
      final poiData = await DBConnection.getPOIData(parsedPoiId);

      if (poiData == null) {
        setState(() {
          _poiInfo = 'POI not found';
        });
        return;
      }

      // Extract POI information
      final MID = poiData['MID'];
      final FID = poiData['FID'];
      final iconName = poiData['PIconName'];
      final name = poiData['PName'] ?? 'Unnamed POI';
      final x = poiData['PX']?.toString() ?? 'N/A';
      final y = poiData['PY']?.toString() ?? 'N/A';
      final description = poiData['PDescription'] ?? 'No description';
      final month = poiData['PEditMonth']?.toString() ?? 'N/A';
      final year = poiData['PEditYear']?.toString() ?? 'N/A';

      setState(() {
        _poiName = name;
        _poiIcon = iconName != null ? _iconMap[iconName] : Icons.place;
        _poiInfo = '''
Name:  $name
Description:  $description

Map ID:  $MID
Floor ID:  $FID
Last Edited:  $month/$year
Coordinates:  X: $x  |  Y: $y
''';
      });
    } on FormatException {
      setState(() {
        _poiInfo = 'Please enter a valid numeric POI ID';
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        _poiInfo = 'Failed to retrieve POI information: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // convert POI to speech using the ApiService
  Future<void> _convertToSpeech() async {
    if (_poiInfo.isEmpty ||
        _poiInfo == 'POI not found' ||
        _poiInfo.contains('Please enter') ||
        _poiInfo.contains('Failed to')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid POI information to read')),
      );
      return;
    }

    setState(() {
      _isConverting = true;
    });

    try {
      // The text to be converted to speech (simplified for better speech)
      String speechText =
          "POI information for ${_poiName}. ${_poiInfo.replaceAll(':', '.')}";

      // Use the ApiService for text-to-speech conversion
      final audioFile = await ApiService.textToSpeech(
        speechText,
        engine: 'gtts',
        language: 'en',
        slow: false,
      );

      if (audioFile != null) {
        setState(() {
          _audioUrl = audioFile.path;
          _isConverting = false;
        });

        // Start playing automatically
        _playAudio();
      } else {
        throw Exception('Failed to convert text to speech');
      }
    } catch (e) {
      print('Text-to-speech error: $e');
      setState(() {
        _isConverting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to convert to speech: ${e.toString()}')),
      );
    }
  }

  // Function to play audio
  Future<void> _playAudio() async {
    if (_audioUrl == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      await _audioPlayer.play(DeviceFileSource(_audioUrl!));
      setState(() {
        _isPlaying = true;
      });

      // Listen for playback completion
      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          _isPlaying = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View POI Information'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _poiIdController,
              decoration: const InputDecoration(
                labelText: 'Enter POI ID',
                border: OutlineInputBorder(),
                hintText: 'e.g. 123',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _getPOIInfo,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Get POI Information'),
            ),
            const SizedBox(height: 20),
            if (_poiInfo.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_poiIcon != null)
                          Row(
                            children: [
                              Icon(_poiIcon, size: 40, color: Colors.blue),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(_poiName,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ),

                              // Text-to-speech button
                              IconButton(
                                icon: _isConverting
                                    ? const CircularProgressIndicator()
                                    : Icon(_isPlaying
                                        ? Icons.pause
                                        : Icons.volume_up),
                                onPressed: _isConverting
                                    ? null
                                    : _audioUrl != null
                                        ? _playAudio
                                        : _convertToSpeech,
                                tooltip: _audioUrl != null
                                    ? (_isPlaying ? 'Pause' : 'Play')
                                    : 'Read aloud',
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        Text(
                          _poiInfo,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _poiIdController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
