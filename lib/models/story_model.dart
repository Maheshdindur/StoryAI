import 'package:equatable/equatable.dart';

class Story extends Equatable {
  final String id;
  final String title;
  final String description;
  final String theme;
  final DateTime createdAt;
  final List<StoryPage> pages;

  const Story({
    required this.id,
    required this.title,
    required this.description,
    required this.theme,
    required this.createdAt,
    required this.pages,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    List<StoryPage> pagesList = [];
    if (json['pages'] != null) {
      pagesList = List<StoryPage>.from(
        (json['pages'] as List).map((page) => StoryPage.fromJson(page)),
      );
    }
    
    return Story(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      theme: json['theme'],
      createdAt: DateTime.parse(json['created_at']),
      pages: pagesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'theme': theme,
      'created_at': createdAt.toIso8601String(),
      'pages': pages.map((page) => page.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, title, description, theme, createdAt, pages];
}

class StoryPage extends Equatable {
  final int pageNumber;
  final String content;
  final String imageUrl;

  const StoryPage({
    required this.pageNumber,
    required this.content,
    required this.imageUrl,
  });

  factory StoryPage.fromJson(Map<String, dynamic> json) {
    return StoryPage(
      pageNumber: json['page_number'],
      content: json['content'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page_number': pageNumber,
      'content': content,
      'image_url': imageUrl,
    };
  }

  @override
  List<Object?> get props => [pageNumber, content, imageUrl];
}