# Supabase Database Setup

This app uses the shared application-database Supabase project.

## Project

- **URL**: `https://supabase.com/dashboard/project/riikpjuqkgpbdarodiek`
- **Project name**: `applications-data`

## Schema

The application schema is defined in the `application-database` repository at:
`/home/takasu/Documents/codinglab/application-database/supabase/migrations/`

It creates the following tables scoped to the HomeInventory app:

- `houses` — Groups users into shared households
- `profiles` — User nicknames, emails, and house membership (extends `users` table)
- `rooms` — Rooms within a house
- `categories` — Product categories per house
- `products` — Inventory items
- `product_history` — Audit log for all product changes
- `invitations` — House join requests

The `applications` table registers `home_inventory` (app_key) with package name `com.takasu.home_inventory`.

## Row Level Security (RLS)

All tables have RLS policies so that:

- Users can only read/update their own `profile`
- House members can read/manage `rooms`, `categories`, and `products` in their house
- Product history is readable by house members
- Invitations are readable by the sender and the house creator

## Auth Configuration

In the Supabase Dashboard:

1. Go to **Authentication > Providers**
2. Ensure **Email** provider is enabled
3. You may want to disable **Confirm email** for easier testing (optional)

## Supabase Credentials

Credentials are hardcoded in `lib/config.dart`. The app uses the shared Supabase project for all applications.

```dart
static const supabaseUrl = 'https://riikpjuqkgpbdarodiek.supabase.co';
static const supabaseAnonKey = 'sb_publishable_...';
```
