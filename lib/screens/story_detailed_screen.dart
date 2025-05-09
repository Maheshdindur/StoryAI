import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:story_ai_app/cubits/story/story_cubit.dart';
import '../models/story_model.dart';

// Define app colors as constants
const Color backgroundColor = Color(0xFFFDF6EC); // Creamy background
const Color accentColor = Color(0xFFD38C71); // Terracotta/Brown accent
const Color textColor = Color(0xFF4E4E4E); // Dark grey for text

class StoryDetailScreen extends StatefulWidget {
  static const String routeName = '/story-detail';

  const StoryDetailScreen({super.key});

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

// Enum to manage TTS state
enum TtsState { playing, stopped, paused }

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  final PageController _pageController = PageController();
  late FlutterTts _flutterTts;
  int _currentPage = 0;
  TtsState _ttsState = TtsState.stopped;
  bool _isTtsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _pageController.addListener(() {
      if (_ttsState == TtsState.playing) {
         _stop();
      }
      if (_pageController.page == _pageController.page?.roundToDouble()) {
        final newPage = _pageController.page?.round() ?? 0;
        if (newPage != _currentPage) {
             setState(() {
               _currentPage = newPage;
             });
        }
      }
    });
  }

  // Initialize TTS settings with web support
  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    
    // Web-specific initialization
    if (kIsWeb) {
      // Set available languages and voice options
      await _flutterTts.awaitSpeakCompletion(true);
      
      // Check if TTS is available
      var available = await _flutterTts.isLanguageAvailable("en-US");
      if (available != 1) {
        print("TTS might not be fully supported in this web browser");
      }
    }
    
    // Common initialization for all platforms
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(1.0);
    
    // Set completion handler based on platform
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _ttsState = TtsState.stopped;
      });
    });

    // Set up error handler
    _flutterTts.setErrorHandler((msg) {
      print("TTS Error: $msg");
      setState(() {
        _ttsState = TtsState.stopped;
      });
    });

    // Set up start handler
    _flutterTts.setStartHandler(() {
      setState(() {
        _ttsState = TtsState.playing;
      });
    });
    
    // Web-specific progress handler
    if (kIsWeb) {
      _flutterTts.setCancelHandler(() {
        setState(() {
          _ttsState = TtsState.stopped;
        });
      });
      
      _flutterTts.setPauseHandler(() {
        setState(() {
          _ttsState = TtsState.paused;
        });
      });
      
      _flutterTts.setContinueHandler(() {
        setState(() {
          _ttsState = TtsState.playing;
        });
      });
    }
    
    setState(() {
      _isTtsInitialized = true;
    });
  }

  // Speak the text with web support
  Future<void> _speak(String text) async {
    if (!_isTtsInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text-to-speech is initializing. Please try again.'))
      );
      return;
    }
    
    if (text.isEmpty) return;
    
    try {
      await _flutterTts.stop();
      
      setState(() {
        _ttsState = TtsState.playing;
      });
      
      // Break long text into chunks for better web TTS performance
      if (kIsWeb && text.length > 1000) {
        // For web, break into paragraphs to handle long text better
        final paragraphs = text.split('\n\n');
        
        for (var paragraph in paragraphs) {
          if (_ttsState != TtsState.playing) break; // Stop if user interrupted
          await _flutterTts.speak(paragraph.trim());
          // Small delay between paragraphs for natural pauses
          await Future.delayed(const Duration(milliseconds: 300));
        }
      } else {
        // For non-web or shorter text, speak normally
        await _flutterTts.speak(text);
      }
    } catch (e) {
      print('TTS Error: $e');
      setState(() {
        _ttsState = TtsState.stopped;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to read text aloud. Please try again later.'),
          backgroundColor: Colors.redAccent,
        )
      );
    }
  }

  // Stop the text with web support
  Future<void> _stop() async {
    if (!_isTtsInitialized) return;
    
    try {
      var result = await _flutterTts.stop();
      
      setState(() {
        _ttsState = TtsState.stopped;
      });
    } catch (e) {
      print('Stop TTS Error: $e');
    }
  }

  @override
  void dispose() {
    if (_isTtsInitialized) {
      _flutterTts.stop();
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoryCubit, StoryState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Scaffold(
            backgroundColor: backgroundColor,
            body: Center(child: CircularProgressIndicator(color: accentColor)),
          );
        }

        if (state.selectedStory == null) {
          // Navigate back or show a clear message
          // Pop automatically if opened via push, otherwise show message.
           WidgetsBinding.instance.addPostFrameCallback((_) {
             if (Navigator.canPop(context)) {
               Navigator.pop(context);
             }
           });
          return const Scaffold(
            backgroundColor: backgroundColor,
            body: Center(child: Text('Story not found or deleted.', style: TextStyle(color: textColor))),
          );
        }

        final story = state.selectedStory!;
        final currentPageContent = story.pages.isNotEmpty ? story.pages[_currentPage].content : '';

        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea( // Ensures content avoids notches/status bars
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Custom Header
                _buildHeader(context, story, textColor),

                // 2. Audio Player Bar
                _buildAudioPlayer(context, currentPageContent, accentColor),

                // 3. Story Title
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                  child: Text(
                    story.title,
                    textAlign: TextAlign.center,
                    // Using GoogleFonts for a slightly nicer look (optional)
                    style: GoogleFonts.libreBaskerville( // Example serif font
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),

                // 4. Story Content Area (PageView)
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: story.pages.length,
                    // onPageChanged handled by the listener in initState now
                    itemBuilder: (context, index) {
                      final page = story.pages[index];
                      // Pass text color to StoryPageView
                      return StoryPageView(page: page, textColor: textColor);
                    },
                  ),
                ),

                // Optional: Page indicator dots (subtle navigation)
                 if (story.pages.length > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_ios, size: 20),
                            color: accentColor,
                            onPressed: _currentPage > 0 
                                ? () => _pageController.previousPage(
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    )
                                : null,
                            tooltip: 'Previous page',
                          ),
                          _buildPageIndicator(story.pages.length, accentColor),
                          IconButton(
                            icon: Icon(Icons.arrow_forward_ios, size: 20),
                            color: accentColor,
                            onPressed: _currentPage < story.pages.length - 1
                                ? () => _pageController.nextPage(
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    )
                                : null,
                            tooltip: 'Next page',
                          ),
                        ],
                      ),
                    ),

                // Removed the old explicit navigation controls
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Helper Widgets ---

  // Custom Header like the image
  Widget _buildHeader(BuildContext context, Story story, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: textColor.withOpacity(0.8)),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
          ),
          Text(
            'Your story', // Title as in image
            style: GoogleFonts.lato( // Example sans-serif
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: textColor.withOpacity(0.9),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.book_outlined, color: textColor.withOpacity(0.8)),
                onPressed: () {
                  // TODO: Implement 'Read' options if needed (e.g., show all text)
                },
                tooltip: 'Reading Options',
              ),
              // Using 'more_vert' for delete and potentially other actions
              PopupMenuButton<String>(
                 icon: Icon(Icons.more_vert, color: textColor.withOpacity(0.8)), // Use 'more' icon
                 tooltip: "More Options",
                 onSelected: (value) {
                   if (value == 'delete') {
                     _showDeleteConfirmation(context, story);
                   }
                   // Add other options here if needed
                 },
                 itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                   const PopupMenuItem<String>(
                     value: 'delete',
                     child: Text('Delete Story', style: TextStyle(color: Colors.redAccent)),
                   ),
                   // Add other PopupMenuItems here
                 ],
               ),
              // IconButton( // Original Text Format Icon (Aa)
              //   icon: Icon(Icons.text_format, color: textColor.withOpacity(0.8)),
              //   onPressed: () {
              //     // TODO: Implement Text Formatting options (font size, etc.)
              //   },
              //   tooltip: 'Text Options',
              // ),
            ],
          ),
        ],
      ),
    );
  }

  // Audio Player Bar
  Widget _buildAudioPlayer(BuildContext context, String textToSpeak, Color accentColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(30.0), // Highly rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ]
      ),
      child: IconButton(
        icon: Icon(
          // Change icon based on TTS state
          _ttsState == TtsState.playing ? Icons.stop_rounded : Icons.volume_up_rounded,
          color: Colors.white,
          size: 30,
        ),
        onPressed: textToSpeak.isEmpty
           ? null // Disable if no text
           : (_ttsState == TtsState.playing ? _stop : () => _speak(textToSpeak)),
        tooltip: _ttsState == TtsState.playing ? 'Stop Reading' : 'Read Aloud',
      ),
    );
  }

  // Subtle Page Indicator Dots
  Widget _buildPageIndicator(int pageCount, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(pageCount, (index) {
          return Container(
            width: 8.0,
            height: 8.0,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentPage == index
                  ? accentColor // Active dot color
                  : accentColor.withOpacity(0.3), // Inactive dot color
            ),
          );
        }),
      ),
    );
  }

  // Delete Confirmation Dialog (kept from original, slightly styled)
  void _showDeleteConfirmation(BuildContext context, Story story) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        title: const Text('Delete Story'),
        content: Text('Are you sure you want to delete "${story.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              // Stop TTS if it was playing this story's content
               _stop();
              Navigator.pop(context); // Close dialog
              context.read<StoryCubit>().deleteStory(story.id);
              // No need for the second pop if called from within the screen,
              // the BlocBuilder will handle the state change and rebuild.
              // If the story is deleted, the builder will likely trigger the
              // "Story not found" case, which now handles navigation.
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}


