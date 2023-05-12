# Specify the path to the contents file
$contentsFile = ".\folderNames.txt"

# Set the directory to current directory
$parentDirectory = ".\"

$processedContentsFile1 = ".\macro-use-temp1.txt"
$processedContentsFile2 = ".\macro-use-temp2.txt"

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
        if ($line -match "{{(.+)}}") {
            $abbreviationFile = ".\$($matches[1]).txt"
            if (Test-Path $abbreviationFile) {
                $tabs = [regex]::Match($line, "^\t*").Value
                $abbreviationLines = Get-Content $abbreviationFile
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
	$processedLines | Out-File $outputFile
}

function Enumerate-Folders {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$inputFilePath,

        [Parameter(Mandatory=$true)]
        [string]$outputFile
    )

    $inputFile = Get-Content $inputFilePath

    # Create an empty stack to hold folder enumerations
    $folderEnumerations = New-Object System.Collections.Stack
    $folderEnumerations.Push(0)

    # Initialize previous depth
    $prevDepth = 0

    # Output array
    $enumeratedFolders = New-Object System.Collections.Generic.List[string]

    # each line is considered as a folder name, we'll iterate by line
    foreach ($line in $inputFile) {
        # Get depth based on number of tabs
        $depth = ([regex]::Matches($line, "`t")).Count
        $line = $line.TrimStart("`t")

        # Check if we are going deeper
        if ($depth -gt $prevDepth) {
            # Reset enumeration for new depth level
            $folderEnumerations.Push(0)
        } elseif ($depth -lt $prevDepth) {
            # If depth decreased, pop enumerations from the stack
            for ($j=0; $j -lt ($prevDepth - $depth); $j++) {
                $folderEnumerations.Pop()
            }
        }

        # Prepare the folder name
        $folderName = ("`t" * $depth) + ($folderEnumerations.Peek()).ToString() + ". " + $line
        # Increment the enumeration for the current depth level
        $folderEnumerations.Push($folderEnumerations.Pop() + 1)

        # Add the folder name to the output array
        $enumeratedFolders.Add($folderName)

        # Set previous depth to current depth
        $prevDepth = $depth
    }

    # Join the folder names with new lines and write to the output file
    ($enumeratedFolders -join "`r`n") | Out-File $outputFile
}



<# Begin Procedural Code
------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------
------------------------------------------------------------------
#>

Expand-Abbreviations -inputFile $contentsFile -outputFile $processedContentsFile1

Enumerate-Folders -inputFile $processedContentsFile1 -outputFile $processedContentsFile2

# Then use $processedContentsFile in the folder creation script
$folderNames = Get-Content $processedContentsFile2

# Create an empty stack to hold parent directories
$parentDirectories = New-Object System.Collections.Stack



# Start with the parent directory
$parentDirectories.Push($parentDirectory)

# Initialize previous depth
$prevDepth = 0

# each line is considered as a folder name, we'll iterate by line
for ($i=0; $i -lt $folderNames.Length; $i++) {
    # Get depth based on number of tabs
    $depth = ([regex]::Matches($folderNames[$i], "`t")).Count
    $folderNames[$i] = $folderNames[$i].TrimStart("`t")

    # Check if we are going deeper
    if ($depth -gt $prevDepth) {
        # Push last created directory to the stack
        $parentDirectories.Push($newFolderPath)
        # Reset enumeration for new depth level
    }
    elseif ($depth -lt $prevDepth) {
        # If depth decreased, pop directories and enumerations from the stack
        for ($j=0; $j -lt ($prevDepth - $depth); $j++) {
            $parentDirectories.Pop()
        }
    }

    # Prepare the folder name
    $folderName = $folderNames[$i]

    # Combine the parent directory path and the new folder name
    $newFolderPath = Join-Path -Path $parentDirectories.Peek() -ChildPath $folderName

    # Create the new directory
    New-Item -ItemType Directory -Force -Path $newFolderPath

    # Set previous depth to current depth
    $prevDepth = $depth
}
