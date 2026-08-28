# Dot-source this file from a PowerShell profile.
# It raises only Pi's V8 heap and resolves the active npm/NVM Pi on every call.

function global:pi {
    $piApplication = Get-Command pi -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if (-not $piApplication) {
        Write-Error "Pi executable not found on PATH. Install Pi, then reopen PowerShell." -ErrorAction Continue
        $global:LASTEXITCODE = 127
        return
    }

    # PowerShell 7 can turn a native nonzero exit into a terminating error.
    # Keep Pi's normal exit-code behavior inside this function's local scope.
    if (Get-Variable PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
        $PSNativeCommandUseErrorActionPreference = $false
    }

    $piPath = $piApplication.Source
    $hadNodeOptions = Test-Path Env:NODE_OPTIONS
    $previousNodeOptions = $env:NODE_OPTIONS
    $exitCode = 0

    try {
        if ([string]::IsNullOrWhiteSpace($previousNodeOptions)) {
            $env:NODE_OPTIONS = "--max-old-space-size=8192"
        }
        else {
            $env:NODE_OPTIONS = "$previousNodeOptions --max-old-space-size=8192"
        }

        & $piPath @args
        $exitCode = $LASTEXITCODE
    }
    finally {
        if ($hadNodeOptions) {
            $env:NODE_OPTIONS = $previousNodeOptions
        }
        else {
            Remove-Item Env:NODE_OPTIONS -ErrorAction SilentlyContinue
        }
    }

    $global:LASTEXITCODE = $exitCode
}
