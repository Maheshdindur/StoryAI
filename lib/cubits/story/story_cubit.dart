import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:story_ai_app/repositories/story_repositories.dart';
import '../../models/story_model.dart';

// State
class StoryState extends Equatable {
  final List<Story> stories;
  final bool isLoading;
  final String? error;
  final Story? selectedStory;

  const StoryState({
    this.stories = const [],
    this.isLoading = false,
    this.error,
    this.selectedStory,
  });

  StoryState copyWith({
    List<Story>? stories,
    bool? isLoading,
    String? error,
    Story? selectedStory,
    bool clearError = false,
    bool clearSelectedStory = false,
  }) {
    return StoryState(
      stories: stories ?? this.stories,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      selectedStory: clearSelectedStory ? null : selectedStory ?? this.selectedStory,
    );
  }

  @override
  List<Object?> get props => [stories, isLoading, error, selectedStory];
}

// Cubit
class StoryCubit extends Cubit<StoryState> {
  final StoryRepository storyRepository;

  StoryCubit({required this.storyRepository}) : super(const StoryState());

  Future<void> loadStories() async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));
      final stories = await storyRepository.getStories();
      emit(state.copyWith(stories: stories, isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> getStory(String id) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));
      final story = await storyRepository.getStory(id);
      emit(state.copyWith(selectedStory: story, isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> addStory(Story story) async {
    emit(state.copyWith(
      stories: [...state.stories, story],
      clearError: true,
    ));
  }

  Future<void> deleteStory(String id) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));
      await storyRepository.deleteStory(id);
      final updatedStories = state.stories.where((story) => story.id != id).toList();
      emit(state.copyWith(stories: updatedStories, isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }
}