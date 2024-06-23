# Check if a search keyword was provided
if (-not $args[0]) {
    Write-Host "Usage: .\github-search.ps1 <search_keyword> [output_file]"
    exit 1
}

# Define the search keyword
$SEARCH_KEYWORD = $args -join " "

# URL encode the search keyword
$ENCODED_KEYWORD = [System.Web.HttpUtility]::UrlEncode($SEARCH_KEYWORD)

# Get the directory where the script is located
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Define the path for the temporary file
$TEMP_FILE = Join-Path $SCRIPT_DIR "github_search_results.json"

# Use Invoke-WebRequest to fetch the search results page for repositories in JSON format
Invoke-WebRequest -Uri "https://api.github.com/search/repositories?q=$ENCODED_KEYWORD" -OutFile $TEMP_FILE

# Function to extract and sort results
function Get-SortedResults {
    param (
        [string]$filePath
    )

    try {
        $RESULTS_JSON = Get-Content $filePath | ConvertFrom-Json

        # Extract the .git repository links and star count from the JSON file
        $RESULTS = $RESULTS_JSON.items | ForEach-Object {
            [PSCustomObject]@{
                Url = "$($_.html_url).git"
                Rating = [int]$($_.stargazers_count)
            }
        }

        # Sort results by rating in descending order
        $SORTED_RESULTS = $RESULTS | Sort-Object Rating -Descending
        return $SORTED_RESULTS
    }
    catch {
        # If not JSON, fallback to HTML parsing
        $HTML_FILE = Join-Path $SCRIPT_DIR "github_search_results.html"
        Invoke-WebRequest -Uri "https://github.com/search?q=$ENCODED_KEYWORD&type=repositories" -OutFile $HTML_FILE

        $RESULTS = Select-String -Path $HTML_FILE -Pattern 'href="\/[^"]+\/[^"]+"' | ForEach-Object {
            $url = $_.Matches.Value -replace 'href="\/([^"]+)"', 'https://github.com/$1.git'
            [PSCustomObject]@{
                Url = $url
                Rating = 'unknown'
            }
        } | Sort-Object Url -Unique

        return $RESULTS
    }
}

# Get and sort the results
$SORTED_RESULTS = Get-SortedResults -filePath $TEMP_FILE

# Determine the length of the longest repository URL
$MAX_URL_LENGTH = 0
foreach ($result in $SORTED_RESULTS) {
    $url_length = $result.Url.Length
    if ($url_length -gt $MAX_URL_LENGTH) {
        $MAX_URL_LENGTH = $url_length
    }
}

# Add 2 to the longest URL length for the arrow spacing
$ARROW_POSITION = $MAX_URL_LENGTH + 2

# Function to format the results
function Format-Line {
    param (
        [string]$repo_url,
        [string]$rating
    )

    $formatted_line = "{0,-$ARROW_POSITION} ------------> (rating: {1})" -f $repo_url, $rating
    return $formatted_line
}

# Process and format the sorted results
$FORMATTED_RESULTS = ""
foreach ($result in $SORTED_RESULTS) {
    $formatted_line = Format-Line -repo_url $result.Url -rating $result.Rating
    $FORMATTED_RESULTS += "$formatted_line`n"
}

# Check if an output file was provided
if ($args[1]) {
    $OUTPUT_FILE = $args[1]
    $FORMATTED_RESULTS | Out-File -FilePath $OUTPUT_FILE -Encoding utf8
    Write-Host "Results saved to $OUTPUT_FILE"
} else {
    Write-Host $FORMATTED_RESULTS
}
