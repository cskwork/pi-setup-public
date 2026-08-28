# Restore this Pi setup from native Windows PowerShell 5.1 or PowerShell 7.
# Links ~/.pi/agent items to this repo, then installs Pi packages.
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$Repo = Split-Path -Parent $MyInvocation.MyCommand.Path
$PiDir = if ($env:PI_DIR) { $env:PI_DIR } else { Join-Path $HOME ".pi\agent" }
$Backup = "$PiDir.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"

function Install-Link {
    param(
        [Parameter(Mandatory = $true)][string]$RepoItem,
        [Parameter(Mandatory = $true)][string]$DestinationName
    )

    $source = Join-Path $Repo $RepoItem
    $destination = Join-Path $PiDir $DestinationName
    New-Item -ItemType Directory -Path $PiDir -Force | Out-Null

    $existing = Get-Item -LiteralPath $destination -Force -ErrorAction SilentlyContinue
    if ($existing -and $existing.PSObject.Properties.Name -contains "LinkType" -and
        $existing.LinkType -eq "SymbolicLink") {
        $target = [string]$existing.Target
        if (-not [System.IO.Path]::IsPathRooted($target)) {
            $target = Join-Path (Split-Path -Parent $destination) $target
        }
        if ([System.IO.Path]::GetFullPath($target) -eq [System.IO.Path]::GetFullPath($source)) {
            Write-Host "  OK $DestinationName (already linked)"
            return
        }
    }

    if ($existing) {
        New-Item -ItemType Directory -Path $Backup -Force | Out-Null
        Move-Item -LiteralPath $destination -Destination $Backup
        Write-Host "  BACKUP existing $DestinationName to $Backup"
    }

    try {
        New-Item -ItemType SymbolicLink -Path $destination -Target $source -ErrorAction Stop | Out-Null
        Write-Host "  LINK $DestinationName -> $source"
    }
    catch {
        Copy-Item -LiteralPath $source -Destination $destination -Recurse -Force
        Write-Host "  COPY $DestinationName (enable Windows Developer Mode for live links)"
    }
}

function Set-ManagedProfileBlock {
    param(
        [Parameter(Mandatory = $true)][string]$ProfilePath,
        [Parameter(Mandatory = $true)][string]$WrapperPath,
        [Parameter(Mandatory = $true)][string]$StartMarker,
        [Parameter(Mandatory = $true)][string]$EndMarker
    )

    $start = $StartMarker
    $end = $EndMarker
    $quotedWrapper = $WrapperPath.Replace("'", "''")
    $block = "$start`r`n. '$quotedWrapper'`r`n$end"
    $content = if (Test-Path -LiteralPath $ProfilePath) {
        # Match each host's native decoding: ANSI on Windows PowerShell 5.1,
        # UTF-8 on PowerShell 7. The rewritten profile gets a UTF-8 BOM so both
        # hosts preserve non-ASCII content on future launches.
        [string](Get-Content -LiteralPath $ProfilePath -Raw)
    }
    else {
        ""
    }

    $startCount = ([regex]::Matches($content, [regex]::Escape($start))).Count
    $endCount = ([regex]::Matches($content, [regex]::Escape($end))).Count
    if ($startCount -ne $endCount -or $startCount -gt 1) {
        throw "Refusing to edit malformed managed block in $ProfilePath"
    }

    if ($startCount -eq 1) {
        $startIndex = $content.IndexOf($start, [System.StringComparison]::Ordinal)
        $endIndex = $content.IndexOf($end, $startIndex, [System.StringComparison]::Ordinal)
        if ($endIndex -lt $startIndex) {
            throw "Refusing to edit reversed managed block in $ProfilePath"
        }
        $afterIndex = $endIndex + $end.Length
        $before = $content.Substring(0, $startIndex).TrimEnd("`r", "`n")
        $after = $content.Substring($afterIndex).TrimStart("`r", "`n")
        $parts = @($before, $block, $after) | Where-Object { $_ }
        $updated = ($parts -join "`r`n`r`n") + "`r`n"
    }
    else {
        $updated = $content.TrimEnd("`r", "`n")
        if ($updated) {
            $updated += "`r`n`r`n"
        }
        $updated += $block + "`r`n"
    }

    if ($updated -eq $content) {
        Write-Host "  OK $ProfilePath (unchanged)"
        return
    }

    $profileDirectory = Split-Path -Parent $ProfilePath
    New-Item -ItemType Directory -Path $profileDirectory -Force | Out-Null
    $temp = "$ProfilePath.pi-setup.tmp"
    $utf8WithBom = New-Object System.Text.UTF8Encoding -ArgumentList $true
    [System.IO.File]::WriteAllText($temp, $updated, $utf8WithBom)
    Move-Item -LiteralPath $temp -Destination $ProfilePath -Force
    Write-Host "  OK $ProfilePath (updated)"
}

Write-Host "==> Linking Pi setup into $PiDir"
Install-Link "AGENTS.md" "AGENTS.md"
Install-Link "settings.json" "settings.json"
Install-Link "models.json" "models.json"
Install-Link "extensions" "extensions"
Install-Link "agents" "agents"
Install-Link "skills" "skills"
Install-Link "profiles" "profiles"

