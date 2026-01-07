# PowerSync Attachments Helper Example

A Flutter demo application showcasing PowerSync Attachments Helper API usage with Supabase backend.

## Features

- ✨ Real-time post synchronization with PowerSync
- 📎 Attachment upload with progress tracking
- 🖼️ Image compression and optimization
- 📊 Upload progress indicators with byte-level tracking
- 💾 Offline-first architecture
- 🔄 Automatic sync when back online
- 🗄️ Supabase Storage integration
- 🔐 Row Level Security (RLS) policies

## Tech Stack

- **Flutter** - Cross-platform mobile framework
- **PowerSync** - Offline-first sync engine
- **Supabase** - Backend as a Service (Database + Storage + Auth)
- **PostgreSQL** - Database with logical replication

## Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK
- Supabase account and project
- PowerSync account and instance

### Installation

1. Clone the repository
2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Configure your environment variables in `packages/env/` and run ./scripts/build_runner.sh env

4. Run Supabase migrations:

   ```bash
   supabase db push
   ```

5. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

- `lib/` - Flutter application code
- `packages/powersync_client/` - PowerSync client implementation
- `packages/shared/` - Shared models and utilities
- `supabase/migrations/` - Database migrations

## Resources

- [PowerSync Documentation](https://docs.powersync.com/)
- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Documentation](https://docs.flutter.dev/)

## License

This project is licensed under the MIT License.
