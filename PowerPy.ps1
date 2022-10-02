# Prerequisites:
# Must - Python, Git
# Optional - Poetry

## ------------------------Variables-------------------------
$PythonTools = [ordered]@{}
# Examples:
# Installation method 1: git clone
$PythonTools["carbon14"] = @{Download = "git clone https://github.com/Lazza/Carbon14.git"; Exec = "python .\carbon14.py" }
# Installation method 2: pip install
$PythonTools["maigret"] = @{Download = "python -m pip install maigret"; Exec = "maigret" }
# Installation method 3: pipenv
$PythonTools["telegram-phone-number-checker"] = @{Download = "git clone https://github.com/bellingcat/telegram-phone-number-checker.git"; Exec = "python .\telegram-phone-validation.py" }

## ------------------------Functions-------------------------
function New-PSProfile {
    Write-Host "`nChecking if a PowerShell profile exists..."
    if ((Test-Path -Path $PROFILE.CurrentUserAllHosts)) {
        Write-Host "PowerShell profile found" -ForegroundColor Green
    }
    else {
        Write-Host "`nPowerShell profile not found"
        Out-Null -inputObject (New-Item -ItemType "File" -Path $PROFILE.CurrentUserAllHosts -Force)
        Write-Host "New Powershell profile created" -ForegroundColor Green
    }
}

