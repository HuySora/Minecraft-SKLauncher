# Function to update a submodule
function Update-Submodule {
    param(
        [string]$submodulePath
    )

    # Change directory to the submodule path
    Push-Location $submodulePath

    git submodule update --init

    # Fetch all branches
    git fetch --all

    # Checkout the master branch
    git checkout -f master

    # Reset to the latest upstream head
    git reset --hard "@{u}"

    # Change directory back to the root directory
    Pop-Location
}

# Main script
# Loop until the user chooses to exit
do {
    # Get the list of submodule directories
    $submoduleDirectories = Get-ChildItem -Path .\ -Directory -Filter ".*"

    # Display the list of submodules to the user
    Write-Host "Available Submodules:"
    for ($i = 0; $i -lt $submoduleDirectories.Count; $i++) {
        Write-Host "$($i + 1). $($submoduleDirectories[$i].Name)"
    }
    Write-Host "X. Exit"

    # Prompt the user to select a submodule to update
    $submoduleIndex = Read-Host "Enter the number of the submodule you want to update (or 'X' to quit)"

    # Check if the user wants to exit
    if ($submoduleIndex -eq "X" -or $submoduleIndex -eq "x") {
        Write-Host "Exiting..."
        Exit
    }

    # Check if the user input is valid
    if (-not ([int]::TryParse($submoduleIndex, [ref]$null))) {
        Write-Host "Invalid input. Please enter a valid number or 'X' to quit."
        Continue
    }

    $submoduleIndex = [int]$submoduleIndex

    if ($submoduleIndex -lt 1 -or $submoduleIndex -gt $submoduleDirectories.Count) {
        Write-Host "Invalid input. Please enter a valid number within the range or 'X' to quit."
        Continue
    }

    # Update the selected submodule
    $selectedSubmodule = $submoduleDirectories[$submoduleIndex - 1].Name
    Write-Host "Updating submodule: $selectedSubmodule"
    Update-Submodule -submodulePath ".\$selectedSubmodule"

    Write-Host "Submodule update completed."
} while ($true)
