#!/bin/bash
# Vercel build for the Smart Attendance System (Flutter web).
# Installs the Flutter SDK (stable) and builds the web bundle with
# Supabase credentials injected at compile time via --dart-define.
set -euo pipefail

git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$HOME/flutter"
export PATH="$HOME/flutter/bin:$PATH"
flutter config --enable-web --no-analytics
flutter pub get
flutter build web --release \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-}" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="${SUPABASE_PUBLISHABLE_KEY:-}"
