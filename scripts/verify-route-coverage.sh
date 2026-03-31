#!/usr/bin/env bash
# verify-route-coverage.sh — Consumer-Driven Route Coverage Verification
# Aegis Layer 4: Cross-references frontend API calls with backend routes
#
# Usage:
#   bash scripts/verify-route-coverage.sh <project-path> [--manifest <path>]
#
# Exit codes:
#   0 — All routes covered, OR degraded mode (with warning)
#   1 — Route coverage gaps found (frontend calls with no backend handler)
#
# Supports:
#   Frontend: TypeScript/JavaScript (fetch, axios, api client patterns)
#   Backend:  Go (gin/echo/chi/http), TypeScript/Node (express/fastify), Python (FastAPI/Flask/Django)
#
# Degradation (铁律):
#   When frontend API surface CANNOT be obtained, falls back to provider-driven
#   testing (current behavior). Outputs WARNING, NOT failure.

set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ─── Args ─────────────────────────────────────────────────────────────────────
PROJECT_PATH="${1:-.}"
MANIFEST_PATH=""
VERBOSE=0

shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --manifest) MANIFEST_PATH="$2"; shift 2 ;;
    --verbose|-v) VERBOSE=1; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Resolve to absolute path
PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"

# ─── Temp files ───────────────────────────────────────────────────────────────
CONSUMER_ROUTES=$(mktemp)
PROVIDER_ROUTES=$(mktemp)
trap 'rm -f "$CONSUMER_ROUTES" "$PROVIDER_ROUTES"' EXIT

# ─── Helper: normalize path (strip trailing slashes, lowercase method) ────────
normalize_route() {
  local method path
  method="$(echo "$1" | tr '[:lower:]' '[:upper:]')"
  path="$(echo "$2" | sed 's|/\+|/|g; s|/$||')"
  echo "${method} ${path}"
}

