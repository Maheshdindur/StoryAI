Story AI App

A Flutter application that generates AI-powered stories with images for children. This app uses Gemini's AI capabilities for story generation and Supabase for data storage.

## Features

- Generate 10-page stories with AI-generated images
- Customize story title, description, theme, and target age
- View all your created stories in a beautiful home screen
- Read stories with page-by-page navigation
- Delete stories you no longer need

## Prerequisites

- Flutter SDK (latest stable version)
- Google Generative AI API key (Gemini)
- Supabase account and project
- Basic knowledge of Flutter development

## Setup Instructions

1. Clone the repository:

   ```
   git clone https://github.com/your-username/story_ai_app.git
   cd story_ai_app
   ```
2. Copy the `.env.template` file to `.env`:

   ```
   cp .env.template .env
   ```
3. Edit the `.env` file and add your credentials:

   ```
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=your-supabase-anon-key
   GEMINI_API_KEY=your-gemini-api-key
   ```
4. Set up Supabase:

   - Create a new Supabase project
   - Go to the SQL Editor
   - Copy and paste the contents of `supabase_schema.sql`
   - Run the SQL queries to create the necessary tables
5. Install dependencies:

   ```
   flutter pub get
   ```
6. Run the app:

   ```
   flutter run
   ```

## Project Structure

- `lib/main.dart` - Entry point for the application
- `lib/models/` - Data models
- `lib/cubits/` - State management using Cubit pattern
- `lib/repositories/` - Data sources and business logic
- `lib/screens/` - UI screens

## Packages Used

- `flutter_bloc` - For state management
- `supabase_flutter` - For backend database
- `google_generative_ai` - For AI story generation
- `equatable` - For value equality
- `cached_network_image` - For image caching
- `flutter_dotenv` - For environment variables
- `uuid` - For generating unique identifiers

## Image Generation

The app uses placeholder images in this implementation. To use real AI-generated images, you would need to integrate with an image generation API like DALL-E, Stable Diffusion, or Midjourney.
