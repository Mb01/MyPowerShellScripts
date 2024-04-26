# Create a new Excel application object
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false # Run Excel in background

try {
    # Get all Excel files in the current directory
    $files = Get-ChildItem -Path (Get-Location) -Filter "*.xls*"

    foreach ($file in $files) {
        # Open the Excel file
        $workbook = $excel.Workbooks.Open($file.FullName)

        # Specify the path for the PDF output
        $pdfPath = [System.IO.Path]::ChangeExtension($file.FullName, 'pdf')

        # Export the first worksheet as PDF
        $workbook.Worksheets[1].ExportAsFixedFormat(0, $pdfPath)

        # Close the workbook without saving
        $workbook.Close($false)
    }
} catch {
    Write-Error "An error occurred: $_"
} finally {
    # Cleanup: Quit Excel and release COM object
    $excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel)
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}

Write-Output "PDF export completed."
