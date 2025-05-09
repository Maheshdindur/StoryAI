import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:story_ai_app/cubits/story/story_cubit.dart';
import 'package:story_ai_app/cubits/story_creation/story_creation.dart';
import 'package:story_ai_app/screens/story_detailed_screen.dart';
import 'package:story_ai_app/repositories/story_repositories.dart'; // Assuming this is correct
import '../models/story_model.dart';

class CreateStoryScreen extends StatefulWidget {
  static const String routeName = '/create-story';

  const CreateStoryScreen({super.key}); // Use super(key: key)

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _themeController = TextEditingController();
  int _selectedAge = 6; // Keep default age
  String? _selectedTemplateId;
  int _selectedPageCount = 3; // Default page count

  // Possible page count options
  final List<int> _pageCountOptions = [1, 2, 3, 4, 5, 6, 7, 8, 10];
  // Keep age options
  final List<int> _ageOptions = List.generate(10, (index) => index + 3); // 3 to 12

  // Keep dispose method
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _themeController.dispose();
    super.dispose();
  }

  // Keep _applyTemplate logic
  void _applyTemplate(StoryTemplate template) {
    setState(() {
      _selectedTemplateId = template.id;
      _titleController.text = template.title;
      _descriptionController.text = template.description;
      _themeController.text = template.theme;
      // Ensure age is within bounds if template age is outside options
      _selectedAge = template.recommendedAge.clamp(_ageOptions.first, _ageOptions.last);
    });
    // Optionally, unfocus any active text field
    FocusScope.of(context).unfocus();
  }

  // Keep _clearTemplateSelection logic
  void _clearTemplateSelection() {
    setState(() {
      _selectedTemplateId = null;
      // Clear fields only if a template was selected, maybe keep user input otherwise?
      // Decided to clear them as per original logic.
      _titleController.clear();
      _descriptionController.clear();
      _themeController.clear();
      // Reset age? Optional. Keeping it as is.
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    // Define colors from the design philosophy
    const Color backgroundColor = Color(0xFFFDF6EC);
    const Color accentColor = Color(0xFFD38C71);
    const Color textColor = Color(0xFF4E4E4E);
    final Color subtleTextColor = textColor.withOpacity(0.65);
    final Color subtleBorderColor = Colors.grey.shade300;
    final Color shadowColor = Colors.black.withOpacity(0.06);

    // Access templates - Assuming repository access remains the same
    final storyRepository = context.read<StoryCreationCubit>().storyRepository;
    final templates = storyRepository.getPrebuiltTemplates();

    // Get screen size to determine layout
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1024;

    return Scaffold(
      backgroundColor: backgroundColor,
      // Remove AppBar, use custom header below
      body: SafeArea(
        child: BlocConsumer<StoryCreationCubit, StoryCreationState>(
          listener: (context, state) {
            // Listener logic remains the same
            if (state.error != null && state.error!.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Error: ${state.error}'),
                    backgroundColor: Colors.redAccent),
              );
              // Optionally reset error in cubit here
              // context.read<StoryCreationCubit>().resetError();
            }

            if (state.createdStory != null) {
              context.read<StoryCubit>().addStory(state.createdStory!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✨ Story created successfully! ✨', style: GoogleFonts.lato()),
                  backgroundColor: Colors.green.shade600,
                  duration: const Duration(seconds: 3),
                ),
              );
              context.read<StoryCubit>().getStory(state.createdStory!.id);
              // Use pushReplacementNamed to prevent going back to creation screen
              Navigator.pushReplacementNamed(
                context,
                StoryDetailScreen.routeName,
                // arguments: state.createdStory!.id, // Arguments seem unused in detail screen now
              );
              // Resetting state is crucial
              context.read<StoryCreationCubit>().resetState();
            }
          },
          builder: (context, state) {
            // --- Loading State ---
            if (state.isCreating) {
              return _buildLoadingState(context, accentColor, textColor, subtleTextColor);
            }

            // --- Form State ---
            return isDesktop
                ? _buildDesktopLayout(
                    context,
                    templates,
                    accentColor,
                    textColor,
                    subtleTextColor,
                    subtleBorderColor,
                    shadowColor,
                  )
                : _buildMobileLayout(
                    context,
                    templates,
                    accentColor,
                    textColor,
                    subtleTextColor,
                    subtleBorderColor,
                    shadowColor,
                  );
          },
        ),
      ),
    );
  }

  // Desktop Layout - Two column approach
  Widget _buildDesktopLayout(
    BuildContext context,
    List<StoryTemplate> templates,
    Color accentColor,
    Color textColor,
    Color subtleTextColor,
    Color subtleBorderColor,
    Color shadowColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column - Templates (30% width)
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              boxShadow: [
                BoxShadow(color: shadowColor, blurRadius: 10, offset: const Offset(2, 0))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button and title
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new, color: textColor.withOpacity(0.8), size: 20),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Back',
                        splashRadius: 22,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Create Story',
                        style: GoogleFonts.libreBaskerville(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Template selection - vertical scrolling for desktop
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '✨ Choose a Template',
                              style: GoogleFonts.lato(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            if (_selectedTemplateId != null)
                              TextButton.icon(
                                onPressed: _clearTemplateSelection,
                                icon: Icon(Icons.close_rounded, size: 18, color: accentColor.withOpacity(0.8)),
                                label: Text('Clear', style: GoogleFonts.lato(color: accentColor, fontSize: 13, fontWeight: FontWeight.w600)),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 1, // Single column for template cards
                              childAspectRatio: 1.4, // Adjust based on your design
                              mainAxisSpacing: 20,
                            ),
                            itemCount: templates.length,
                            itemBuilder: (context, index) {
                              final template = templates[index];
                              final isSelected = _selectedTemplateId == template.id;
                              return _buildDesktopTemplateCard(
                                context,
                                template,
                                isSelected,
                                accentColor,
                                textColor,
                                subtleTextColor,
                                subtleBorderColor,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right column - Form (70% width)
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Story Details',
                    style: GoogleFonts.libreBaskerville(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form inputs in a more spacious layout
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left form section (title & description)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextFormField(
                              controller: _titleController,
                              labelText: 'Story Title',
                              hintText: 'Enter a title for your story',
                              icon: Icons.title,
                              validatorText: 'Please enter a title',
                              textColor: textColor,
                              accentColor: accentColor,
                              subtleTextColor: subtleTextColor,
                            ),
                            const SizedBox(height: 20),
                            _buildTextFormField(
                              controller: _descriptionController,
                              labelText: 'Story Description',
                              hintText: 'What is your story about?',
                              icon: Icons.description,
                              validatorText: 'Please enter a description',
                              textColor: textColor,
                              accentColor: accentColor,
                              subtleTextColor: subtleTextColor,
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 32),

                      // Right form section (theme & advanced options)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextFormField(
                              controller: _themeController,
                              labelText: 'Story Theme',
                              hintText: 'e.g. Adventure, Fantasy, Space',
                              icon: Icons.category,
                              validatorText: 'Please enter a theme',
                              textColor: textColor,
                              accentColor: accentColor,
                              subtleTextColor: subtleTextColor,
                            ),

                            // Age and page count selectors in desktop view
                            Padding(
                              padding: const EdgeInsets.only(top: 32.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Age selector
                                  Expanded(
                                    child: _buildDesktopAgeSelector(
                                      context,
                                      accentColor,
                                      textColor,
                                      subtleTextColor,
                                      shadowColor,
                                    ),
                                  ),

                                  const SizedBox(width: 24),

                                  // Page count selector
                                  Expanded(
                                    child: _buildDesktopPageCountSelector(
                                      context,
                                      accentColor,
                                      textColor,
                                      subtleTextColor,
                                      shadowColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Submit button centered at the bottom with more space
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(
                      child: SizedBox(
                        width: 280,
                        child: _buildSubmitButton(context, accentColor, _submitForm),
                      ),
                    ),
                  ),

                  Center(
                    child: Text(
                      'Creates a story with unique AI-generated illustrations for each page.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(color: subtleTextColor, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Mobile Layout - Keep existing vertical scrolling approach
  Widget _buildMobileLayout(
    BuildContext context,
    List<StoryTemplate> templates,
    Color accentColor,
    Color textColor,
    Color subtleTextColor,
    Color subtleBorderColor,
    Color shadowColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Custom header
        _buildHeader(context, textColor),

        // Form in a scrollable area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Template Selection Section - Horizontal scroll
                  _buildTemplateSection(
                    context,
                    templates,
                    accentColor,
                    textColor,
                    subtleTextColor,
                    subtleBorderColor,
                    shadowColor,
                  ),
                  const SizedBox(height: 24),

                  // 2. Story Details Section
                  _buildSectionTitle('Story Details', textColor),
                  const SizedBox(height: 12),

                  // Title field
                  _buildTextFormField(
                    controller: _titleController,
                    labelText: 'Story Title',
                    hintText: 'Enter a title for your story',
                    icon: Icons.title,
                    validatorText: 'Please enter a title',
                    textColor: textColor,
                    accentColor: accentColor,
                    subtleTextColor: subtleTextColor,
                  ),
                  const SizedBox(height: 16),

                  // Description field
                  _buildTextFormField(
                    controller: _descriptionController,
                    labelText: 'Story Description',
                    hintText: 'What is your story about?',
                    icon: Icons.description,
                    validatorText: 'Please enter a description',
                    textColor: textColor,
                    accentColor: accentColor,
                    subtleTextColor: subtleTextColor,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Theme field
                  _buildTextFormField(
                    controller: _themeController,
                    labelText: 'Story Theme',
                    hintText: 'e.g. Adventure, Fantasy, Space',
                    icon: Icons.category,
                    validatorText: 'Please enter a theme',
                    textColor: textColor,
                    accentColor: accentColor,
                    subtleTextColor: subtleTextColor,
                  ),
                  const SizedBox(height: 24),

                  // 3. Age Selector
                  _buildAgeSelector(
                    context,
                    accentColor,
                    textColor,
                    subtleTextColor,
                    shadowColor,
                  ),
                  const SizedBox(height: 24),

                  // 4. Page Count Selector
                  _buildPageCountSelector(
                    context,
                    accentColor,
                    textColor,
                    subtleTextColor,
                    shadowColor,
                  ),
                  const SizedBox(height: 40),

                  // 5. Submit Button
                  _buildSubmitButton(context, accentColor, _submitForm),
                  const SizedBox(height: 12),

                  Text(
                    'Creates a story with unique images for each page.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(color: subtleTextColor, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Desktop-specific template card
  Widget _buildDesktopTemplateCard(
    BuildContext context,
    StoryTemplate template,
    bool isSelected,
    Color accentColor,
    Color textColor,
    Color subtleTextColor,
    Color subtleBorderColor,
  ) {
    return GestureDetector(
      onTap: () => _applyTemplate(template),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : subtleBorderColor.withOpacity(0.7),
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(color: accentColor.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))
                ]
              : [],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                template.previewImageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: Center(
                        child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentColor.withOpacity(0.6),
                    )),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Center(
                        child: Icon(
                      Icons.hide_image_outlined,
                      size: 35,
                      color: subtleTextColor.withOpacity(0.5),
                    )),
                  );
                },
              ),
            ),

            // Template details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    template.description,
                    style: GoogleFonts.lato(
                      color: subtleTextColor,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Theme chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          template.theme,
                          style: GoogleFonts.lato(
                            color: accentColor.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Age indicator
                      Row(
                        children: [
                          Icon(Icons.child_care_outlined, size: 14, color: subtleTextColor),
                          const SizedBox(width: 4),
                          Text(
                            '${template.recommendedAge} years',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: subtleTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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

  // Desktop-specific age selector
  Widget _buildDesktopAgeSelector(
    BuildContext context,
    Color accentColor,
    Color textColor,
    Color subtleTextColor,
    Color shadowColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reader Age',
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Stories will be tailored to this age group',
            style: GoogleFonts.lato(
              fontSize: 13,
              color: subtleTextColor,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          // Value display
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$_selectedAge',
                  style: GoogleFonts.lato(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor,
              inactiveTrackColor: accentColor.withOpacity(0.3),
              trackHeight: 6.0,
              thumbColor: accentColor,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
              overlayColor: accentColor.withOpacity(0.2),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
              valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
              valueIndicatorColor: accentColor.withOpacity(0.8),
              valueIndicatorTextStyle: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 12.0,
              ),
            ),
            child: Slider(
              value: _selectedAge.toDouble(),
              min: _ageOptions.first.toDouble(),
              max: _ageOptions.last.toDouble(),
              divisions: _ageOptions.length - 1,
              label: '$_selectedAge yrs',
              onChanged: (value) {
                setState(() {
                  _selectedAge = value.round();
                });
              },
            ),
          ),

          // Min/Max labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_ageOptions.first} yrs',
                  style: GoogleFonts.lato(
                    color: subtleTextColor,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${_ageOptions.last} yrs',
                  style: GoogleFonts.lato(
                    color: subtleTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Desktop-specific page count selector
  Widget _buildDesktopPageCountSelector(
    BuildContext context,
    Color accentColor,
    Color textColor,
    Color subtleTextColor,
    Color shadowColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Page Count',
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How many pages in your story',
            style: GoogleFonts.lato(
              fontSize: 13,
              color: subtleTextColor,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          // Page options as buttons in a grid
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.center,
            children: _pageCountOptions.map((count) {
              final isSelected = _selectedPageCount == count;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPageCount = count;
                  });
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? accentColor : subtleTextColor.withOpacity(0.3),
                      width: isSelected ? 0 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: accentColor.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$count',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : textColor,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          Text(
            'Longer stories take more time to generate',
            style: GoogleFonts.lato(
              color: subtleTextColor,
              fontSize: 12,
              fontStyle: FontStyle.italic,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets for Build Method ---
  Widget _buildHeader(BuildContext context, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, right: 20.0, top: 12.0, bottom: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: textColor.withOpacity(0.8), size: 20),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
            splashRadius: 22,
          ),
          const SizedBox(width: 8),
          Text(
            'Create New Story',
            style: GoogleFonts.libreBaskerville(
              fontSize: 22, // Slightly smaller than home screen title
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, Color accentColor, Color textColor, Color subtleTextColor) {
    final state = context.read<StoryCreationCubit>().state; // Get current progress
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: accentColor, strokeWidth: 3.5),
            const SizedBox(height: 32),
            Text(
              'Generating your masterpiece...',
              textAlign: TextAlign.center,
              style: GoogleFonts.libreBaskerville(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Brewing creativity, adding illustrations...\nThis can take a minute or two.",
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 15,
                color: subtleTextColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: state.progress, // Use progress from state
                  backgroundColor: accentColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  minHeight: 8, // Make it a bit thicker
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${(state.progress * 100).clamp(0, 100).toInt()}% complete', // Clamp value just in case
              style: GoogleFonts.lato(
                fontSize: 13,
                color: subtleTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Text(
      title,
      style: GoogleFonts.lato(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor.withOpacity(0.9),
      ),
    );
  }

  Widget _buildTemplateSection(
    BuildContext context,
    List<StoryTemplate> templates,
    Color accentColor,
    Color textColor,
    Color subtleTextColor,
    Color subtleBorderColor,
    Color shadowColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0), // Add vertical padding
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5), // Slightly transparent white background
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 10, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '✨ Start with a Template', // More engaging title
                  style: GoogleFonts.lato(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                if (_selectedTemplateId != null)
                  TextButton.icon(
                    onPressed: _clearTemplateSelection,
                    icon: Icon(Icons.close_rounded, size: 18, color: accentColor.withOpacity(0.8)),
                    label: Text('Clear', style: GoogleFonts.lato(color: accentColor, fontSize: 13, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero, // Remove default min size
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduce tap area
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 225, // Increased height slightly
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              // Add padding for leftmost/rightmost items
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                final isSelected = _selectedTemplateId == template.id;

                // Template Card Widget
                return _buildTemplateCard(
                  context,
                  template,
                  isSelected,
                  accentColor,
                  textColor,
                  subtleTextColor,
                  subtleBorderColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    StoryTemplate template,
    bool isSelected,
    Color accentColor,
    Color textColor,
    Color subtleTextColor,
    Color subtleBorderColor,
  ) {
    return GestureDetector(
      onTap: () => _applyTemplate(template),
      child: Container(
        width: 165, // Adjusted width
        margin: const EdgeInsets.only(right: 14), // Spacing between cards
        decoration: BoxDecoration(
          color: Colors.white, // White background for card
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : subtleBorderColor.withOpacity(0.7),
            width: isSelected ? 2.5 : 1.0, // Thicker border when selected
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(color: accentColor.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))
                ]
              : [],
        ),
        clipBehavior: Clip.antiAlias, // Clip image
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template image
            Image.network(
              template.previewImageUrl,
              height: 120, // Fixed height
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 120,
                  color: Colors.grey[200],
                  child: Center(
                      child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accentColor.withOpacity(0.6),
                  )),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  color: Colors.grey[200],
                  child: Center(
                      child: Icon(
                    Icons.hide_image_outlined,
                    size: 35,
                    color: subtleTextColor.withOpacity(0.5),
                  )),
                );
              },
            ),
            // Template details
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.w600, // Use w600 for card titles
                      fontSize: 14,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.theme,
                    style: GoogleFonts.lato(
                      color: subtleTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.child_care_outlined, size: 14, color: subtleTextColor),
                      const SizedBox(width: 4),
                      Text(
                        '${template.recommendedAge} yrs', // Abbreviate
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: subtleTextColor,
                          fontWeight: FontWeight.w500,
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

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    required String validatorText,
    required Color textColor,
    required Color accentColor,
    required Color subtleTextColor,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.lato(fontSize: 15, color: textColor), // Input text style
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.lato(color: subtleTextColor, fontSize: 15),
        hintText: hintText,
        hintStyle: GoogleFonts.lato(color: subtleTextColor.withOpacity(0.7), fontSize: 14),
        prefixIcon: Icon(icon, color: subtleTextColor, size: 20),
        filled: true, // Add background fill
        fillColor: Colors.white.withOpacity(0.7), // Semi-transparent white fill
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.red.shade600, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0), // Adjust padding
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return validatorText;
        }
        return null;
      },
    );
  }

  Widget _buildAgeSelector(
    BuildContext context,
    Color accentColor,
    Color textColor,
    Color subtleTextColor,
    Color shadowColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 10, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recommended Age',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.w600, // Use w600
                  color: textColor,
                ),
              ),
              Text(
                '${_selectedAge} years old',
                style: GoogleFonts.lato(
                  color: accentColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor,
              inactiveTrackColor: accentColor.withOpacity(0.3),
              trackHeight: 6.0,
              thumbColor: accentColor,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
              overlayColor: accentColor.withOpacity(0.2),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
              valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
              valueIndicatorColor: accentColor.withOpacity(0.8),
              valueIndicatorTextStyle: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 12.0,
              ),
            ),
            child: Slider(
              value: _selectedAge.toDouble(),
              min: _ageOptions.first.toDouble(),
              max: _ageOptions.last.toDouble(),
              divisions: _ageOptions.length - 1,
              label: '$_selectedAge yrs', // Tooltip label
              onChanged: (value) {
                setState(() {
                  _selectedAge = value.round();
                });
              },
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_ageOptions.first} yrs',
                style: GoogleFonts.lato(color: subtleTextColor, fontSize: 12),
              ),
              Text(
                '${_ageOptions.last} yrs',
                style: GoogleFonts.lato(color: subtleTextColor, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageCountSelector(
    BuildContext context,
    Color accentColor,
    Color textColor,
    Color subtleTextColor,
    Color shadowColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 10, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Number of Pages',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Text(
                '$_selectedPageCount pages',
                style: GoogleFonts.lato(
                  color: accentColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: _pageCountOptions.map((count) {
              final isSelected = _selectedPageCount == count;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPageCount = count;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? accentColor : subtleTextColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(color: accentColor.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))
                          ]
                        : null,
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.lato(
                      color: isSelected ? Colors.white : textColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            'Longer stories take more time to generate',
            style: GoogleFonts.lato(
              color: subtleTextColor,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, Color accentColor, VoidCallback onSubmit) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.auto_fix_high_rounded, size: 20), // Sparkle icon
      label: Text(
        'Generate Story',
        style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      onPressed: onSubmit,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, // Text/icon color
        backgroundColor: accentColor, // Button background color
        padding: const EdgeInsets.symmetric(vertical: 16), // Button padding
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), // Highly rounded button
        ),
        elevation: 3, // Button shadow
        shadowColor: accentColor.withOpacity(0.4),
      ),
    );
  }

  void _submitForm() {
    // Hide keyboard before submitting
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      context.read<StoryCreationCubit>().createStory(
            title: _titleController.text,
            description: _descriptionController.text,
            theme: _themeController.text,
            age: _selectedAge,
            pageCount: _selectedPageCount, // Pass the selected page count
            templateId: _selectedTemplateId, // Pass the selected template ID
          );
    } else {
      // Optional: Show a snackbar if validation fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all required fields.', style: GoogleFonts.lato()),
          backgroundColor: Colors.orange.shade700,
        ),
      );
    }
  }
}