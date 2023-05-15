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

$contentsFile = ".\folderNames.txt"
$parentDirectory = ".\"
$processedContentsFile = ".\macro-use-temp1.txt"

$script:folderCount = 0
$folderLimit = 2000

<#
.SYNOPSIS
This function expands abbreviations found in the input file by replacing them with the contents of the corresponding abbreviation files.

.DESCRIPTION
The function takes an inputFile and an outputFile as parameters. It reads the inputFile line by line. Abbreviations (a word enclosed in double curly braces) are expanded. It checks if a file with the name of the abbreviation exists. If it does, it recursively calls itself to process the abbreviation file.

The processed files are stored in the outputFile with abbreviations replaced by their corresponding contents. If a circular reference is detected, an exception is thrown.

.PARAMETERS
- inputFile: The path of the file to be processed.
- outputFile: The path of the file where the processed output will be stored.
- processedFiles: Array storing previously processed files for detecting circular references.

#>
function Expand-Abbreviations {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$inputFile,
        
        [Parameter(Mandatory=$true)]
        [string]$outputFile,

        [string[]]$processedFiles = @()
    )

    $lines = Get-Content $inputFile
    $processedLines = New-Object System.Collections.Generic.List[string]

    foreach ($line in $lines) {
        if ($line -match "(.*?){{(.+)}}") {
            $abbreviationFile = ".\$($matches[2]).txt"

            if ($abbreviationFile -in $processedFiles) {
                throw "Circular reference detected in file $abbreviationFile."
            }

            if (Test-Path $abbreviationFile) {
                $tabs = [regex]::Match($line, "^\t*").Value
                $abbreviationLines = Expand-Abbreviations -inputFile $abbreviationFile -outputFile "$abbreviationFile.expanded" -processedFiles ($processedFiles + $abbreviationFile)
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
    return $processedLines
}

Expand-Abbreviations -inputFile $contentsFile -outputFile $processedContentsFile

$folderNames = Get-Content $processedContentsFile
$parentDirectories = New-Object System.Collections.Stack
$parentDirectories.Push($parentDirectory)
$prevPath = $parentDirectory

foreach ($line in $folderNames) {
    $depth = ([regex]::Matches($line, "`t")).Count
    $folderName = $line.TrimStart("`t")
	
    if ($depth -gt $prevDepth) {
        $parentDirectories.Push($prevPath)
        $prevDepth++
    } else {
        while ($depth -lt $prevDepth) {
            $parentDirectories.Pop() | Out-Null
            $prevDepth--
        }
    }

    if ($script:folderCount -ge $folderLimit) {
        Write-Host "Folder limit of $folderLimit reached. No more folders will be created."
        break
    }

    $newFolderPath = Join-Path -Path $parentDirectories.Peek() -ChildPath $folderName
    New-Item -ItemType Directory -Force -Path $newFolderPath | Out-Null

    $prevPath = $newFolderPath
    $prevDepth = $depth
    $script:folderCount++
}
