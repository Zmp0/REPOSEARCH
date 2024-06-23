#!/bin/bash

# Check if a search keyword was provided
if [ -z "$1" ]; then
  echo "Usage: $0 <search_keyword> [output_file]"
  exit 1
fi

# Define the search keyword
SEARCH_KEYWORD="$*"

# URL encode the search keyword
ENCODED_KEYWORD=$(echo "$SEARCH_KEYWORD" | jq -s -R -r @uri)

# Get the directory where the script is located
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Define the path for the temporary file
TEMP_FILE="$SCRIPT_DIR/github_search_results.json"

# Use wget to fetch the search results page for repositories in JSON format
wget -qO- "https://api.github.com/search/repositories?q=$ENCODED_KEYWORD" > "$TEMP_FILE"

# Check if the fetched content is valid JSON
if jq empty "$TEMP_FILE" 2>/dev/null; then
  # Extract the .git repository links and star count from the JSON file
  RESULTS=$(jq -r '.items[] | .html_url + ".git (rating: " + (.stargazers_count|tostring) + ")"' "$TEMP_FILE")
else
  # If not JSON, fallback to HTML parsing
  wget -qO- "https://github.com/search?q=$ENCODED_KEYWORD&type=repositories" > "$SCRIPT_DIR/github_search_results.html"
  RESULTS=$(grep -oP 'href="\/[^"]+\/[^"]+"' "$SCRIPT_DIR/github_search_results.html" | sed -n 's/href="\/\([^"]\+\)"/https:\/\/github.com\/\1.git (rating: unknown)/p' | uniq)
fi

# Extract ratings and sort the results by rating in descending order
SORTED_RESULTS=$(echo "$RESULTS" | grep -oP 'https:\/\/github\.com\/[^ ]+ \(rating: \K\d+' | paste -d ' ' - <(echo "$RESULTS") | sort -nr | cut -d ' ' -f 2-)

# Determine the length of the longest repository URL
MAX_URL_LENGTH=0
while IFS= read -r line; do
  repo_url=$(echo "$line" | sed 's/ (rating:.*//')
  url_length=${#repo_url}
  if [ $url_length -gt $MAX_URL_LENGTH ]; then
    MAX_URL_LENGTH=$url_length
  fi
done <<< "$SORTED_RESULTS"

# Add 2 to the longest URL length for the arrow spacing
ARROW_POSITION=$((MAX_URL_LENGTH + 2))

# Function to format the results
format_line() {
  local repo_url="$1"
  local rating="$2"
  printf "%-${ARROW_POSITION}s ------------> (rating: %s)\n" "$repo_url" "$rating"
}

# Process and format the sorted results
FORMATTED_RESULTS=""
while IFS= read -r line; do
  repo_url=$(echo "$line" | sed 's/ (rating:.*//')
  rating=$(echo "$line" | sed 's/.* (rating: \(.*\))/\1/')
  formatted_line=$(format_line "$repo_url" "$rating")
  FORMATTED_RESULTS="$FORMATTED_RESULTS$formatted_line\n"
done <<< "$SORTED_RESULTS"

# Check if an output file was provided
if [ -n "$2" ]; then
  OUTPUT_FILE="$2"
  echo -e "$FORMATTED_RESULTS" > "$OUTPUT_FILE"
  echo "Results saved to $OUTPUT_FILE"
else
  echo -e "$FORMATTED_RESULTS"
fi

