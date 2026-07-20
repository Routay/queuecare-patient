# #!/bin/bash

# # Vercel doesn't have Flutter pre-installed, so we install it during the build process
# echo "Cloning Flutter stable branch..."
# git clone https://github.com/flutter/flutter.git -b stable

# # Add Flutter to the path
# export PATH="$PATH:`pwd`/flutter/bin"

# echo "Verifying Flutter version..."
# flutter --version

# echo "Building the Flutter web app..."
# flutter build web --release


#!/bin/bash
set -e

echo "Cloning Flutter 3.35.4..."

git clone https://github.com/flutter/flutter.git
cd flutter
git checkout 3.35.4
cd ..

export PATH="$PATH:$(pwd)/flutter/bin"

echo "Flutter version:"
flutter --version

echo "Getting dependencies..."
flutter pub get

echo "Building..."
flutter build web --release