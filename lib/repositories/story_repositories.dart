import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/story_model.dart';

class StoryTemplate {
  final String id;
  final String title;
  final String description;
  final String theme;
  final int recommendedAge;
  final String previewImageUrl;
  final List<Map<String, String>> pages; // Optional pre-defined pages

  StoryTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.theme,
    required this.recommendedAge,
    required this.previewImageUrl,
    this.pages = const [],
  });
}

class StoryRepository {
  final SupabaseClient supabase;
  final GenerativeModel generativeModel;
  final Uuid _uuid = const Uuid();
  
  // Add a list of prebuilt story templates
  final List<StoryTemplate> _prebuiltTemplates = [
    StoryTemplate(
      id: 'template_adventure_forest',
      title: 'The Magic Forest Adventure',
      description: 'A journey through an enchanted forest filled with magical creatures',
      theme: 'adventure',
      recommendedAge: 6,
      previewImageUrl: 'https://picsum.photos/800/600?random=forest',
    ),
    StoryTemplate(
      id: 'template_space_journey',
      title: 'Journey to the Stars',
      description: 'An exciting space adventure across the galaxy',
      theme: 'space',
      recommendedAge: 8,
      previewImageUrl: 'https://picsum.photos/800/600?random=space',
    ),
    StoryTemplate(
      id: 'template_underwater',
      title: 'Deep Sea Discovery',
      description: 'Explore the mysterious ocean depths with sea creatures',
      theme: 'ocean',
      recommendedAge: 5,
      previewImageUrl: 'https://picsum.photos/800/600?random=ocean',
    ),
    StoryTemplate(
      id: 'template_dinosaur',
      title: 'Dinosaur Days',
      description: 'Travel back in time to meet amazing dinosaurs',
      theme: 'prehistoric',
      recommendedAge: 7,
      previewImageUrl: 'https://picsum.photos/800/600?random=dinosaur',
    ),
    StoryTemplate(
      id: 'template_fairy_tale',
      title: 'The Enchanted Kingdom',
      description: 'A magical fairy tale with princes, princesses and dragons',
      theme: 'fantasy',
      recommendedAge: 6,
      previewImageUrl: 'https://picsum.photos/800/600?random=fairytale',
    ),
  ];

  StoryRepository({
    required this.supabase,
    required this.generativeModel,
  });

  // Add method to get prebuilt templates
  List<StoryTemplate> getPrebuiltTemplates() {
    return _prebuiltTemplates;
  }

  // Get a specific template by ID
  StoryTemplate? getTemplateById(String templateId) {
    try {
      return _prebuiltTemplates.firstWhere((template) => template.id == templateId);
    } catch (e) {
      return null;
    }
  }

  Future<List<Story>> getStories() async {
    final response = await supabase
        .from('stories')
        .select('*')
        .order('created_at', ascending: false);

    final List<Story> stories = [];

    for (final storyData in response) {
      // For each story, get its pages
      final pagesResponse = await supabase
          .from('story_pages')
          .select('*')
          .eq('story_id', storyData['id'])
          .order('page_number'); // Keep DB order clause

      List<StoryPage> pages = pagesResponse.map<StoryPage>((pageData) {
        return StoryPage(
          pageNumber: pageData['page_number'],
          content: pageData['content'],
          imageUrl: pageData['image_url'],
        );
      }).toList();

      // Explicitly sort the pages list in Dart by pageNumber
      pages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

      // Create the Story object with its pages
      stories.add(
        Story(
          id: storyData['id'],
          title: storyData['title'],
          description: storyData['description'],
          theme: storyData['theme'],
          createdAt: DateTime.parse(storyData['created_at']),
          pages: pages, // Use the sorted list
        ),
      );
    }

    return stories;
  }

