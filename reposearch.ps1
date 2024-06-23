param (
    [Parameter(Mandatory=$true, Position=0)]
    [string]$searchKeyword,

    [Parameter(Position=1)]
    [string]$outputFile
)

# Check if a search keyword was provided
if (-not $searchKeyword) {
    Write-Host "Usage: $PSCommandPath <search_keyword> [output_file]"
    exit 1
}

# URL encode the search keyword
$encodedKeyword = [uri]::EscapeDataString($searchKeyword)

# Get the directory where the script is located
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Define the path for the temporary file
$tempFile = Join-Path $scriptDir "github_search_results.json"

# Use Invoke-WebRequest to fetch the search results page for repositories in JSON format
Invoke-WebRequest -Uri "https://api.github.com/search/repositories?q=$encodedKeyword" -OutFile $tempFile

# Check if the fetched content is valid JSON
if (Test-Path $tempFile) {
    try {
        $jsonContent = Get-Content $tempFile -Raw | ConvertFrom-Json
        if ($jsonContent.items) {
            # Extract the .git repository links from the JSON file
            $results = $jsonContent.items | ForEach-Object { $_.html_url + ".git" }
        }
    }
    catch {
        Write-Host "Failed to parse JSON content, falling back to HTML parsing."
    }
}

# If JSON parsing failed or no valid JSON content, fallback to HTML parsing
if (-not $results) {
    Invoke-WebRequest -Uri "https://github.com/search?q=$encodedKeyword&type=repositories" -OutFile "$scriptDir\github_search_results.html"
    $htmlContent = Get-Content "$scriptDir\github_search_results.html" -Raw

    # Extract the .git repository links from the HTML file
    $results = [regex]::Matches($htmlContent, 'href="\/[^"]+\/[^"]+"') | ForEach-Object {
        $url = $_.Groups[0].Value -replace 'href="([^"]+)"', 'https://github.com/$1.git'
        $url
    } | Select-Object -Unique
}

# Check if an output file was provided
if ($outputFile) {
    $results | Out-File -FilePath $outputFile -Encoding UTF8
    Write-Host "Results saved to $outputFile"
}
else {
    $results
}
