#!/usr/bin/env bash
# Source this file from an interactive bash or zsh profile.
# It raises only Pi's V8 heap and resolves the active NVM/npm Pi on every call.

pi() {
  NODE_OPTIONS="${NODE_OPTIONS:+$NODE_OPTIONS }--max-old-space-size=8192" command pi "$@"
}
