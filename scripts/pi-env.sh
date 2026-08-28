#!/usr/bin/env bash
# Source this file from an interactive bash or zsh profile, before Pi runs.
# It loads ~/.pi-setup.env and normalizes provider key aliases.
#
# Pi registers a provider only when that provider's documented environment
# variable is set. A model referenced in settings.json whose provider never
# registers makes every subagent launch print
#   [pi-subagents] Skipping fallback model '<id>' because it is unavailable...
# so the credential has to be present before Pi starts, on every machine.
#
# Already-exported variables always win. The file supplies defaults only, so a
# one-off `ZAI_API_KEY=... pi ...` override and CI secrets both survive.

# Sentinel written by pi_setup_quiet_unused_providers. It is not a credential,
# so every step below must treat it as "no key" — otherwise re-sourcing this
# file in one shell would let a stale placeholder outrank a real key added
# afterwards, because the loader lets an already-set variable win.
PI_SETUP_PLACEHOLDER_VALUE="unset-placeholder"

pi_setup_clear_placeholders() {
  local var
  for var in ZAI_API_KEY; do
    if [ "$(eval "printf '%s' \"\${$var-}\"")" = "$PI_SETUP_PLACEHOLDER_VALUE" ]; then
      unset "$var"
    fi
  done
}

pi_setup_load_env_file() {
  local file="${PI_SETUP_ENV_FILE:-$HOME/.pi-setup.env}"
  [ -r "$file" ] || return 0

  local line name value
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line#"${line%%[![:space:]]*}"}"          # strip leading blanks
    case "$line" in ''|'#'*) continue ;; esac
    line="${line#export }"
    case "$line" in *=*) ;; *) continue ;; esac

    name="${line%%=*}"
    value="${line#*=}"
    case "$name" in ''|*[!A-Za-z0-9_]*) continue ;; esac

    # Strip one matching pair of surrounding quotes.
    case "$value" in
      \"*\") value="${value#\"}"; value="${value%\"}" ;;
      \'*\') value="${value#\'}"; value="${value%\'}" ;;
    esac

    # Exported env wins. Read the named variable without bash-only ${!name},
    # which zsh rejects outright — this file is sourced by both shells.
    if [ -n "$(eval "printf '%s' \"\${$name-}\"")" ]; then
      continue
    fi
    export "$name=$value"
  done < "$file"
}

# Pi reads ZAI_API_KEY; the Z.ai Vision MCP server reads Z_AI_API_KEY.
# Mirror whichever one is set so both consumers work from a single secret.
pi_setup_alias_env() {
  if [ -z "${ZAI_API_KEY-}" ] && [ -n "${Z_AI_API_KEY-}" ]; then
    export ZAI_API_KEY="$Z_AI_API_KEY"
  fi
  if [ -z "${Z_AI_API_KEY-}" ] && [ -n "${ZAI_API_KEY-}" ]; then
    export Z_AI_API_KEY="$ZAI_API_KEY"
  fi
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
# Only providers actually routed in settings.json need this. Set
# PI_SETUP_NO_PLACEHOLDER=1 to opt out and see the warnings instead.
pi_setup_quiet_unused_providers() {
  [ -n "${PI_SETUP_NO_PLACEHOLDER-}" ] && return 0
  local var
  for var in ZAI_API_KEY; do
    if [ -z "$(eval "printf '%s' \"\${$var-}\"")" ]; then
      export "$var=$PI_SETUP_PLACEHOLDER_VALUE"
    fi
  done
}

pi_setup_clear_placeholders
pi_setup_load_env_file
pi_setup_alias_env
pi_setup_quiet_unused_providers