function Install-PythonDeps {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $ToolName
    )
    $PythonDepsFile = "requirements.txt", "Pipfile", "pyproject.toml"

    foreach ($FilePath in Get-ChildItem) {
        if ((Split-Path -Path $FilePath -Leaf -Resolve) -in $PythonDepsFile) {
            $PythonDepsFile = $filePath.Name
            break
        }
    }

    switch ($PythonDepsFile) {
        "requirements.txt" {
            try {
                Invoke-Expression "python -m pip install -r requirements.txt"
            }
            catch {
                Write-Host $PSItem.Exception.Message -ForegroundColor Red
            }
            break
        }
        "Pipfile" {            
            try {
                $Deps = Select-String -Raw -Path .\Pipfile -Pattern "([a-z0-9-]+\s=\s\`"[0-9\W]+\`")"

                $Deps = $Deps -replace "\`"$", "" -replace "\s=\s\`"\*", "" -replace "python_version\s=\s\`"[0-9\.\*]+", "" -replace "\s=\s\`"", "=="
        
                $Deps -replace "==~=", "~=" -replace "==>=", ">=" -replace "==<=", "<=" | Set-Content requirements.txt
            
                Invoke-Expression "python -m pip install -r requirements.txt"
            }
            catch {
                Write-Host $PSItem.Exception.Message -ForegroundColor Red
            }
            break
        }
        "pyproject.toml" {
            try {
                Invoke-Expression "poetry export -f requirements.txt --output requirements.txt --without-hashes"
                Invoke-Expression "python -m pip install -r requirements.txt"
            }
            catch {
                Write-Host "Python Poetry is required to convert pyproject.toml file to requirements.txt" -ForegroundColor Red
                Write-Host $PSItem.Exception.Message -ForegroundColor Red
            }
            break
        }
        default { Write-Host "No file specifying dependencies for $ToolName was found" -ForegroundColor Red }
    }
}

function Install-PythonTool {
    [CmdletBinding()]
    param(        
        [Parameter(Mandatory = $true)]
        [string]
        $ToolName,
    
        [Parameter(Mandatory = $true)]
        [string]
        $ToolDownload,
    
        [Parameter(Mandatory = $true)]
        [string]
        $ToolExec
    )

    function New-Venv {
        switch ($ToolDownload.Contains("git clone")) {
            $true {
                try {        
                    Invoke-Expression $ToolDownload
                    Set-Location .\$ToolName
                    Out-Null -inputObject (Invoke-Expression "python -m venv venv --upgrade-deps")
                    Invoke-Expression ".\venv\scripts\activate"
                    Install-PythonDeps -ToolName $ToolName
                    Invoke-Expression "deactivate"
                    Set-Location -
                    Write-Host "Installed $ToolName" -ForegroundColor Green
                }
                catch {
                    Write-Host $PSItem.Exception.Message -ForegroundColor Red
                }
            }
            $false {
                try {
                    Out-Null -inputObject (New-Item -Path ".\" -Name $ToolExec -ItemType "directory")
                    Set-Location .\$ToolExec
                    Out-Null -inputObject (Invoke-Expression "python -m venv venv --upgrade-deps")
                    Invoke-Expression ".\venv\scripts\activate"
                    Invoke-Expression $ToolDownload
                    Invoke-Expression "deactivate"
                    Set-Location -
                    Write-Host "Installed $ToolName" -ForegroundColor Green
                }
                catch {
                    Write-Host $PSItem.Exception.Message -ForegroundColor Red
                }
            }
        }
    }
    function Add-FunctionToPSProfile {
        if (Test-Path -Path .\$ToolName) {
            $RelativePath = $ToolName
        }
        else { $RelativePath = $ToolExec }
        
        $FunctionText = "`nfunction tool-$ToolName {
            Set-Location `"$PWD\$RelativePath`"
            Invoke-Expression `".\venv\scripts\activate`"
            Invoke-Expression `"$ToolExec `$args`"
            Invoke-Expression `"deactivate`"
            Set-Location `"-`"
        }"
        
        Add-Content -Path $PROFILE.CurrentUserAllHosts -Value $FunctionText
    }

    if ((Test-Path -Path .\$ToolName) -or (Test-Path -Path .\$ToolExec)) {
        $InputMessage = "A tool named $ToolName already exists`nWould you like to remove it and install the latest version?`nAnswer: [Y]es or [N]o"
        do {
            $UserInput = Read-Host -Prompt $InputMessage
            switch -Regex ($UserInput) {
                "^y$|^yes$" {
                    Write-Host "Updating $ToolName..." -ForegroundColor Green
                    Remove-Item .\$ToolName -Recurse -Force
                    New-Venv
                }
                "^n$|^no$" {
                    Write-Host "Skipping $ToolName" -ForegroundColor Green
                }
                default {
                    Write-Host "Invalid entry, try again" -ForegroundColor Red
                }
            }
        }
        until (($UserInput) -match "(^[yn]{1}$)|(^no$)|(^yes$)")
    }
    else {
        New-Venv
        Add-FunctionToPSProfile
    }
}

## ----------------------Main Script----------------------

Clear-Host
Write-Host "Welcome to the Python tools installer script" -ForegroundColor Green

do {
    Write-Host "Please choose an option:" -ForegroundColor Green
    Write-Host "1. Install tools`n2. List tools to install`n3. Add tool to install`n4. Remove tool from install list`n5. Clear install list`n6. Exit"
    $UserInput = Read-Host -Prompt "Enter selection"
    switch ($UserInput) {
        "1" {
            New-PSProfile
            if ($PythonTools.Count -gt 0) {
                foreach ($ToolName in $PythonTools.Keys) { 
                    Install-PythonTool -ToolName $ToolName -ToolDownload $PythonTools.$ToolName.Download -ToolExec $PythonTools.$ToolName.Exec
                }
            }
            else {
                Write-Host "Tools list is empty - there are no tools to install`n" -ForegroundColor Red
            }
        }
        "2" {
            if ($PythonTools.Count -gt 0) {
                Write-Host "`nThe following tools will be installed in the current directory:`n"
                foreach ($ToolName in $PythonTools.Keys) {
                    Write-Host $ToolName -ForegroundColor Green
                }
                Write-Host 
            }
            else {
                Write-Host "`nTools list is empty`n" -ForegroundColor Yellow
            }
        }
        "3" {
            $Name = Read-Host -Prompt "Enter tool name"
            $Download = Read-Host -Prompt "Enter tool download command"
            $Exec = Read-Host -Prompt "Enter tool execution command"
            $PythonTools[$Name] = @{Download = $Download; Exec = $Exec }
            Write-Host "`n$Name was added to install list`n" -ForegroundColor Green
        }
        "4" {
            $ToolToRemove = Read-Host -Prompt "Enter tool name to remove"
            if ($PythonTools.Contains($ToolToRemove)) {
                $PythonTools.Remove($ToolToRemove)
                Write-Host "`n$ToolToRemove was removed from install list`n" -ForegroundColor Green
            }
            else {
                Write-Host "`nError: no tool named $ToolToRemove was found in install list`n" -ForegroundColor Red
            }
        }
        "5" {
            $PythonTools.Clear()
            Write-Host "`nCleared tools install list" -ForegroundColor Green
        }
        "6" {
            Write-Host "`nExiting. Bye bye!`n" -ForegroundColor Green
        }
        default {
            Write-Host "`nInvalid entry, try again" -ForegroundColor Red
        }
    }
}
until ($UserInput -match "(^1$)|(^6$)")