  Future<Story> getStory(String id) async {
    final storyData = await supabase
        .from('stories')
        .select()
        .eq('id', id)
        .single();

    final pagesResponse = await supabase
        .from('story_pages')
        .select()
        .eq('story_id', id)
        .order('page_number'); // Keep DB order clause

    List<StoryPage> pages = pagesResponse.map<StoryPage>((pageData) {
      return StoryPage(
        pageNumber: pageData['page_number'],
        content: pageData['content'],
        imageUrl: pageData['image_url'],
      );
    }).toList();

    // Explicitly sort the pages list in Dart by pageNumber
    pages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

    return Story(
      id: storyData['id'],
      title: storyData['title'],
      description: storyData['description'],
      theme: storyData['theme'],
      createdAt: DateTime.parse(storyData['created_at']),
      pages: pages, // Use the sorted list
    );
  }

  // Update createStory method to accept pageCount parameter
  Future<Story> createStory({
    required String title,
    required String description,
    required String theme,
    required int age,
    String? templateId,
    int pageCount = 3, // Default to 3 pages if not specified
  }) async {
    final String storyId = _uuid.v4();
    final DateTime now = DateTime.now();
    
    // Insert the story record
    await supabase.from('stories').insert({
      'id': storyId,
      'title': title,
      'description': description,
      'theme': theme,
      'created_at': now.toIso8601String(),
      'template_id': templateId,
    });
    
    // Generate the story content - either from template or using AI
    final List<StoryPage> pages;
    
    if (templateId != null) {
      final template = getTemplateById(templateId);
      if (template != null && template.pages.isNotEmpty) {
        // Use the template's predefined pages if available
        pages = template.pages.map((page) => StoryPage(
          pageNumber: int.parse(page['page_number'] ?? '1'),
          content: page['content'] ?? '',
          imageUrl: page['image_url'] ?? '',
        )).toList();
      } else {
        // Generate content based on the template's theme and description
        pages = await _generateStoryWithGemini(
          title: title,
          description: description,
          theme: theme,
          age: age,
          templateId: templateId,
          pageCount: pageCount,
        );
      }
    } else {
      // Generate completely new content
      pages = await _generateStoryWithGemini(
        title: title,
        description: description,
        theme: theme,
        age: age,
        pageCount: pageCount,
      );
    }
    
    // Insert all the story pages
    final List<Map<String, dynamic>> pagesData = [];
    for (final page in pages) {
      pagesData.add({
        'story_id': storyId,
        'page_number': page.pageNumber,
        'content': page.content,
        'image_url': page.imageUrl,
      });
    }
    
    await supabase.from('story_pages').insert(pagesData);
    
    return Story(
      id: storyId,
      title: title,
      description: description,
      theme: theme,
      createdAt: now,
      pages: pages,
    );
  }

