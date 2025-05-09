import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/story_model.dart';

class StoryBlueprint {
  final String id;
  final String title;
  final String description;
  final String theme;
  final int ageGroup;
  final String previewImage;
  final List<Map<String, String>> predefinedPages;

  StoryBlueprint({
    required this.id,
    required this.title,
    required this.description,
    required this.theme,
    required this.ageGroup,
    required this.previewImage,
    this.predefinedPages = const [],
  });
}

class StoryService {
  final SupabaseClient dbClient;
  final Uuid _uuid = const Uuid();

  StoryService({required this.dbClient});

  final List<StoryBlueprint> _templates = [
    StoryBlueprint(
      id: 'template_forest',
      title: 'The Enchanted Forest',
      description: 'Adventure through a magical forest with mythical creatures.',
      theme: 'adventure',
      ageGroup: 6,
      previewImage: 'https://picsum.photos/800/600?random=forest',
    ),
    // Add others as needed
  ];

  List<StoryBlueprint> getTemplates() => _templates;

  StoryBlueprint? getTemplateById(String id) {
    try {
      return _templates.firstWhere((template) => template.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Story> createStory({
    required String title,
    required String description,
    required String theme,
    required int ageGroup,
    String? templateId,
  }) async {
    final String storyId = _uuid.v4();
    final DateTime timestamp = DateTime.now();

    await dbClient.from('stories').insert({
      'id': storyId,
      'title': title,
      'description': description,
      'theme': theme,
      'created_at': timestamp.toIso8601String(),
      'template_id': templateId,
    });

    final List<StoryPage> storyPages = await _generatePages(
      title: title,
      description: description,
      theme: theme,
      ageGroup: ageGroup,
      templateId: templateId,
    );

    final List<Map<String, dynamic>> pagesData = storyPages.map((page) => {
          'story_id': storyId,
          'page_number': page.pageNumber,
          'content': page.content,
          'image_url': page.imageUrl,
        }).toList();

    await dbClient.from('story_pages').insert(pagesData);

    return Story(
      id: storyId,
      title: title,
      description: description,
      theme: theme,
      createdAt: timestamp,
      pages: storyPages,
    );
  }

  Future<List<StoryPage>> _generatePages({
    required String title,
    required String description,
    required String theme,
    required int ageGroup,
    String? templateId,
  }) async {
    String prompt = '''
Create a 3-page story for children:
Title: $title
Description: $description
Theme: $theme
Target Age: $ageGroup

Format:
{
  "pages": [
    {"page_number": 1, "content": "Page 1 text..."},
    {"page_number": 2, "content": "Page 2 text..."},
    {"page_number": 3, "content": "Page 3 text..."}
  ]
}
Use simple vocabulary. Each page should be 4-5 short paragraphs. Include a beginning, middle, and end.''';

    if (templateId != null) {
      final template = getTemplateById(templateId);
      if (template != null) {
        prompt += '\nMatch the tone and story elements of: ${template.description}';
      }
    }

    final response = await http.post(
      Uri.parse('http://127.0.0.1/generate-story'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': prompt}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to generate story: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final List<dynamic> pagesJson = data['pages'];

    return pagesJson.map<StoryPage>((entry) {
      return StoryPage(
        pageNumber: entry['page_number'],
        content: entry['content'],
        imageUrl: '', // Add image URL generation logic if needed
      );
    }).toList();
  }
}
