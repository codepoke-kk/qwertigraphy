# The reference data and image files are both from the amazing work of Richard Liu
# https://github.com/richyliu/greggdict/tree/master

# This script takes the original .json file and converts it to CSV, rather than 
# wrestle with reading it in AHK directly. AHK does not do it natively. 

# Input the data into an array of pages 
$pages = Get-Content -path "$PsScriptRoot\reference.json" | ConvertFrom-Json 

# Create an ArrayList into which to push the findings 
$words = New-Object System.Collections.ArrayList

# Loop across each word of each page and create a Custom Object to hold the 
# word (primary key) and the page on which it can be found 
# X and Y hold the location to focus in order to zoom in on that word 
foreach ($page in $pages) {
    foreach ($word in $page.words) {
        # Write-Host "$($page.page) has $($page.words[0].t)"
        # The PsCustomObject will export most nicely into a CSV
        $reference = New-Object PsCustomObject -Property @{
            word = $word.t
            page = $page.page
            link = "pages\$($page.page).png"
            x = $word.x
            y = $word.y
        }
        $words.Add($reference) | Out-Null
    }
}

# Convert this to array then select the column order I want. 
$words.ToArray() | Select-Object @('word','page','link','x','y') | Export-Csv -Path "$PsScriptRoot\reference.csv" -NoTypeInformation
