final class AppConfig {
  AppConfig._();

  // Supabase
  static const supabaseUrl = 'https://riikpjuqkgpbdarodiek.supabase.co';
  static const supabaseAnonKey =
      'sb_publishable_0WSUZ1RXR9zIzQkh4N6NhA_VJg_iMgl';

  // Application identity (used for Supabase app lookup and data scoping)
  static const appKey = 'home_inventory';
  static const packageName = 'com.takasu.home_inventory';

  // GitHub (update checker)
  static const githubOwner = 'GiovanniDrago';
  static const githubRepo = 'home_inventory';
}