  // Update _generateStoryWithGemini to accept templateId and pageCount
  Future<List<StoryPage>> _generateStoryWithGemini({
    required String title,
    required String description,
    required String theme,
    required int age,
    String? templateId,
    int pageCount = 3, // Default to 3 pages
  }) async {
    try {
      // Update the prompt to include the page count
      String promptTemplate = '''Create a ${pageCount}-page children's story with the following details:
      make sure this is simple english according to the children age as the children dont know any tough words and as its for indian kids so make sure that the words are very simple 
          Title: $title
          Description: $description
          Theme: $theme
          Target Age: $age years old
          ''';

      // Add template-specific guidance if a template is selected
      if (templateId != null) {
        final template = getTemplateById(templateId);
        if (template != null) {
          promptTemplate += '''
          This story should follow the theme of "${template.title}".
          Key elements to include: ${template.description}
          ''';
        }
      }

      // Complete the prompt with formatting instructions
      promptTemplate += '''
            make sure this is simple english according to the children age as the children dont know any tough words and as its for indian kids so make sure that the words are very simple 

          Format the response as a JSON object with the following structure:
          {
            "pages": [
              {"page_number": 1, "content": "Page 1 text here..."},
              {"page_number": 2, "content": "Page 2 text here..."},
              ...and so on for $pageCount pages
            ]
          }
          make sure the numbering of pages is correct and the sotry is not inverted 
          You have to make sure the words are very simple and easy to understand as this is for kids
          Make each page about 5 paragraphs long. Make sure the story has a beginning, middle, and end spread across the $pageCount pages.''';


      // Generate the story content
      final content = await generativeModel.generateContent(
        [Content.text(promptTemplate)],
      );
      
      // Extract JSON from the response, handling potential markdown formatting
      String jsonText = content.text!;
      
      // If response is wrapped in markdown code blocks, extract just the JSON part
      if (jsonText.contains('```')) {
        final RegExp jsonRegex = RegExp(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```');
        final match = jsonRegex.firstMatch(jsonText);
        if (match != null && match.groupCount >= 1) {
          jsonText = match.group(1)!;
        }
      }
      
      // Parse the cleaned JSON
      final storyJson = jsonDecode(jsonText);
      final pagesData = storyJson['pages'] as List;
      
      // Now generate an image for each page
      final List<StoryPage> storyPages = [];
      
      for (final pageData in pagesData) {
        final pageNumber = pageData['page_number'];
        final pageContent = pageData['content'];
        
        // Generate image prompt based on the page content
        final imagePrompt = await generativeModel.generateContent(
          [
            Content.text('''Based on the following excerpt from a children's story, create a brief, specific description for an image that would illustrate this scene well. Keep the description under 30 words and focus only on visual elements:
            
            "$pageContent"''')
          ],
        );
        
        // Use an image generation API (like Stable Diffusion or DALL-E)
        // For this example, we'll use a placeholder service
        final imageUrl = await _generateImageForPrompt(imagePrompt.text!);
        
        storyPages.add(
          StoryPage(
            pageNumber: pageNumber,
            content: pageContent,
            imageUrl: imageUrl,
          ),
        );
      }
      
      // Sort the generated pages before returning, just in case the AI response wasn't ordered
      storyPages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

      return storyPages;
    } catch (e) {
      print('Error generating story with Gemini: $e');
      throw Exception('Failed to generate story');
    }
  }

  Future<String> _generateImageForPrompt(String prompt) async {
    try {
      // Get the API key from environment variables
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        throw Exception('Gemini API key not found');
      }

      // Prepare the request to the Gemini image generation API
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp-image-generation:generateContent?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Create a high-quality children\'s book illustration: $prompt'}
              ]
            }
          ],
          'generationConfig': {
            'responseModalities': ['Text', 'Image']
          }
        }),
      );

      if (response.statusCode != 200) {
        print('Failed to generate image: ${response.statusCode} ${response.body}');
        // Fall back to placeholder if the API request fails
        return 'https://picsum.photos/800/600?random=${_uuid.v4()}';
      }

      // Parse the response and extract the base64-encoded image
      final responseData = jsonDecode(response.body);
      
      // Navigate through the response structure to find the image data
      final candidates = responseData['candidates'] as List;
      if (candidates.isEmpty) {
        throw Exception('No image generation candidates returned');
      }
      
      final content = candidates[0]['content'];
      final parts = content['parts'] as List;
      
      // Find the part containing image data
      String? base64ImageData;
      for (final part in parts) {
        if (part.containsKey('inlineData') && part['inlineData']['mimeType'].startsWith('image/')) {
          base64ImageData = part['inlineData']['data'];
          break;
        }
      }
      
      if (base64ImageData == null) {
        throw Exception('No image data found in the response');
      }

      // Upload the image to Supabase storage
      final imageBytes = base64Decode(base64ImageData);
      final fileName = 'story_images/${_uuid.v4()}.jpg';
      
      await supabase.storage.from('images').uploadBinary(
        fileName,
        imageBytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );
      
      // Get the public URL for the uploaded image
      final imageUrl = supabase.storage.from('images').getPublicUrl(fileName);
      return imageUrl;
      
    } catch (e) {
      print('Error generating image with Gemini: $e');
      // Fall back to placeholder if anything fails
      return 'https://picsum.photos/800/600?random=${_uuid.v4()}';
    }
  }

  Future<void> deleteStory(String id) async {
    // Delete all pages first (assuming foreign key constraints)
    await supabase
        .from('story_pages')
        .delete()
        .eq('story_id', id);
        
    // Then delete the story
    await supabase
        .from('stories')
        .delete()
        .eq('id', id);
  }
}