// --- Updated StoryPageView Widget ---

class StoryPageView extends StatelessWidget {
  final StoryPage page;
  final Color textColor; // Pass text color for consistency

  const StoryPageView({
    super.key,
    required this.page,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // Use a SingleChildScrollView for potentially long markdown content per page
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0), // Consistent padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch column items
        children: [
          // Show the image for each page
          if (page.imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Hero(
                    tag: 'story_page_image_${page.pageNumber}',
                    child: _buildImage(page.imageUrl),
                  ),
                ),
              ),
            ),

          // Display story content using Markdown
          MarkdownBody(
            data: page.content,
            selectable: true, // Allow text selection
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              // Customize Markdown styles to match the desired look
              p: GoogleFonts.dmSerifDisplay( // Using a serif font for body text
                fontSize: 17,        // Slightly smaller for readability
                height: 1.6,         // Line spacing
                color: textColor,      // Use passed text color
              ),
              h1: GoogleFonts.libreBaskerville(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
              h2: GoogleFonts.libreBaskerville(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
              // Add other styles (h3, blockquote, code, etc.) if needed
              listBullet: GoogleFonts.dmSerifDisplay(fontSize: 17, height: 1.6, color: textColor),
              em: GoogleFonts.dmSerifDisplay(fontSize: 17, height: 1.6, color: textColor, fontStyle: FontStyle.italic),
              strong: GoogleFonts.dmSerifDisplay(fontSize: 17, height: 1.6, color: textColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20), // Add some space at the bottom
        ],
      ),
    );
  }
  
  // Helper method to build appropriate image widget based on URL type
  Widget _buildImage(String url) {
    // Check if it's a data URL (base64)
    if (url.startsWith('data:image')) {
      return Image.memory(
        _decodeBase64Image(url),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder();
        },
      );
    }
    
    // Regular network image
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
            color: Theme.of(context).primaryColor,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorPlaceholder();
      },
    );
  }
  
  // Helper method to decode base64 image data
  Uint8List _decodeBase64Image(String dataUrl) {
    // Extract the base64 string after the comma
    final base64String = dataUrl.split(',')[1];
    return base64Decode(base64String);
  }
  
  // Error placeholder for images
  Widget _buildErrorPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined, color: Colors.grey[600], size: 48),
            const SizedBox(height: 8),
            Text(
              'Image not available',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}