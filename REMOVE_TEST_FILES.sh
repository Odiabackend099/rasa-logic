#!/bin/bash
# Script to remove all test files before production push

echo "🗑️  Removing test files and temporary data..."

cd "$(dirname "$0")/backend"

# Remove test files
rm -f test-*.js
echo "✅ Removed test-*.js files"

# Remove log files
rm -f *.log combined.log error.log
echo "✅ Removed log files"

# Remove temporary directory
rm -rf tmp/
echo "✅ Removed tmp/ directory"

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "Next: Review git status and commit"
