# Supabase Database Setup

## Quick Start

1. Go to your Supabase project: https://supabase.com/dashboard/project/cquijdaatorygfdktxrv
2. Open the **SQL Editor** (left sidebar)
3. Click **New Query**
4. Copy and paste the contents of `schema.sql` into the editor
5. Click **Run**

## What the schema creates

- `houses` — Groups users into shared households
- `profiles` — User nicknames, emails, and house membership
- `rooms` — Rooms within a house
- `categories` — Product categories per house
- `products` — Inventory items
- `product_history` — Audit log for all product changes
- `invitations` — House join requests

## Row Level Security (RLS)

All tables have RLS policies so that:
- Users can only read/update their own `profile`
- House members can read/manage `rooms`, `categories`, and `products` in their house
- Product history is readable by house members
- Invitations are readable by the sender and the house creator

## Auth Configuration

In your Supabase Dashboard:
1. Go to **Authentication > Providers**
2. Ensure **Email** provider is enabled
3. You may want to disable **Confirm email** for easier testing (optional)

## Supabase Credentials

**Never commit credentials to version control.**

For local development, pass them via `--dart-define` when running the app:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

For production builds, configure `SUPABASE_URL` and `SUPABASE_ANON_KEY` as GitHub repository secrets. They are injected via `--dart-define` in the CI/CD workflow.
