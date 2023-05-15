<#
    .SYNOPSIS
        A PowerShell script for creating directory structures based on an input file.

    .DESCRIPTION
        This script reads a list of folder names from a text file, where each line represents a folder and the depth of the folder in the directory structure is indicated by the number of tabs at the start of the line. It supports abbreviations, which are surrounded by double curly brackets ({{}}) and expand to the contents of a text file with the same name as the abbreviation. Currently, abbreviation nesting is not supported.

    .NOTES
        Author: Mark Bowden
        Date: 5/15/23
        Version: 0.9.2
		
		
		# Example folderNames.txt:
		Folder1
			Folder2
				{{abbreviations}}
		Folder3

		Example abbreviations.txt
		abfolder1
			abfolder2
		abfolder3
			abfolder4
				abfolder5

		Result:
		0
		├───Folder1
		│   └───Folder2
		│       ├───abfolder1
		│       │   └───abfolder2
		│       └───abfolder3
		│           └───abfolder4
		│               └───abfolder5
		└───Folder3
			├───abFolder1
			│   └───abfolder2
			└───abfolder3
				└───abfolder4
					└───abfolder5
#>

# Specify the path to the contents file
$contentsFile = ".\folderNames.txt"

# Set the directory to current directory
$parentDirectory = ".\"

$processedContentsFile = ".\macro-use-temp1.txt"

function Expand-Abbreviations {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$inputFile,
        
        [Parameter(Mandatory=$true)]
        [string]$outputFile
    )

    $lines = Get-Content $inputFile

    $processedLines = New-Object System.Collections.Generic.List[string]

    foreach ($line in $lines) {
		# Is the name surrounded in {{curly brackets}}?
        if ($line -match "(.*?){{(.+)}}") {
			# Get the name between the brackets and use as a filename.
            $abbreviationFile = ".\$($matches[2]).txt"
            if (Test-Path $abbreviationFile) {
                $tabs = [regex]::Match($line, "^\t*").Value
                $abbreviationLines = Get-Content $abbreviationFile
				# For each expansion line, add the tabs from the abbreviated line and save to output.
                foreach ($abbreviationLine in $abbreviationLines) {
                    $processedLines.Add($tabs + $abbreviationLine)
                }
            } else {
                Write-Host "File $abbreviationFile does not exist."
            }
        } else {
            $processedLines.Add($line)
        }
    }
    ($processedLines -join "`r`n") | Out-File $outputFile
}

# Call the preprocessor function
Expand-Abbreviations -inputFile $contentsFile -outputFile $processedContentsFile

# Then use $processedContentsFile in the folder creation script
$folderNames = Get-Content $processedContentsFile

# Create an empty stack to hold parent directories
$parentDirectories = New-Object System.Collections.Stack

# Start with the parent directory
$parentDirectories.Push($parentDirectory)

$prevPath = $parentDirectory

foreach ($line in $folderNames) {
    # Get depth based on number of tabs
    $depth = ([regex]::Matches($line, "`t")).Count
    $folderName = $line.TrimStart("`t")
	
    # If we are going down in the tree
    if ($depth -gt $prevDepth) {
        $parentDirectories.Push($prevPath)
        $prevDepth++
    }
	else{
    # If we are going up in the tree
    while ($depth -lt $prevDepth) {
        $parentDirectories.Pop() | Out-Null
        $prevDepth --
    }}
	
	# Combine the parent directory path and the new folder name
    $newFolderPath = Join-Path -Path $parentDirectories.Peek() -ChildPath $folderName
    # Create the new directory
    New-Item -ItemType Directory -Force -Path $newFolderPath | Out-Null
	
	# Set up for next run
	$prevPath = $newFolderPath
	$prevDepth = $depth
}