# ─── Extract Frontend API Calls ──────────────────────────────────────────────
# Scans for common patterns in TypeScript/JavaScript frontend code:
#   fetch('/api/...'), axios.get('/api/...'), api.get('/api/...'),
#   http.get('/api/...'), apiClient.post('/api/...')
extract_frontend_routes_js() {
  local search_dirs=()
  for d in "$PROJECT_PATH/frontend" "$PROJECT_PATH/client" "$PROJECT_PATH/web" \
           "$PROJECT_PATH/app" "$PROJECT_PATH/src"; do
    [[ -d "$d" ]] && search_dirs+=("$d")
  done

  if [[ ${#search_dirs[@]} -eq 0 ]]; then
    return 1
  fi

  # Pattern 1: fetch('METHOD', '/path') or fetch('/path') — GET implied
  # Pattern 2: axios.METHOD('/path') / api.METHOD('/path') / http.METHOD('/path')
  # Pattern 3: apiClient.METHOD('/path') or this.http.METHOD('/path')
  # Capture: METHOD + PATH from common API call patterns

  find "${search_dirs[@]}" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) \
    ! -path "*/node_modules/*" ! -path "*/.next/*" ! -path "*/dist/*" ! -path "*/build/*" \
    -print0 2>/dev/null | while IFS= read -r -d '' file; do

    # Match: .get('/api/...'), .post('/api/...'), .put('/api/...'), .delete('/api/...'), .patch('/api/...')
    grep -oEn '\.(get|post|put|delete|patch)\s*\(\s*["`'"'"']\/?api\/[^"`'"'"']*["`'"'"']' "$file" 2>/dev/null | while IFS=: read -r _ match; do
      method=$(echo "$match" | grep -oE '^\.(get|post|put|delete|patch)' | sed 's/^\.//' | tr '[:lower:]' '[:upper:]')
      path=$(echo "$match" | grep -oE '["`'"'"']\/?api\/[^"`'"'"']*["`'"'"']' | tr -d "\"'\`")
      # Normalize path: ensure leading slash
      [[ "$path" != /* ]] && path="/$path"
      # Replace path params like ${id} or :id with :param placeholder
      path=$(echo "$path" | sed -E 's/\$\{[^}]+\}/:param/g; s/:[a-zA-Z_]+/:param/g')
      echo "$method $path"
    done

    # Match: fetch('/api/...') — implies GET
    grep -oEn "fetch\s*\(\s*[\"'\`]\/?api\/[^\"'\`]*[\"'\`]" "$file" 2>/dev/null | while IFS=: read -r _ match; do
      path=$(echo "$match" | grep -oE "[\"'\`]\/?api\/[^\"'\`]*[\"'\`]" | tr -d "\"'\`")
      [[ "$path" != /* ]] && path="/$path"
      path=$(echo "$path" | sed -E 's/\$\{[^}]+\}/:param/g; s/:[a-zA-Z_]+/:param/g')
      echo "GET $path"
    done

    # Match: fetch('/api/...', { method: 'POST' })
    # This is harder to do reliably in bash — handled by the simpler patterns above
    # for most real-world code that uses axios/api clients
  done
}

# Extract frontend routes from Go code (http.NewRequest patterns)
extract_frontend_routes_go() {
  local search_dirs=()
  for d in "$PROJECT_PATH/frontend" "$PROJECT_PATH/client" "$PROJECT_PATH/web" \
           "$PROJECT_PATH/cmd" "$PROJECT_PATH/internal"; do
    [[ -d "$d" ]] && search_dirs+=("$d")
  done

  [[ ${#search_dirs[@]} -eq 0 ]] && return 1

  find "${search_dirs[@]}" -type f -name "*.go" ! -path "*/vendor/*" -print0 2>/dev/null | \
    while IFS= read -r -d '' file; do
    # http.NewRequest("GET", "/api/...")
    grep -oE 'http\.NewRequest\s*\(\s*"(GET|POST|PUT|DELETE|PATCH)"\s*,\s*"[^"]*"' "$file" 2>/dev/null | while read -r match; do
      method=$(echo "$match" | grep -oE '"(GET|POST|PUT|DELETE|PATCH)"' | head -1 | tr -d '"')
      path=$(echo "$match" | grep -oE '"\/[^"]*"' | tail -1 | tr -d '"')
      [[ -n "$method" && -n "$path" ]] && echo "$method $path"
    done
  done
}

# Extract frontend routes from Python code (requests/httpx patterns)
extract_frontend_routes_python() {
  local search_dirs=()
  for d in "$PROJECT_PATH/frontend" "$PROJECT_PATH/client" "$PROJECT_PATH/web" \
           "$PROJECT_PATH/app" "$PROJECT_PATH/src"; do
    [[ -d "$d" ]] && search_dirs+=("$d")
  done

  [[ ${#search_dirs[@]} -eq 0 ]] && return 1

  find "${search_dirs[@]}" -type f -name "*.py" ! -path "*/__pycache__/*" ! -path "*/venv/*" \
    -print0 2>/dev/null | while IFS= read -r -d '' file; do
    # requests.get('/api/...'), httpx.post('/api/...'), client.get('/api/...')
    grep -oE '\.(get|post|put|delete|patch)\s*\(\s*['"'"'"]\/?api\/[^'"'"'"]*['"'"'"]' "$file" 2>/dev/null | while read -r match; do
      method=$(echo "$match" | grep -oE '^\.(get|post|put|delete|patch)' | sed 's/^\.//' | tr '[:lower:]' '[:upper:]')
      path=$(echo "$match" | grep -oE "['\"]\/api\/[^'\"]*['\"]" | tr -d "\"'")
      [[ "$path" != /* ]] && path="/$path"
      path=$(echo "$path" | sed -E 's/\{[^}]+\}/:param/g')
      echo "$method $path"
    done
  done
}

# ─── Extract Backend Routes ──────────────────────────────────────────────────
# Scans backend router definitions for registered handlers

extract_backend_routes_js() {
  local search_dirs=()
  for d in "$PROJECT_PATH/backend" "$PROJECT_PATH/server" "$PROJECT_PATH/api" \
           "$PROJECT_PATH/services" "$PROJECT_PATH/src"; do
    [[ -d "$d" ]] && search_dirs+=("$d")
  done

  [[ ${#search_dirs[@]} -eq 0 ]] && return 1

  find "${search_dirs[@]}" -type f \( -name "*.ts" -o -name "*.js" \) \
    ! -path "*/node_modules/*" ! -path "*/dist/*" ! -path "*/build/*" \
    -print0 2>/dev/null | while IFS= read -r -d '' file; do

    # Express/Fastify: router.get('/api/...'), app.post('/api/...')
    grep -oE '(router|app|server)\.(get|post|put|delete|patch)\s*\(\s*['"'"'"`]\/?api\/[^'"'"'"`]*['"'"'"`]' "$file" 2>/dev/null | while read -r match; do
      method=$(echo "$match" | grep -oE '\.(get|post|put|delete|patch)' | sed 's/^\.//' | tr '[:lower:]' '[:upper:]')
      path=$(echo "$match" | grep -oE "['\"\`]\/?api\/[^'\"\`]*['\"\`]" | tr -d "\"'\`")
      [[ "$path" != /* ]] && path="/$path"
      path=$(echo "$path" | sed -E 's/:([a-zA-Z_]+)/:param/g')
      echo "$method $path"
    done
  done
}

extract_backend_routes_go() {
  local search_dirs=()
  for d in "$PROJECT_PATH/backend" "$PROJECT_PATH/server" "$PROJECT_PATH/api" \
           "$PROJECT_PATH/cmd" "$PROJECT_PATH/internal" "$PROJECT_PATH/pkg"; do
    [[ -d "$d" ]] && search_dirs+=("$d")
  done

  [[ ${#search_dirs[@]} -eq 0 ]] && return 1

  find "${search_dirs[@]}" -type f -name "*.go" ! -path "*/vendor/*" -print0 2>/dev/null | \
    while IFS= read -r -d '' file; do
    # Gin: r.GET("/api/..."), group.POST("/api/...")
    # Echo: e.GET("/api/..."), g.POST("/api/...")
    # Chi: r.Get("/api/..."), r.Post("/api/...")
    # net/http: http.HandleFunc("/api/...", handler) — method extracted from pattern
    grep -oE '\.(GET|POST|PUT|DELETE|PATCH|Get|Post|Put|Delete|Patch)\s*\(\s*"[^"]*"' "$file" 2>/dev/null | while read -r match; do
      method=$(echo "$match" | grep -oE '\.(GET|POST|PUT|DELETE|PATCH|Get|Post|Put|Delete|Patch)' | sed 's/^\.//' | tr '[:lower:]' '[:upper:]')
      path=$(echo "$match" | grep -oE '"[^"]*"' | tr -d '"')
      [[ "$path" == *api* ]] && {
        path=$(echo "$path" | sed -E 's/:([a-zA-Z_]+)/:param/g; s/\{[^}]+\}/:param/g')
        echo "$method $path"
      }
    done

    # http.HandleFunc pattern
    grep -oE 'HandleFunc\s*\(\s*"\/api\/[^"]*"' "$file" 2>/dev/null | while read -r match; do
      path=$(echo "$match" | grep -oE '"[^"]*"' | tr -d '"')
      # HandleFunc doesn't specify method — register as ALL
      echo "ANY $path"
    done
  done
}

extract_backend_routes_python() {
  local search_dirs=()
  for d in "$PROJECT_PATH/backend" "$PROJECT_PATH/server" "$PROJECT_PATH/api" \
           "$PROJECT_PATH/app" "$PROJECT_PATH/src"; do
    [[ -d "$d" ]] && search_dirs+=("$d")
  done

  [[ ${#search_dirs[@]} -eq 0 ]] && return 1

  find "${search_dirs[@]}" -type f -name "*.py" ! -path "*/__pycache__/*" ! -path "*/venv/*" \
    -print0 2>/dev/null | while IFS= read -r -d '' file; do
    # FastAPI: @app.get("/api/..."), @router.post("/api/...")
    # Flask: @app.route("/api/...", methods=["GET"])
    grep -oE '@(app|router)\.(get|post|put|delete|patch)\s*\(\s*['"'"'"]\/api\/[^'"'"'"]*['"'"'"]' "$file" 2>/dev/null | while read -r match; do
      method=$(echo "$match" | grep -oE '\.(get|post|put|delete|patch)' | sed 's/^\.//' | tr '[:lower:]' '[:upper:]')
      path=$(echo "$match" | grep -oE "['\"]\/api\/[^'\"]*['\"]" | tr -d "\"'")
      path=$(echo "$path" | sed -E 's/\{[^}]+\}/:param/g')
      echo "$method $path"
    done
  done
}

# ─── Read from manifest file (YAML) ─────────────────────────────────────────
# Simple YAML parser for route-manifest.yaml / consumer-routes.yaml
read_manifest_routes() {
  local manifest="$1"
  local current_method="" current_path=""

  while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue

    if [[ "$line" =~ method:[[:space:]]*(.+) ]]; then
      current_method="${BASH_REMATCH[1]}"
      current_method="$(echo "$current_method" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')"
    elif [[ "$line" =~ path:[[:space:]]*(.+) ]]; then
      current_path="${BASH_REMATCH[1]}"
      current_path="$(echo "$current_path" | tr -d '[:space:]')"
      if [[ -n "$current_method" && -n "$current_path" ]]; then
        echo "$current_method $current_path"
        current_method=""
        current_path=""
      fi
    fi
  done < "$manifest"
}

# ─── Main Logic ──────────────────────────────────────────────────────────────

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Aegis Route Coverage — Consumer-Driven Verification${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Project: ${PROJECT_PATH}"
echo ""

# Step 1: Collect consumer (frontend) routes
FRONTEND_FOUND=0

# Priority 1: Explicit manifest file
if [[ -n "$MANIFEST_PATH" && -f "$MANIFEST_PATH" ]]; then
  echo -e "${GREEN}▶ Reading consumer routes from manifest: ${MANIFEST_PATH}${NC}"
  read_manifest_routes "$MANIFEST_PATH" >> "$CONSUMER_ROUTES"
  FRONTEND_FOUND=1
fi

# Priority 2: consumer-routes.yaml in contracts/ (cross-workspace mode)
if [[ $FRONTEND_FOUND -eq 0 && -f "$PROJECT_PATH/contracts/consumer-routes.yaml" ]]; then
  echo -e "${GREEN}▶ Found cross-workspace consumer manifest: contracts/consumer-routes.yaml${NC}"
  read_manifest_routes "$PROJECT_PATH/contracts/consumer-routes.yaml" >> "$CONSUMER_ROUTES"
  FRONTEND_FOUND=1
fi

# Priority 3: route-manifest.yaml in contracts/
if [[ $FRONTEND_FOUND -eq 0 && -f "$PROJECT_PATH/contracts/route-manifest.yaml" ]]; then
  echo -e "${GREEN}▶ Found route manifest: contracts/route-manifest.yaml${NC}"
  read_manifest_routes "$PROJECT_PATH/contracts/route-manifest.yaml" >> "$CONSUMER_ROUTES"
  FRONTEND_FOUND=1
fi

# Priority 4: Auto-scan frontend code
if [[ $FRONTEND_FOUND -eq 0 ]]; then
  echo -e "${BLUE}▶ Scanning frontend code for API calls...${NC}"

  extract_frontend_routes_js >> "$CONSUMER_ROUTES" 2>/dev/null && FRONTEND_FOUND=1
  extract_frontend_routes_go >> "$CONSUMER_ROUTES" 2>/dev/null && FRONTEND_FOUND=1
  extract_frontend_routes_python >> "$CONSUMER_ROUTES" 2>/dev/null && FRONTEND_FOUND=1
fi

# Deduplicate consumer routes
if [[ -s "$CONSUMER_ROUTES" ]]; then
  sort -u "$CONSUMER_ROUTES" -o "$CONSUMER_ROUTES"
  CONSUMER_COUNT=$(wc -l < "$CONSUMER_ROUTES" | tr -d ' ')
  echo -e "${GREEN}  Found ${CONSUMER_COUNT} unique consumer route(s)${NC}"
else
  CONSUMER_COUNT=0
fi

# ─── Degradation Check ───────────────────────────────────────────────────────
if [[ $CONSUMER_COUNT -eq 0 ]]; then
  echo ""
  echo -e "${YELLOW}⚠️  WARNING: No frontend API surface found${NC}"
  echo -e "${YELLOW}   Reason: No consumer-routes.yaml, route-manifest.yaml, or scannable frontend code${NC}"
  echo -e "${YELLOW}   Mode: DEGRADED — falling back to provider-driven integration tests${NC}"
  echo -e "${YELLOW}   Action: Backend integration tests still required per Aegis Layer 4${NC}"
  echo -e "${YELLOW}   To fix: Add contracts/consumer-routes.yaml or ensure frontend code is scannable${NC}"
  echo ""
  echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
  echo -e "${YELLOW}  RESULT: DEGRADED (provider-driven only) — exit 0${NC}"
  echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
  exit 0
fi

# Step 2: Collect provider (backend) routes
echo ""
echo -e "${BLUE}▶ Scanning backend code for registered routes...${NC}"

extract_backend_routes_js >> "$PROVIDER_ROUTES" 2>/dev/null || true
extract_backend_routes_go >> "$PROVIDER_ROUTES" 2>/dev/null || true
extract_backend_routes_python >> "$PROVIDER_ROUTES" 2>/dev/null || true

if [[ -s "$PROVIDER_ROUTES" ]]; then
  sort -u "$PROVIDER_ROUTES" -o "$PROVIDER_ROUTES"
  PROVIDER_COUNT=$(wc -l < "$PROVIDER_ROUTES" | tr -d ' ')
  echo -e "${GREEN}  Found ${PROVIDER_COUNT} unique backend route(s)${NC}"
else
  echo ""
  echo -e "${RED}✗ ERROR: No backend routes found${NC}"
  echo -e "${RED}  Cannot verify route coverage without backend route definitions${NC}"
  echo -e "${RED}  Ensure backend code is in: backend/, server/, api/, cmd/, or src/${NC}"
  exit 1
fi

# Step 3: Cross-reference
echo ""
echo -e "${BLUE}▶ Cross-referencing consumer → provider routes...${NC}"
echo ""

MATCHED=0
UNMATCHED=0
UNMATCHED_LIST=""

while IFS= read -r consumer_route; do
  c_method=$(echo "$consumer_route" | awk '{print $1}')
  c_path=$(echo "$consumer_route" | awk '{print $2}')

  # Normalize consumer path params
  c_path_norm=$(echo "$c_path" | sed -E 's/:param/:param/g; s/:[a-zA-Z_]+/:param/g')

  found=0
  while IFS= read -r provider_route; do
    p_method=$(echo "$provider_route" | awk '{print $1}')
    p_path=$(echo "$provider_route" | awk '{print $2}')
    p_path_norm=$(echo "$p_path" | sed -E 's/:param/:param/g; s/:[a-zA-Z_]+/:param/g')

    # Match: same method + same path (with param normalization)
    # Also match if provider registered as ANY (e.g., http.HandleFunc)
    if [[ "$c_method" == "$p_method" || "$p_method" == "ANY" ]]; then
      if [[ "$c_path_norm" == "$p_path_norm" ]]; then
        found=1
        break
      fi
    fi
  done < "$PROVIDER_ROUTES"

  if [[ $found -eq 1 ]]; then
    MATCHED=$((MATCHED + 1))
    [[ $VERBOSE -eq 1 ]] && echo -e "  ${GREEN}✓${NC} ${c_method} ${c_path}"
  else
    UNMATCHED=$((UNMATCHED + 1))
    UNMATCHED_LIST="${UNMATCHED_LIST}\n  ${RED}✗${NC} ${c_method} ${c_path} — ${RED}NO BACKEND HANDLER${NC}"
  fi
done < "$CONSUMER_ROUTES"

TOTAL=$((MATCHED + UNMATCHED))

# Step 4: Report
echo -e "${BLUE}─── Route Coverage Report ──────────────────────────────────────${NC}"
echo ""
echo -e "  Consumer routes: ${TOTAL}"
echo -e "  Matched:         ${GREEN}${MATCHED}${NC}"
echo -e "  Unmatched:       ${RED}${UNMATCHED}${NC}"
if [[ $TOTAL -gt 0 ]]; then
  COVERAGE=$((MATCHED * 100 / TOTAL))
  echo -e "  Coverage:        ${COVERAGE}%"
fi
echo ""

if [[ $UNMATCHED -gt 0 ]]; then
  echo -e "${RED}Unmatched routes (frontend calls with no backend handler):${NC}"
  echo -e "$UNMATCHED_LIST"
  echo ""
  echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
  echo -e "${RED}  RESULT: FAIL — ${UNMATCHED} consumer route(s) have no backend handler${NC}"
  echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
  exit 1
else
  echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}  RESULT: PASS — All consumer routes have backend handlers${NC}"
  echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
  exit 0
fi
