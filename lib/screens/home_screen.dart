import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:story_ai_app/cubits/story/story_cubit.dart';
import 'package:story_ai_app/screens/create_story_screen.dart';
import 'package:story_ai_app/screens/story_detailed_screen.dart';
import '../models/story_model.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Story> _filteredStories = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text != _searchQuery) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStories(List<Story> allStories) {
    if (_searchQuery.isEmpty) {
      _filteredStories = List.from(allStories);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredStories = allStories.where((story) {
        final titleMatch = story.title.toLowerCase().contains(query);
        final descriptionMatch = story.description.toLowerCase().contains(query);
        final themeMatch = story.theme.toLowerCase().contains(query);
        return titleMatch || descriptionMatch || themeMatch;
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define colors from the design philosophy
    const Color backgroundColor = Color(0xFFFDF6EC);
    const Color accentColor = Color(0xFFD38C71);
    const Color textColor = Color(0xFF4E4E4E);
    final Color subtleTextColor = textColor.withOpacity(0.65);
    final Color shadowColor = Colors.black.withOpacity(0.08);
    
    // Get screen width to determine layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;

    return Scaffold(
      backgroundColor: backgroundColor,
      // Use responsive layout based on screen size
      body: SafeArea(
        child: isDesktop
            ? _buildDesktopLayout(
                context,
                accentColor,
                textColor,
                subtleTextColor,
                shadowColor,
              )
            : _buildMobileLayout(
                context,
                accentColor,
                textColor,
                subtleTextColor,
                shadowColor,
              ),
      ),
      // Only show FAB on mobile layout
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, CreateStoryScreen.routeName);
              },
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              tooltip: 'Create New Story',
              elevation: 4,
              child: const Icon(Icons.add, size: 28),
            ),
    );
  }

  // Desktop layout with sidebar
  Widget _buildDesktopLayout(
    BuildContext context,
    Color accentColor,
    Color textColor,
    Color subtleTextColor,
    Color shadowColor,
  ) {
    return Row(
      children: [
        // Left sidebar (25% width)
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App title and logo area
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_stories,
                        size: 32,
                        color: accentColor,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Story AI',
                        style: GoogleFonts.libreBaskerville(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _buildSearchBar(textColor, subtleTextColor, shadowColor),
                ),
                
                const SizedBox(height: 32),
                
                // Create new story button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, CreateStoryScreen.routeName);
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: Text(
                      'Create New Story',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 20.0,
                      ),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Categories or filters could go here
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Categories',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCategoryButton('All Stories', isSelected: true, accentColor, textColor),
                      _buildCategoryButton('Recently Created', accentColor, textColor),
                      _buildCategoryButton('For Younger Kids', accentColor, textColor),
                      _buildCategoryButton('For Older Kids', accentColor, textColor),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Help or about section at bottom
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.help_outline,
                        size: 20,
                        color: subtleTextColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Help & Support',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: subtleTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Main content area (75% width)
        Expanded(
          flex: 9,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with page title 
              Padding(
                padding: const EdgeInsets.fromLTRB(40.0, 32.0, 40.0, 24.0),
                child: Text(
                  'Your Stories',
                  style: GoogleFonts.libreBaskerville(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              
              // Stories grid
              Expanded(
                child: BlocConsumer<StoryCubit, StoryState>(
                  listener: (context, state) {
                    if (state.error != null && state.error!.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${state.error}'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    _filterStories(state.stories);

                    if (state.isLoading && state.stories.isEmpty) {
                      return  Center(
                        child: CircularProgressIndicator(color: accentColor),
                      );
                    }

                    if (state.stories.isEmpty && !state.isLoading) {
                      return _buildEmptyState(context, accentColor, textColor, subtleTextColor);
                    }

                    return RefreshIndicator(
                      color: accentColor,
                      backgroundColor: backgroundColor,
                      onRefresh: () async {
                        await context.read<StoryCubit>().loadStories();
                      },
                      child: _filteredStories.isEmpty
                          ? _buildEmptySearchState(subtleTextColor)
                          : _buildDesktopStoriesGrid(context, accentColor, textColor, subtleTextColor, shadowColor),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Desktop stories grid layout
  Widget _buildDesktopStoriesGrid(
    BuildContext context,
    Color accentColor, 
    Color textColor, 
    Color subtleTextColor, 
    Color shadowColor,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(32.0, 8.0, 32.0, 32.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 stories per row
        childAspectRatio: 0.8, // Wider than tall
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: _filteredStories.length,
      itemBuilder: (context, index) {
        final story = _filteredStories[index];
        return _buildDesktopStoryCard(
          context,
          story,
          textColor,
          subtleTextColor,
          accentColor,
          shadowColor,
        );
      },
    );
  }

  // Desktop story card
  Widget _buildDesktopStoryCard(
    BuildContext context,
    Story story,
    Color textColor,
    Color subtleTextColor,
    Color accentColor,
    Color shadowColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          FocusScope.of(context).unfocus();
          context.read<StoryCubit>().getStory(story.id);
          Navigator.pushNamed(context, StoryDetailScreen.routeName);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 12,
              child: story.pages.isNotEmpty && story.pages.first.imageUrl.isNotEmpty
                  ? Hero(
                      tag: 'story_image_${story.id}',
                      child: Image.network(
                        story.pages.first.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: accentColor.withOpacity(0.7),
                                strokeWidth: 2.5,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: subtleTextColor.withOpacity(0.5),
                                size: 40,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Container(
                      color: Colors.grey[100],
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: subtleTextColor.withOpacity(0.5),
                          size: 40,
                        ),
                      ),
                    ),
            ),
            
            // Text content
            Expanded(
              flex: 10,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      story.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.libreBaskerville(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Description
                    if (story.description.isNotEmpty)
                      Expanded(
                        child: Text(
                          story.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            color: subtleTextColor,
                            height: 1.4,
                          ),
                        ),
                      ),
                    
                    // Theme and date
                    Container(
                      margin: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Theme chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              story.theme.isNotEmpty ? story.theme : 'General',
                              style: GoogleFonts.lato(
                                color: accentColor.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          
                          // Date
                          Text(
                            DateFormat.yMMMd().format(story.createdAt),
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: subtleTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mobile layout (original design)
  Widget _buildMobileLayout(
    BuildContext context,
    Color accentColor,
    Color textColor,
    Color subtleTextColor,
    Color shadowColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Custom Header Title
        Padding(
          padding: const EdgeInsets.only(top: 20.0, left: 24.0, right: 24.0, bottom: 8.0),
          child: Text(
            'Your Stories',
            style: GoogleFonts.libreBaskerville(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),

        // 2. Search Bar
        _buildSearchBar(textColor, subtleTextColor, shadowColor),

        // 3. Story List Area
        Expanded(
          child: BlocConsumer<StoryCubit, StoryState>(
            listener: (context, state) {
              if (state.error != null && state.error!.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${state.error}'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            builder: (context, state) {
              _filterStories(state.stories);

              if (state.isLoading && state.stories.isEmpty) {
                return  Center(
                  child: CircularProgressIndicator(color: accentColor),
                );
              }

              if (state.stories.isEmpty && !state.isLoading) {
                return _buildEmptyState(context, accentColor, textColor, subtleTextColor);
              }

              return RefreshIndicator(
                color: accentColor,
                backgroundColor: backgroundColor,
                onRefresh: () async {
                  await context.read<StoryCubit>().loadStories();
                },
                child: _filteredStories.isEmpty
                    ? _buildEmptySearchState(subtleTextColor)
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0, bottom: 80.0),
                        itemCount: _filteredStories.length,
                        itemBuilder: (context, index) {
                          final story = _filteredStories[index];
                          return StoryCard(
                            story: story,
                            textColor: textColor,
                            subtleTextColor: subtleTextColor,
                            accentColor: accentColor,
                            shadowColor: shadowColor,
                          );
                        },
                      ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Category button for desktop sidebar
  Widget _buildCategoryButton(String title, Color accentColor, Color textColor, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextButton(
        onPressed: () {
          // Category filtering could be implemented here
        },
        style: TextButton.styleFrom(
          backgroundColor: isSelected ? accentColor.withOpacity(0.1) : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          minimumSize: const Size(double.infinity, 48),
          alignment: Alignment.centerLeft,
        ),
        child: Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? accentColor : textColor,
          ),
        ),
      ),
    );
  }

  // Helper Widget for the Search Bar
  Widget _buildSearchBar(Color textColor, Color subtleTextColor, Color shadowColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.lato(color: textColor, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Search stories by title, theme...',
            hintStyle: GoogleFonts.lato(color: subtleTextColor, fontSize: 15),
            prefixIcon: Icon(Icons.search, color: subtleTextColor, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: subtleTextColor, size: 20),
                    onPressed: () {
                      _searchController.clear();
                    },
                    splashRadius: 18,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ),
    );
  }

  // Helper Widget for the initial Empty State
  Widget _buildEmptyState(
    BuildContext context,
    Color accentColor,
    Color textColor,
    Color subtleTextColor,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories_outlined, size: 70, color: subtleTextColor.withOpacity(0.7)),
            const SizedBox(height: 20),
            Text(
              'No stories yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.libreBaskerville(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap the + button below to create your first magical story!',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 15,
                color: subtleTextColor,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget for Empty State after filtering
  Widget _buildEmptySearchState(Color subtleTextColor) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 60.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 60, color: subtleTextColor.withOpacity(0.6)),
              const SizedBox(height: 16),
              Text(
                'No stories found',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: subtleTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try searching with different keywords.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: subtleTextColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Mobile StoryCard (unchanged)
class StoryCard extends StatelessWidget {
  final Story story;
  final Color textColor;
  final Color subtleTextColor;
  final Color accentColor;
  final Color shadowColor;

  const StoryCard({
    super.key,
    required this.story,
    required this.textColor,
    required this.subtleTextColor,
    required this.accentColor,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          FocusScope.of(context).unfocus();
          context.read<StoryCubit>().getStory(story.id);
          Navigator.pushNamed(context, StoryDetailScreen.routeName);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (story.pages.isNotEmpty && story.pages.first.imageUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Hero(
                  tag: 'story_image_${story.id}',
                  child: Image.network(
                    story.pages.first.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: accentColor.withOpacity(0.7),
                            strokeWidth: 2.5,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: subtleTextColor.withOpacity(0.5),
                            size: 40,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              Container(
                height: 100,
                color: Colors.grey[100],
                child: Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: subtleTextColor.withOpacity(0.5),
                    size: 30,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.libreBaskerville(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (story.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 10.0),
                      child: Text(
                        story.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: subtleTextColor,
                          height: 1.4,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          story.theme.isNotEmpty ? story.theme : 'General',
                          style: GoogleFonts.lato(
                            color: accentColor.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat.yMMMd().format(story.createdAt),
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: subtleTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}