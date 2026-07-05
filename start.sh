#!/bin/bash
# ─────────────────────────────────────────────────────────
#  IPMAC Lab 04 — SQL Injection Challenge
#  Startup script
# ─────────────────────────────────────────────────────────

set -e
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BOLD}${CYAN}"
echo "  ██╗██████╗ ███╗   ███╗ █████╗  ██████╗"
echo "  ██║██╔══██╗████╗ ████║██╔══██╗██╔════╝"
echo "  ██║██████╔╝██╔████╔██║███████║██║"
echo "  ██║██╔═══╝ ██║╚██╔╝██║██╔══██║██║"
echo "  ██║██║     ██║ ╚═╝ ██║██║  ██║╚██████╗"
echo "  ╚═╝╚═╝     ╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝"
echo -e "${NC}"
echo -e "${BOLD}  Lab 04 — SQL Injection Challenge${NC}"
echo ""

# Check Docker
if ! command -v docker &>/dev/null; then
    echo -e "${RED}❌ Docker not found. Please install Docker first.${NC}"
    exit 1
fi

if ! command -v docker-compose &>/dev/null && ! docker compose version &>/dev/null 2>&1; then
    echo -e "${RED}❌ Docker Compose not found.${NC}"
    exit 1
fi

COMPOSE="docker compose"
command -v docker-compose &>/dev/null && COMPOSE="docker-compose"

echo -e "${YELLOW}▶ Starting lab containers...${NC}"
$COMPOSE up -d --build

echo ""
echo -e "${YELLOW}▶ Waiting for WordPress to initialize (this may take 2-3 minutes)...${NC}"

# Wait for setup flag
TIMEOUT=180
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    if $COMPOSE exec -T wordpress test -f /var/www/html/.ipmac_setup_done 2>/dev/null; then
        break
    fi
    printf "."
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done
echo ""

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo -e "${YELLOW}⚠ Setup may still be running. Check logs: docker compose logs wordpress${NC}"
fi

# Get host IP
HOST_IP=$(docker inspect lab04_landing --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null || echo "127.0.0.1")
REAL_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1 2>/dev/null || echo "YOUR_IP")

echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║          ✅ LAB IS READY!                        ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}  Landing Page:${NC}  http://${REAL_IP}:80"
echo -e "${BOLD}  WordPress:${NC}     http://cafeipmac.local  (port 8080)"
echo -e "${BOLD}  Admin Panel:${NC}   http://cafeipmac.local/wp-admin"
echo -e "${BOLD}  Credentials:${NC}   admin / hulabaloo"
echo ""
echo -e "${YELLOW}  ── Hosts Entry Required ──────────────────────────${NC}"
echo -e "  Add to /etc/hosts:${NC}"
echo -e "  ${CYAN}${BOLD}  ${REAL_IP}  cafeipmac.local${NC}"
echo ""
echo -e "${YELLOW}  ── Attack Surface ─────────────────────────────────${NC}"
echo -e "  SQLi endpoint:  /wp-admin/admin-ajax.php"
echo -e "  Action:         ps_get_survey_results (unauthenticated)"
echo -e "  Param:          surveyId"
echo ""
echo -e "${YELLOW}  ── Stop Lab ────────────────────────────────────────${NC}"
echo -e "  $COMPOSE down"
echo ""
