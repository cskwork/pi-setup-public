# Dot-source this file from a PowerShell profile, before Pi runs.
# It loads ~/.pi-setup.env and normalizes provider key aliases.
#
# Pi registers a provider only when that provider's documented environment
# variable is set. A model referenced in settings.json whose provider never
# registers makes every subagent launch print
#   [pi-subagents] Skipping fallback model '<id>' because it is unavailable...
# so the credential has to be present before Pi starts, on every machine.
#
# Already-set variables always win. The file supplies defaults only.

# Sentinel written by Set-PiSetupProviderPlaceholders. It is not a credential,
# so every step below must treat it as "no key" — otherwise re-sourcing this
# file in one session would let a stale placeholder outrank a real key added
# afterwards, because the loader lets an already-set variable win.
$script:PiSetupPlaceholderValue = "unset-placeholder"

function Clear-PiSetupPlaceholder {
    foreach ($variable in @("ZAI_API_KEY")) {
        if ([System.Environment]::GetEnvironmentVariable($variable) -eq $script:PiSetupPlaceholderValue) {
            Remove-Item -Path "Env:$variable" -ErrorAction SilentlyContinue
        }
    }
}

function Import-PiSetupEnvFile {
    $file = if ($env:PI_SETUP_ENV_FILE) { $env:PI_SETUP_ENV_FILE }
            else { Join-Path $HOME ".pi-setup.env" }
    if (-not (Test-Path -LiteralPath $file)) { return }

    foreach ($raw in [System.IO.File]::ReadAllLines($file)) {
        $line = $raw.TrimStart()
        if ($line -eq "" -or $line.StartsWith("#")) { continue }
        if ($line.StartsWith("export ")) { $line = $line.Substring(7) }

        $split = $line.IndexOf("=")
        if ($split -lt 1) { continue }

        $name = $line.Substring(0, $split)
        $value = $line.Substring($split + 1)
        if ($name -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') { continue }

        if (($value.StartsWith('"') -and $value.EndsWith('"') -and $value.Length -ge 2) -or
            ($value.StartsWith("'") -and $value.EndsWith("'") -and $value.Length -ge 2)) {
            $value = $value.Substring(1, $value.Length - 2)
        }

        # Already-set environment wins.
        if ([System.Environment]::GetEnvironmentVariable($name)) { continue }
        Set-Item -Path "Env:$name" -Value $value
    }
}

# Pi reads ZAI_API_KEY; the Z.ai Vision MCP server reads Z_AI_API_KEY.
# Mirror whichever one is set so both consumers work from a single secret.
function Set-PiSetupEnvAlias {
    if (-not $env:ZAI_API_KEY -and $env:Z_AI_API_KEY) {
        $env:ZAI_API_KEY = $env:Z_AI_API_KEY
    }
    if (-not $env:Z_AI_API_KEY -and $env:ZAI_API_KEY) {
        $env:Z_AI_API_KEY = $env:ZAI_API_KEY
    }
}

# Keep a provider quiet when the user has no key for it.
#
# pi-subagents warns once per launch for every model whose provider is not
# registered: "Skipping fallback model '<id>' because it is unavailable in this
# environment." That is noise when a provider is deliberately unused, and
# pi-subagents has no setting to mute it.
#
# Any non-empty value registers the provider, which stops the warning. The
# credential is then wrong, but that path is already silent: Pi tries the model,
# the call fails, and it moves to the next candidate in the fallback chain.
# A real key later simply overrides the placeholder and gets used normally.
#
# Set PI_SETUP_NO_PLACEHOLDER=1 to opt out and see the warnings instead.
function Set-PiSetupProviderPlaceholders {
    if ($env:PI_SETUP_NO_PLACEHOLDER) { return }
    foreach ($variable in @("ZAI_API_KEY")) {
        if (-not [System.Environment]::GetEnvironmentVariable($variable)) {
            Set-Item -Path "Env:$variable" -Value $script:PiSetupPlaceholderValue
        }
    }
}

Clear-PiSetupPlaceholder
Import-PiSetupEnvFile
Set-PiSetupEnvAlias
Set-PiSetupProviderPlaceholders
