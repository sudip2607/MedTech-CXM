#!/bin/bash

# Update all MS TOC SQL files to remove the problematic post_hook
for file in models/intermediate/ms_toc/*.sql; do
    # Remove the post_hook line entirely
    sed -i '' '/post_hook=/d' "$file"
    echo "✅ Fixed: $file"
done

echo "All files updated!"