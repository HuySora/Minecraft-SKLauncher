if(!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`"  `"$($MyInvocation.MyCommand.UnboundArguments)`""
    Exit
}
Push-Location $PSScriptRoot

# Function to setup modpack files
function Setup-Modpack {
    param(
        [string]$modpackPath
    )
    $clientScript = Join-Path $modpackPath "setup-client-files.ps1"
    if (Test-Path $clientScript) {
        $executeLine = "$clientScript -Silent"
        Write-Host "EXECUTE: $executeLine"
        & $executeLine
    }
    $serverScript = Join-Path $modpackPath ".server\setup-server-files.ps1"
    if (Test-Path $serverScript) {
        $executeLine = "$serverScript -Silent"
        Write-Host "EXECUTE: $executeLine"
        & $executeLine
    }
}

# Function to update a submodule
function Update-Submodule {
    param(
        [string]$submodulePath
    )
    git submodule update --init --recursive $submodulePath
    try {
        # Change directory to the submodule path
        Push-Location $submodulePath

        # Fetch all branches
        git fetch --all
        # Checkout the master branch
        git checkout -f master
        # Stash changes
        try {
            git stash save --all
            # Reset to the latest upstream head
            git clean -fdx
            git reset --hard "@{u}"
            # Also re-setup the modpack to avoid multiple stash push-pop
            Setup-Modpack -modpackPath " "
        }
        finally {
            # Pop stash
            git stash pop
        }
    }
    finally {
        # Change directory back to the root directory
        Pop-Location
    }
}

# Loop until the user chooses to exit
do {
    try {
        # Get the list of submodule status
        $gitCmdRet = git submodule status
        $submodules = @()
        # Process each line of the output
        foreach ($line in $gitCmdRet -split "`n") {
            # Use regex to extract SHA, submodule name, and branch
            $pattern = "(?<sha>\-?[0-9a-f]{40})\s+(?<name>[\.\w\-]+)(\s+\((?<branch>.*?)\))?"
            if ($line -match $pattern) {
                # Create a custom object for each submodule
                Write-Host "2"
                $submodule = [PSCustomObject]@{
                    Id      = $submodules.Count + 1 # 1-based index
                    Name    = $matches['name']
                    Branch  = $matches['branch']
                    SHA     = $matches['sha']
                }
                # Add the submodule object to the array
                $submodules += $submodule
            }
        }
        # Output the array of submodules
        $submodules | Format-Table -AutoSize

        # Prompt the user to select a submodule to update
        $submoduleIndex = Read-Host "Input (Q to quit): "

        # Check if the user wants to quit
        if ($submoduleIndex -eq "Q" -or $submoduleIndex -eq "q") {
            Write-Host " "
            Write-Host "Exiting..."
            Exit
        }
        
        # Check if the user input is valid
        if (-not ([int]::TryParse($submoduleIndex, [ref]$null))) {
            Write-Host "ERROR: Please enter a valid number"
            Continue
        }
        $submoduleIndex = [int]$submoduleIndex
        if ($submoduleIndex -lt 1 -or $submoduleIndex -gt $submodules.Count) {
            Write-Host "ERROR: Please enther a valid id"
            Continue
        }

        Write-Host " "

        # Update the selected submodule
        $selectedSubmodule = $submodules[$submoduleIndex - 1].Name
        Write-Host "Updating submodule $selectedSubmodule"
        Update-Submodule -submodulePath ".\$selectedSubmodule"

        Write-Host "Update completed."
    }
    finally {
    }
} while ($true)
