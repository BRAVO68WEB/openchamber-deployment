#!/usr/bin/env bash
set -eu

HOME="/home/openchamber"
export HOME

# ── Source nvm so node/npm are on PATH ──
export NVM_DIR="${HOME}/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    source "$NVM_DIR/nvm.sh"
fi

OPENCODE_CONFIG_DIR="${OPENCODE_CONFIG_DIR:-${HOME}/.config/opencode}"
export OPENCODE_CONFIG_DIR

# ── Fix ownership of shared volumes (opencode runs as root) ──
sudo chown -R openchamber:openchamber "${HOME}/.local/share/opencode" 2>/dev/null || true
sudo chown -R openchamber:openchamber "${HOME}/.config/opencode" 2>/dev/null || true

# ── SSH key generation ──
SSH_DIR="${HOME}/.ssh"
SSH_PRIVATE_KEY_PATH="${SSH_DIR}/id_ed25519"
SSH_PUBLIC_KEY_PATH="${SSH_PRIVATE_KEY_PATH}.pub"

mkdir -p "${SSH_DIR}"
chmod 700 "${SSH_DIR}" 2>/dev/null || true

if [ ! -f "${SSH_PRIVATE_KEY_PATH}" ] || [ ! -f "${SSH_PUBLIC_KEY_PATH}" ]; then
    if [ -w "${SSH_DIR}" ]; then
        echo "[entrypoint] Generating SSH key..."
        ssh-keygen -t ed25519 -N "" -f "${SSH_PRIVATE_KEY_PATH}" >/dev/null 2>&1 || \
            echo "[entrypoint] Warning: failed to generate SSH key" >&2
    fi
fi

chmod 600 "${SSH_PRIVATE_KEY_PATH}" 2>/dev/null || true
chmod 644 "${SSH_PUBLIC_KEY_PATH}" 2>/dev/null || true

if [ -f "${SSH_PUBLIC_KEY_PATH}" ]; then
    echo "[entrypoint] SSH public key:"
    cat "${SSH_PUBLIC_KEY_PATH}"
fi

# ── oh-my-openagent install on first boot ──
MARKER="${HOME}/.local/.oh-my-openagent-installed"
if [ ! -f "$MARKER" ]; then
    echo "[entrypoint] Installing oh-my-openagent..."
    if command -v bunx >/dev/null 2>&1; then
        bunx oh-my-openagent install --no-tui --claude=no --gemini=no --copilot=no --skip-auth 2>&1 || true
    elif command -v npx >/dev/null 2>&1; then
        npx oh-my-openagent install --no-tui --claude=no --gemini=no --copilot=no --skip-auth 2>&1 || true
    else
        echo "[entrypoint] Warning: neither bunx nor npx found, skipping oh-my-openagent" >&2
    fi
    mkdir -p "$(dirname "$MARKER")" && touch "$MARKER"
    echo "[entrypoint] oh-my-openagent setup complete."
else
    echo "[entrypoint] oh-my-openagent already installed. Skipping."
fi

# ── UI password handling ──
if [ -z "${OPENCHAMBER_UI_PASSWORD:-}" ] && [ -n "${UI_PASSWORD:-}" ]; then
    OPENCHAMBER_UI_PASSWORD="$UI_PASSWORD"
    export OPENCHAMBER_UI_PASSWORD
fi

if [ -n "${OPENCHAMBER_UI_PASSWORD:-}" ]; then
    echo "[entrypoint] UI password set, enabling authentication"
fi

# ── Set publicOrigin for reverse proxy origin validation ──
if [ -n "${OPENCHAMBER_PUBLIC_ORIGIN:-}" ]; then
    SETTINGS_FILE="${HOME}/.config/openchamber/settings.json"
    mkdir -p "$(dirname "$SETTINGS_FILE")"
    if [ -f "$SETTINGS_FILE" ]; then
        # Merge publicOrigin into existing settings
        python3 -c "
import json, sys
with open('$SETTINGS_FILE') as f:
    s = json.load(f) if f.read().strip() else {}
s['publicOrigin'] = '$OPENCHAMBER_PUBLIC_ORIGIN'
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(s, f, indent=2)
" 2>/dev/null || echo '{"publicOrigin":"'"$OPENCHAMBER_PUBLIC_ORIGIN"'"}' > "$SETTINGS_FILE"
    else
        echo '{"publicOrigin":"'"$OPENCHAMBER_PUBLIC_ORIGIN"'"}' > "$SETTINGS_FILE"
    fi
    echo "[entrypoint] publicOrigin set to $OPENCHAMBER_PUBLIC_ORIGIN"
fi

# ── Start OpenChamber ──
OPENCHAMBER_HOST="${OPENCHAMBER_HOST:-0.0.0.0}"
export OPENCHAMBER_HOST

echo "[entrypoint] Starting OpenChamber..."

if [ -n "${OPENCHAMBER_UI_PASSWORD:-}" ]; then
    exec openchamber serve --foreground --ui-password "$OPENCHAMBER_UI_PASSWORD"
else
    exec openchamber serve --foreground
fi
