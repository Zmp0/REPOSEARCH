# GitHub Search Script

## Overview

This script allows you to search for GitHub repositories using a specified keyword and retrieve their .git URLs. It can either display these URLs in the terminal or save them to a file,easy like that.

#### Requirements

   - Bash (Bourne Again SHell)
   - wget (for fetching web pages)
   - jq (optional, for parsing JSON responses from GitHub API)

# LINUX

#### First change the permission with:

	chmod +x reposearch.sh

#### Command Syntax


    ./reposearch.sh <search_keyword> [output_file]

  - <search_keyword>: Specify the keyword to search for repositories on GitHub.
  - [output_file] (optional): If provided, the script will save the results to this file. If not provided, results will be displayed in the terminal.

#### Examples

Display results in the terminal:


    ./reposearch.sh machine+learning

Save results to a file:


    ./reposearch.sh machine+learning results.txt


If the name is just one word,remove the plus sign


# WINDOWS(Powershell)

### Execution Policy:

- Ensure PowerShell execution policy allows running scripts. You can set it using:

        Set-ExecutionPolicy RemoteSigned

  Choose Y (Yes) to confirm.

   
#### Command Syntax


	.\reposearch.ps1 <search_keyword> [output_file]

- <search_keyword>: Specify the keyword to search for repositories on GitHub.
- [output_file] (optional): If provided, the script will save the results to this file. If not provided, results will be displayed in the terminal.

## Examples

- Display results in the terminal:


		.\reposearch.ps1 machine+learning

- Save results to a file:


		.\reposearch.ps1 machine+learning results.txt

If the name is just one word,remove the plus sign
