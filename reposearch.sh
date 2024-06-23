#!/bin/bash

# Check if a search keyword was provided
if [ -z "$1" ]; then
  echo "Usage: $0 <search_keyword> [output_file]"
  exit 1
fi

# Define the search keyword
SEARCH_KEYWORD="$*"

# URL encode the search keyword
ENCODED_KEYWORD=$(echo "$SEARCH_KEYWORD" | sed 's/ /%20/g')

# Get the directory where the script is located
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Define the path for the temporary file
TEMP_FILE="$SCRIPT_DIR/github_search_results.json"

# Use wget to fetch the search results page for repositories in JSON format
wget -qO- "https://api.github.com/search/repositories?q=$ENCODED_KEYWORD" > "$TEMP_FILE"

# Check if the fetched content is valid JSON
if jq empty "$TEMP_FILE" 2>/dev/null; then
  # Extract the .git repository links from the JSON file
  RESULTS=$(jq -r '.items[] | .html_url + ".git"' "$TEMP_FILE")
else
  # If not JSON, fallback to HTML parsing
  wget -qO- "https://github.com/search?q=$ENCODED_KEYWORD&type=repositories" > "$SCRIPT_DIR/github_search_results.html"
  RESULTS=$(grep -oP 'href="\/[^"]+\/[^"]+"' "$SCRIPT_DIR/github_search_results.html" | sed -n 's/href="\/\([^"]\+\)"/https:\/\/github.com\/\1.git/p' | uniq)
fi

# Check if an output file was provided
if [ -n "$2" ]; then
  OUTPUT_FILE="$2"
  echo "$RESULTS" > "$OUTPUT_FILE"
  echo "Results saved to $OUTPUT_FILE"
else
  echo "$RESULTS"
fi

