<#
.SYNOPSIS
    A PowerShell script to populate template files in leaf folders based on a specification file.

.DESCRIPTION
    This script reads a specification file that contains lines in the format "path_to_template,path_to_base_folder".
    It copies the specified template file into each leaf folder in the provided base folder's tree structure.
    Before each copy operation, the script prints the directory where the file will be added and pauses for user input to allow for inspection.

.USAGE
    Save this script to a file named "PopulateTemplates.ps1".

    Create a specification file with lines in the format "path_to_template,path_to_base_folder".
    Example:
        C:\Templates\ExampleTemplate.txt,C:\Projects\BaseFolder1
        C:\Templates\AnotherTemplate.txt,C:\Projects\BaseFolder2

    Run the script in PowerShell:
        .\PopulateTemplates.ps1 -specificationFile "path_to_specification_file"

    Replace "path_to_specification_file" with the actual path to your specification file.

#>

$specificationFile = ".\specification.txt"

function Populate-Templates {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$specificationFile
    )

    # Get the lines from the specification file
    $lines = Get-Content $specificationFile

    foreach ($line in $lines) {
        # Split the line into the path to the template and the path to the base folder
        $parts = $line.Split(',')
        $templatePath = $parts[0].Trim()
        $baseFolderPath = $parts[1].Trim()

        # Make sure both paths exist
        if (!(Test-Path $templatePath) -or !(Test-Path $baseFolderPath)) {
            Write-Host "Either the template path '$templatePath' or the base folder path '$baseFolderPath' does not exist."
            continue
        }

        # Get all the leaf folders in the base folder
        $leafFolders = Get-ChildItem -Path $baseFolderPath -Directory -Recurse | Where-Object { !(Get-ChildItem -Path $_.FullName -Directory) }

        foreach ($leafFolder in $leafFolders) {
			# Print out the directory where the file will be added
            Write-Host "About to add '$templatePath' to '$($leafFolder.FullName)'"	
			# Pause for input
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            # Copy the template file to the leaf folder
            Copy-Item -Path $templatePath -Destination $leafFolder.FullName
        }
    }
}

Populate-Templates -specificationFile $specificationFile