$permissionDirectory = Join-Path $Repo "extensions\pi-permission-system"
New-Item -ItemType Directory -Path $permissionDirectory -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $Repo "configs\permissions.json") `
    -Destination (Join-Path $permissionDirectory "config.json") -Force

Write-Host "==> Creating machine-local secret file"
$envFile = if ($env:PI_SETUP_ENV_FILE) { $env:PI_SETUP_ENV_FILE }
           else { Join-Path $HOME ".pi-setup.env" }
if (Test-Path -LiteralPath $envFile) {
    Write-Host "  OK $envFile (already present, left untouched)"
}
else {
    Copy-Item -LiteralPath (Join-Path $Repo ".env.example") -Destination $envFile
    Write-Host "  NEW $envFile created from .env.example - add your provider keys"
}

Write-Host "==> Installing shell profile wrappers"
$wrapper = Join-Path $Repo "scripts\pi-node-heap.ps1"
Set-ManagedProfileBlock -ProfilePath $PROFILE.CurrentUserAllHosts -WrapperPath $wrapper `
    -StartMarker "# >>> pi-setup Pi-only Node heap >>>" `
    -EndMarker "# <<< pi-setup Pi-only Node heap <<<"
$envWrapper = Join-Path $Repo "scripts\pi-env.ps1"
Set-ManagedProfileBlock -ProfilePath $PROFILE.CurrentUserAllHosts -WrapperPath $envWrapper `
    -StartMarker "# >>> pi-setup provider env >>>" `
    -EndMarker "# <<< pi-setup provider env <<<"
. $wrapper
. $envWrapper

Write-Host "==> Checking provider credentials"
# provider id -> environment variable documented in Pi's docs/providers.md
$envByProvider = @{
    "zai"           = "ZAI_API_KEY"
    "zai-coding-cn" = "ZAI_CODING_CN_API_KEY"
    "google"        = "GEMINI_API_KEY"
    "openai"        = "OPENAI_API_KEY"
    "xai"           = "XAI_API_KEY"
    "openrouter"    = "OPENROUTER_API_KEY"
    "deepseek"      = "DEEPSEEK_API_KEY"
    "groq"          = "GROQ_API_KEY"
    "mistral"       = "MISTRAL_API_KEY"
    "kimi-coding"   = "KIMI_API_KEY"
}
# These authenticate through `pi auth` (auth.json), not an env var.
$oauthProviders = @("anthropic", "openai-codex", "amazon-bedrock")
$settingsJson = Get-Content -LiteralPath (Join-Path $Repo "settings.json") -Raw | ConvertFrom-Json
$referenced = New-Object System.Collections.Generic.HashSet[string]
foreach ($override in $settingsJson.subagents.agentOverrides.PSObject.Properties.Value) {
    $models = @($override.model) + @($override.fallbackModels)
    foreach ($model in $models) {
        if ($model -is [string] -and $model.Contains("/")) {
            [void]$referenced.Add($model.Split("/")[0])
        }
    }
}
# scripts/pi-env.ps1 sets this for providers with no key. It silences the
# per-launch warning but is not a credential, so report it as missing.
$placeholder = "unset-placeholder"
$clean = $true
foreach ($provider in ($referenced | Sort-Object)) {
    if ($oauthProviders -contains $provider) { continue }
    if (-not $envByProvider.ContainsKey($provider)) {
        Write-Warning "provider '$provider' is routed in settings.json but this installer does not know its credential variable - verify manually."
        $clean = $false
        continue
    }
    $variable = $envByProvider[$provider]
    $value = [System.Environment]::GetEnvironmentVariable($variable)
    if (-not $value -or $value -eq $placeholder) {
        Write-Host "  INFO provider '$provider' is routed in settings.json but $variable is unset."
        Write-Host "    That is fine: those roles fall through to the next model in their fallback chain,"
        Write-Host "    and the startup warning stays suppressed."
        Write-Host "    To actually use it, add $variable to $envFile."
        $clean = $false
    }
}
if ($clean) {
    Write-Host "  OK every provider routed in settings.json has a credential"
}

Write-Host "==> Installing Pi packages (list comes from settings.json)"
$settings = Get-Content -LiteralPath (Join-Path $Repo "settings.json") -Raw | ConvertFrom-Json
foreach ($package in $settings.packages) {
    if (-not $package.StartsWith("npm:")) {
        Write-Host "  SKIP non-npm entry: $package"
        continue
    }

    pi install $package *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK $package"
    }
    else {
        Write-Warning "failed: $package - run: pi install $package"
    }
}

Write-Host "==> External CLI dependencies"
if (Get-Command agent-browser -CommandType Application -ErrorAction SilentlyContinue) {
    $agentBrowserVersion = (& agent-browser --version 2>$null | Select-Object -First 1)
    Write-Host "  OK agent-browser ($agentBrowserVersion)"
}
elseif (Get-Command npm -CommandType Application -ErrorAction SilentlyContinue) {
    & npm install -g agent-browser *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK agent-browser (installed globally via npm)"
    }
    else {
        Write-Warning "agent-browser CLI missing - run: npm install -g agent-browser"
    }
}
else {
    Write-Warning "agent-browser CLI missing and npm is not on PATH"
}

if (-not (Get-Command superqa -CommandType Application -ErrorAction SilentlyContinue)) {
    Write-Warning "superqa not on PATH - browser-qa scenario replay is unavailable"
    Write-Host "    Install: https://github.com/cskwork/browser-qa"
}

Write-Host ""
Write-Host "Done. Next steps:"
Write-Host "  1. pi auth        # OAuth providers (anthropic, openai-codex, amazon-bedrock)"
Write-Host "  2. add API-key providers to $envFile  # e.g. ZAI_API_KEY=..."
Write-Host "  3. reopen PowerShell, then restart Pi"
Write-Host "     If profiles are blocked: Set-ExecutionPolicy -Scope CurrentUser RemoteSigned"
Write-Host "  4. optional: verify browser tooling - npx pi-agent-browser-doctor"
