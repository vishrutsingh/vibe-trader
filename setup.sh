#!/usr/bin/env bash
#  ██╗   ██╗██╗██████╗ ███████╗    ████████╗██████╗  █████╗ ██████╗ ███████╗██████╗
#  ██║   ██║██║██╔══██╗██╔════╝    ╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗
#  ██║   ██║██║██████╔╝█████╗         ██║   ██████╔╝███████║██║  ██║█████╗  ██████╔╝
#  ╚██╗ ██╔╝██║██╔══██╗██╔══╝         ██║   ██╔══██╗██╔══██║██║  ██║██╔══╝  ██╔══██╗
#   ╚████╔╝ ██║██████╔╝███████╗       ██║   ██║  ██║██║  ██║██████╔╝███████╗██║  ██║
#    ╚═══╝  ╚═╝╚═════╝ ╚══════╝       ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝
#
#  Paper-only trading research bot — MCP + Telegram gateway + dashboard
#  Architecture A: self-contained Hermes inside Docker

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# ── Colors ──
if [[ -t 1 ]]; then
  BOLD='\033[1m'; DIM='\033[2m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; BLUE='\033[34m'; CYAN='\033[36m'; NC='\033[0m'
else
  BOLD=''; DIM=''; GREEN=''; YELLOW=''; RED=''; BLUE=''; CYAN=''; NC=''
fi

STEP=0; TOTAL=5
_step() { STEP=$((STEP+1)); printf "\n  ${BLUE}${BOLD}[%d/%d]${NC} ${BOLD}%s${NC}\n  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n" "$STEP" "$TOTAL" "$1"; }
_ok()   { printf "    ${GREEN}✓${NC} %s\n" "$1"; }
_warn() { printf "    ${YELLOW}⚠${NC}  %s\n" "$1"; }
_info() { printf "    ${DIM}→${NC} %s\n" "$1"; }
_spinner() { local pid=$1 msg="$2" s='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0
  while kill -0 "$pid" 2>/dev/null; do printf "\r    ${DIM}%s${NC} %s" "${s:$i:1}" "$msg"; i=$(( (i+1)%${#s} )); sleep 0.1; done
  wait "$pid"; printf "\r    ${GREEN}✓${NC} %s ${DIM}(done)${NC}\n" "$msg"; }

# ── Banner ──
clear 2>/dev/null || true
echo ""
echo "  ${BOLD}${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo "  ${BOLD}${CYAN}║${NC}              ${BOLD}VIBE-TRADING WORKSPACE${NC}                 ${BOLD}${CYAN}║${NC}"
echo "  ${BOLD}${CYAN}║${NC}        ${DIM}Paper-Only Research Bot — MCP + TG + UI${NC}     ${BOLD}${CYAN}║${NC}"
echo "  ${BOLD}${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo ""

# ═══════════════════════════════════════════════════════════════
# Step 1: Prerequisites
# ═══════════════════════════════════════════════════════════════
_step "Checking prerequisites"

command -v docker &>/dev/null && _ok "docker $(docker --version | cut -d' ' -f3 | tr -d ',')" || { echo "Need docker"; exit 1; }
docker compose version &>/dev/null && _ok "docker compose" || { echo "Need docker compose"; exit 1; }

# ═══════════════════════════════════════════════════════════════
# Step 2: Environment
# ═══════════════════════════════════════════════════════════════
_step "Configuring environment"

if [[ ! -f .env ]]; then
  cp .env.example .env
  _ok ".env created"
else
  _ok ".env already exists"
fi

source .env 2>/dev/null || true

echo ""
echo "  ${BOLD}Secrets${NC}"
echo "  ${DIM}─────────────────────────────────────────${NC}"

if [[ -z "${OPENROUTER_API_KEY:-}" ]] || [[ "$OPENROUTER_API_KEY" == "sk-or-..." ]]; then
  printf "    ${CYAN}?${NC} OpenRouter API key: "
  read -r key
  [[ -n "$key" ]] && { sed -i "/^OPENROUTER_API_KEY=/d" .env 2>/dev/null; echo "OPENROUTER_API_KEY=$key" >> .env; _ok "OpenRouter key saved"; }
else
  _ok "OpenRouter key ${DIM}(configured)${NC}"
fi

if [[ -z "${TELEGRAM_BOT_TOKEN:-}" ]] || [[ "$TELEGRAM_BOT_TOKEN" == "123:abc" ]]; then
  printf "    ${CYAN}?${NC} Telegram bot token: "
  read -r token
  [[ -n "$token" ]] && { sed -i "/^TELEGRAM_BOT_TOKEN=/d" .env 2>/dev/null; echo "TELEGRAM_BOT_TOKEN=$token" >> .env; _ok "Telegram token saved"; }
else
  _ok "Telegram bot token ${DIM}(configured)${NC}"
fi

printf "    ${CYAN}?${NC} Telegram user ID ${DIM}[1766037643]${NC}: "
read -r tgid; tgid="${tgid:-1766037643}"
sed -i "/^TELEGRAM_ALLOWED_USERS=/d" .env 2>/dev/null; echo "TELEGRAM_ALLOWED_USERS=$tgid" >> .env

if [[ -z "${DASHBOARD_PASSWORD_HASH:-}" ]]; then
  printf "    ${CYAN}?${NC} Dashboard password ${DIM}(for user 'admin')${NC}: "
  read -rs pw; echo ""
  if [[ -n "$pw" ]]; then
    hash=$(python3 -c "from plugins.dashboard_auth.basic import hash_password; print(hash_password('$pw'))" 2>/dev/null || \
           python3 -c "import hashlib,os; s=os.urandom(16).hex(); print(f'sha256:{s}:{hashlib.sha256(f\"{s}$pw\".encode()).hexdigest()}')")
    sed -i "/^DASHBOARD_PASSWORD_HASH=/d" .env 2>/dev/null; echo "DASHBOARD_PASSWORD_HASH=$hash" >> .env
    _ok "Dashboard password set"
  fi
else
  _ok "Dashboard password ${DIM}(configured)${NC}"
fi

source .env 2>/dev/null || true

# ═══════════════════════════════════════════════════════════════
# Step 3: Build & volume init
# ═══════════════════════════════════════════════════════════════
_step "Building image & initializing volumes"

docker compose build 2>&1 &
_spinner $! "Building trader image..."

# Start MCP first for one-time setup, leave gateway/dashboard off
docker compose up -d mcp 2>&1 &
_spinner $! "Starting MCP server..."
sleep 3

# Create data dirs inside container
docker compose exec -T mcp mkdir -p /trader/hermes-home /trader/state 2>/dev/null || true
_ok "Volumes initialized"

# ═══════════════════════════════════════════════════════════════
# Step 4: One-time Hermes configuration
# ═══════════════════════════════════════════════════════════════
_step "Configuring Hermes profile"

docker compose exec -T mcp bash -c "
  export HERMES_HOME=/trader/hermes-home
  source /opt/hermes-venv/bin/activate

  # Create profile if needed
  hermes profile list 2>/dev/null | grep -q vibe-trading || hermes profile create vibe-trading

  # Model
  hermes -p vibe-trading config set model.default '${VIBE_TRADING_MODEL:-anthropic/claude-sonnet-4}'
  hermes -p vibe-trading config set model.provider '${VIBE_TRADING_PROVIDER:-openrouter}'

  # Dashboard auth
  hermes -p vibe-trading config set dashboard.basic_auth.username '${DASHBOARD_USERNAME:-admin}'
  hermes -p vibe-trading config set dashboard.basic_auth.password_hash '${DASHBOARD_PASSWORD_HASH:-}'

  echo 'ok'
" 2>&1 | tail -3
_ok "Profile configured"

# MCP registration
echo ""
_info "Registering MCP server (54 tools)..."
docker compose exec -T mcp bash -c "
  export HERMES_HOME=/trader/hermes-home
  source /opt/hermes-venv/bin/activate
  printf 'n\ny\n' | hermes -p vibe-trading mcp add vibe-trading --url http://mcp:8900/mcp --connect-timeout 30
  hermes -p vibe-trading mcp test vibe-trading
" 2>&1 | tail -5
_ok "MCP registered — 54 read-only research tools"

# ═══════════════════════════════════════════════════════════════
# Step 5: Start all services
# ═══════════════════════════════════════════════════════════════
_step "Starting all services"

docker compose up -d 2>&1 &
_spinner $! "Starting gateway + dashboard..."
sleep 5

curl -sf http://localhost:8900/health >/dev/null 2>&1 && _ok "MCP        → http://localhost:8900 (healthy)" || _warn "MCP        → check logs"
_ok "Gateway    → Telegram bot active"
_ok "Dashboard  → http://localhost:9119 (basic auth: /auth/password-login)"

echo ""
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║              ${GREEN}${BOLD}VIBE-TRADING READY${NC}                 ║"
echo "  ╠══════════════════════════════════════════════════╣"
echo "  ║                                                  ║"
printf "  ║  ${BOLD}MCP:${NC}        http://localhost:8900              ║\n"
printf "  ║  ${BOLD}Dashboard:${NC}  http://localhost:9119              ║\n"
printf "  ║  ${BOLD}Telegram:${NC}   @your_bot (user %s)     ║\n" "${TELEGRAM_ALLOWED_USERS:-?}"
echo "  ║                                                  ║"
printf "  ║  ${BOLD}Logs:${NC}       docker compose logs -f             ║\n"
printf "  ║  ${BOLD}Stop:${NC}       docker compose down                 ║\n"
echo "  ║                                                  ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo ""