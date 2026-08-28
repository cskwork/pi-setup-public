$ErrorActionPreference = "Stop"
if (Get-Variable PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}

$Repo = Split-Path -Parent $PSScriptRoot
$Temp = Join-Path ([System.IO.Path]::GetTempPath()) ("pi-node-heap-" + [guid]::NewGuid())
$OriginalPath = $env:Path
$OriginalNodeOptionsPresent = Test-Path Env:NODE_OPTIONS
$OriginalNodeOptions = $env:NODE_OPTIONS
$ProfilePath = $PROFILE.CurrentUserAllHosts
$ProfileExisted = Test-Path -LiteralPath $ProfilePath
$ProfileBytes = if ($ProfileExisted) { [System.IO.File]::ReadAllBytes($ProfilePath) } else { $null }

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
}

function Assert-Contains {
    param([string]$Actual, [string]$Expected)
    Assert-True ($Actual.Contains($Expected)) "expected '$Expected' in '$Actual'"
}

function New-FakePi {
    param([string]$Directory, [string]$Label)
    New-Item -ItemType Directory -Path $Directory -Force | Out-Null
    @"
@echo off
echo label=$Label
echo node_options=%NODE_OPTIONS%
echo args=%*
if defined PI_FAKE_EXIT exit /b %PI_FAKE_EXIT%
exit /b 0
"@ | Set-Content -LiteralPath (Join-Path $Directory "pi.cmd") -Encoding Ascii
}

try {
    New-Item -ItemType Directory -Path $Temp -Force | Out-Null
    $A = Join-Path $Temp "a"
    $B = Join-Path $Temp "b"
    New-FakePi $A "A"
    New-FakePi $B "B"

    . (Join-Path $Repo "scripts\pi-node-heap.ps1")
    $env:NODE_OPTIONS = "--trace-warnings"
    $env:Path = "$A$([System.IO.Path]::PathSeparator)$OriginalPath"
    $output = (pi "two words" "--flag") -join "`n"
    Assert-Contains $output "label=A"
    Assert-Contains $output "node_options=--trace-warnings --max-old-space-size=8192"
    Assert-Contains $output 'args="two words" --flag'
    Assert-True ($env:NODE_OPTIONS -eq "--trace-warnings") "parent NODE_OPTIONS changed"

    $env:Path = "$B$([System.IO.Path]::PathSeparator)$OriginalPath"
    $output = (pi "switch") -join "`n"
    Assert-Contains $output "label=B"

    $env:PI_FAKE_EXIT = "37"
    $null = pi "failure"
    Assert-True ($global:LASTEXITCODE -eq 37) "Pi exit code was not preserved"
    Remove-Item Env:PI_FAKE_EXIT

    $NodeProbe = Join-Path $Temp "node-probe"
    New-Item -ItemType Directory -Path $NodeProbe -Force | Out-Null
    '@node -e "const v8=require(''v8'');console.log(Math.round(v8.getHeapStatistics().heap_size_limit/1048576))"' |
        Set-Content -LiteralPath (Join-Path $NodeProbe "pi.cmd") -Encoding Ascii
    $env:Path = "$NodeProbe$([System.IO.Path]::PathSeparator)$OriginalPath"
    $env:NODE_OPTIONS = "--max-old-space-size=128"
    $heapLimit = [int]((pi) -join "")
    Assert-True ($heapLimit -ge 8000) "Pi heap limit stayed below 8 GiB: $heapLimit MiB"
    Assert-True ($env:NODE_OPTIONS -eq "--max-old-space-size=128") "parent heap option changed"

    $FakeTools = Join-Path $Temp "tools"
    New-FakePi $FakeTools "INSTALL"
    @'
@echo off
if "%1"=="--version" echo test
exit /b 0
'@ | Set-Content -LiteralPath (Join-Path $FakeTools "agent-browser.cmd") -Encoding Ascii
    '@exit /b 0' | Set-Content -LiteralPath (Join-Path $FakeTools "superqa.cmd") -Encoding Ascii
    '@exit /b 0' | Set-Content -LiteralPath (Join-Path $FakeTools "npm.cmd") -Encoding Ascii

    $Log = Join-Path $Temp "pi.log"
    @"
@echo off
>>"$Log" echo %NODE_OPTIONS%^|%*
exit /b 0
"@ | Set-Content -LiteralPath (Join-Path $FakeTools "pi.cmd") -Encoding Ascii

    $env:PI_DIR = Join-Path $Temp "agent"
    $env:Path = "$FakeTools$([System.IO.Path]::PathSeparator)$OriginalPath"
    $env:NODE_OPTIONS = "--trace-warnings"

    $profileDirectory = Split-Path -Parent $ProfilePath
    New-Item -ItemType Directory -Path $profileDirectory -Force | Out-Null
    $utf8Bom = New-Object System.Text.UTF8Encoding -ArgumentList $true
    $malformed = "# <<< pi-setup Pi-only Node heap <<<`r`n# >>> pi-setup Pi-only Node heap >>>`r`n"
    [System.IO.File]::WriteAllText($ProfilePath, $malformed, $utf8Bom)
    $malformedBefore = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($ProfilePath))
    $rejected = $false
    try {
        & (Join-Path $Repo "install.ps1") *> $null
    }
    catch {
        $rejected = $true
    }
    Assert-True $rejected "installer accepted reversed managed-block markers"
    $malformedAfter = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($ProfilePath))
    Assert-True ($malformedAfter -eq $malformedBefore) "installer changed a malformed profile"

    if ($ProfileExisted) {
        [System.IO.File]::WriteAllBytes($ProfilePath, $ProfileBytes)
    }
    else {
        Remove-Item -LiteralPath $ProfilePath -Force
    }

    & (Join-Path $Repo "install.ps1") *> $null
    & (Join-Path $Repo "install.ps1") *> $null

    $profileBytesAfterInstall = [System.IO.File]::ReadAllBytes($ProfilePath)
    Assert-True ($profileBytesAfterInstall.Length -ge 3 -and
        $profileBytesAfterInstall[0] -eq 0xEF -and
        $profileBytesAfterInstall[1] -eq 0xBB -and
        $profileBytesAfterInstall[2] -eq 0xBF) "PowerShell profile is missing a UTF-8 BOM"

    $profileText = [System.IO.File]::ReadAllText($ProfilePath)
    Assert-True (([regex]::Matches($profileText, "(?m)^# >>> pi-setup Pi-only Node heap >>>\r?$")).Count -eq 1) `
        "PowerShell profile contains duplicate start markers"
    Assert-True (([regex]::Matches($profileText, "(?m)^# <<< pi-setup Pi-only Node heap <<<\r?$")).Count -eq 1) `
        "PowerShell profile contains duplicate end markers"
    Assert-Contains $profileText (Join-Path $Repo "scripts\pi-node-heap.ps1")
    Assert-Contains ([System.IO.File]::ReadAllText($Log)) "--max-old-space-size=8192"

    $powerShellPath = (Get-Process -Id $PID).Path
    $freshOutput = (& $powerShellPath -NoLogo -NonInteractive -Command `
        '$command = Get-Command pi -CommandType Function -ErrorAction Stop; $command.Name') -join "`n"
    Assert-True ($LASTEXITCODE -eq 0) "fresh PowerShell could not load the managed profile"
    Assert-Contains $freshOutput "pi"

    [scriptblock]::Create([System.IO.File]::ReadAllText((Join-Path $Repo "install.ps1"))) | Out-Null
    Write-Host "PASS: Pi-only PowerShell heap wrapper and installer profile block"
}
finally {
    $env:Path = $OriginalPath
    if ($OriginalNodeOptionsPresent) {
        $env:NODE_OPTIONS = $OriginalNodeOptions
    }
    else {
        Remove-Item Env:NODE_OPTIONS -ErrorAction SilentlyContinue
    }
    Remove-Item Env:PI_DIR -ErrorAction SilentlyContinue
    Remove-Item Env:PI_FAKE_EXIT -ErrorAction SilentlyContinue

    if ($ProfileExisted) {
        [System.IO.File]::WriteAllBytes($ProfilePath, $ProfileBytes)
    }
    else {
        Remove-Item -LiteralPath $ProfilePath -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -LiteralPath $Temp -Recurse -Force -ErrorAction SilentlyContinue
}
