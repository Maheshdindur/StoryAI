import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:story_ai_app/repositories/story_repositories.dart';
import '../../models/story_model.dart';
import 'dart:async';  // Add this import for Timer

// State
class StoryCreationState extends Equatable {
  final bool isCreating;
  final double progress;
  final String? error;
  final Story? createdStory;

  const StoryCreationState({
    this.isCreating = false,
    this.progress = 0.0,
    this.error,
    this.createdStory,
  });

  StoryCreationState copyWith({
    bool? isCreating,
    double? progress,
    String? error,
    Story? createdStory,
    bool clearError = false,
    bool clearCreatedStory = false,
  }) {
    return StoryCreationState(
      isCreating: isCreating ?? this.isCreating,
      progress: progress ?? this.progress,
      error: clearError ? null : error ?? this.error,
      createdStory: clearCreatedStory ? null : createdStory ?? this.createdStory,
    );
  }

  @override
  List<Object?> get props => [isCreating, progress, error, createdStory];
}

// Cubit
class StoryCreationCubit extends Cubit<StoryCreationState> {
  final StoryRepository storyRepository;
  Timer? _progressTimer;  // Timer to update progress

  StoryCreationCubit({required this.storyRepository}) : super(const StoryCreationState());

  Future<void> createStory({
    required String title,
    required String description,
    required String theme,
    required int age,
    required int pageCount,
    String? templateId,

  }) async {
    try {
      emit(state.copyWith(
        isCreating: true,
        progress: 0.1,
        clearError: true,
        clearCreatedStory: true,
      ));

      // Start updating progress
      _updateProgressPeriodically();

      final story = await storyRepository.createStory(
        title: title,
        description: description,
        theme: theme,
        age: age,
        pageCount: pageCount,
        templateId: templateId,
      );

      // Cancel timer when done
      _progressTimer?.cancel();
      
      emit(state.copyWith(
        isCreating: false,
        progress: 1.0,
        createdStory: story,
      ));
    } catch (e) {
      // Cancel timer on error
      _progressTimer?.cancel();
      
      emit(state.copyWith(
        isCreating: false,
        error: e.toString(),
        progress: 0.0,
      ));
    }
  }

  void _updateProgressPeriodically() {
    // Cancel any existing timer
    _progressTimer?.cancel();
    
    // Create a new timer that fires every second
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Don't update if not creating or if we're already at high progress
      if (!state.isCreating || state.progress >= 0.95) {
        timer.cancel();
        return;
      }
      
      // Calculate new progress
      double newProgress;
      
      if (state.progress < 0.2) {
        // Initial jump to 20%
        newProgress = 0.2;
      } else if (state.progress < 0.5) {
        // Slower progress to 50%
        newProgress = state.progress + 0.05;
      } else if (state.progress < 0.8) {
        // Even slower progress to 80%
        newProgress = state.progress + 0.03;
      } else {
        // Very slow progress to 95%
        newProgress = state.progress + 0.01;
      }
      
      // Ensure we don't go above 0.95 (95%)
      newProgress = newProgress.clamp(0.0, 0.95);
      
      // Emit new state with updated progress
      emit(state.copyWith(progress: newProgress));
    });
  }

  void resetState() {
    _progressTimer?.cancel();
    emit(const StoryCreationState());
  }
  
  @override
  Future<void> close() {
    _progressTimer?.cancel();
    return super.close();
  }
}