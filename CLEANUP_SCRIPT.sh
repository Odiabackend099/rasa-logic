#!/bin/bash
# Production cleanup script - removes test files and debugging code

echo "🧹 Production Cleanup Script"
echo "============================"
echo ""

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$BASE_DIR/backend"

# Remove test files
echo "1. Removing test files..."
cd "$BACKEND_DIR"
rm -f test-minimax-tts.js
rm -f test-tts-final.js
rm -f test-tts-autoplay.js
rm -f test-all-voices-autoplay.js
echo "   ✅ Test files removed"

# Remove log files
echo "2. Removing log files..."
rm -f combined.log error.log
echo "   ✅ Log files removed"

# Remove temporary files
echo "3. Removing temporary files..."
rm -rf tmp/
echo "   ✅ Temporary files removed"

# Check for console statements
echo ""
echo "4. Checking for remaining console statements..."
CONSOLE_COUNT=$(grep -r "console\." services/ routes/ --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')
if [ "$CONSOLE_COUNT" -gt 0 ]; then
  echo "   ⚠️  Found $CONSOLE_COUNT console statements"
  echo "   Review these files:"
  grep -rn "console\." services/ routes/ --exclude-dir=node_modules 2>/dev/null | cut -d: -f1 | sort -u
else
  echo "   ✅ No console statements found"
fi

# Check for TODO comments
echo ""
echo "5. Checking for TODO comments..."
TODO_COUNT=$(grep -r "TODO" backend/ --exclude-dir=node_modules 2>/dev/null | grep -v ".gitignore" | wc -l | tr -d ' ')
if [ "$TODO_COUNT" -gt 0 ]; then
  echo "   ⚠️  Found $TODO_COUNT TODO comments"
  echo "   Review these files:"
  grep -rn "TODO" backend/ --exclude-dir=node_modules 2>/dev/null | grep -v ".gitignore" | cut -d: -f1 | sort -u
else
  echo "   ✅ No TODO comments found"
fi

# Fix hardcoded path in START_SERVICES.sh
echo ""
echo "6. Fixing hardcoded paths..."
if [ -f "START_SERVICES.sh" ]; then
  sed -i '' 's|BASE_DIR="/Users/odiadev/Desktop/rasa open source"|BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"|g' START_SERVICES.sh
  echo "   ✅ START_SERVICES.sh path fixed"
fi

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "Next steps:"
echo "1. Run: npm install winston (in backend directory)"
echo "2. Test the logger: node -e \"const logger = require('./backend/utils/logger'); logger.info('Test');\""
echo "3. Review git status: git status"
echo "4. Commit changes"
