import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:story_ai_app/cubits/story/story_cubit.dart';
import 'package:story_ai_app/cubits/story_creation/story_creation.dart';
import 'package:story_ai_app/repositories/story_repositories.dart';
import 'package:story_ai_app/screens/create_story_screen.dart';
import 'package:story_ai_app/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'screens/story_detailed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // Initialize Gemini API
  final geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  final generativeModel = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: geminiApiKey,
  );
  
  // Setup repositories
  final storyRepository = StoryRepository(
    supabase: Supabase.instance.client,
    generativeModel: generativeModel,
  );
  
  runApp(MyApp(storyRepository: storyRepository));
}

class MyApp extends StatelessWidget {
  final StoryRepository storyRepository;
  
  const MyApp({Key? key, required this.storyRepository}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<StoryCubit>(
          create: (context) => StoryCubit(storyRepository: storyRepository)..loadStories(),
        ),
        BlocProvider<StoryCreationCubit>(
          create: (context) => StoryCreationCubit(storyRepository: storyRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Story AI App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        // Remove home property and use initialRoute instead
        initialRoute: HomeScreen.routeName,
        routes: {
          HomeScreen.routeName: (context) => const HomeScreen(),
          StoryDetailScreen.routeName: (context) => const StoryDetailScreen(),
          CreateStoryScreen.routeName: (context) => const CreateStoryScreen(),
        },
      ),
    );
  }
}