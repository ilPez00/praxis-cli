#!/bin/bash
#===============================================================================
# PRAXIS CLI - API Client Library
# Connects to Praxis Webapp Backend API
#===============================================================================

# Configuration
PRAXIS_API_URL="${PRAXIS_API_URL:-http://localhost:3001}"
PRAXIS_SUPABASE_URL="${PRAXIS_SUPABASE_URL:-}"
PRAXIS_SUPABASE_ANON_KEY="${PRAXIS_SUPABASE_ANON_KEY:-}"
PRAXIS_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/praxis"
PRAXIS_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/praxis"

# Session files
SESSION_FILE="$PRAXIS_DATA_DIR/session.json"
CONFIG_FILE="$PRAXIS_CONFIG_DIR/config.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

#===============================================================================
# HTTP CLIENT FUNCTIONS
#===============================================================================

# Make HTTP GET request
# Usage: http_get <url> [auth_token]
http_get() {
    local url="$1"
    local token="$2"
    local headers="-H 'Content-Type: application/json'"
    
    if [[ -n "$token" ]]; then
        headers="$headers -H 'Authorization: Bearer $token'"
    fi
    
    curl -s -X GET "$url" $headers
}

# Make HTTP POST request
# Usage: http_post <url> <data> [auth_token]
http_post() {
    local url="$1"
    local data="$2"
    local token="$3"
    local headers="-H 'Content-Type: application/json'"
    
    if [[ -n "$token" ]]; then
        headers="$headers -H 'Authorization: Bearer $token'"
    fi
    
    curl -s -X POST "$url" \
        -H "Content-Type: application/json" \
        ${token:+-H "Authorization: Bearer $token"} \
        -d "$data"
}

# Make HTTP PUT request
http_put() {
    local url="$1"
    local data="$2"
    local token="$3"
    
    curl -s -X PUT "$url" \
        -H "Content-Type: application/json" \
        ${token:+-H "Authorization: Bearer $token"} \
        -d "$data"
}

# Make HTTP DELETE request
http_delete() {
    local url="$1"
    local token="$2"
    
    curl -s -X DELETE "$url" \
        ${token:+-H "Authorization: Bearer $token"}
}

#===============================================================================
# SUPABASE AUTH FUNCTIONS
#===============================================================================

# Supabase Auth API
SUPABASE_AUTH_URL="$PRAXIS_SUPABASE_URL/auth/v1"

# Sign up
# Usage: supabase_signup <email> <password> <name>
supabase_signup() {
    local email="$1"
    local password="$2"
    local name="$3"
    
    local data="{
        \"email\": \"$email\",
        \"password\": \"$password\",
        \"options\": {
            \"data\": {
                \"name\": \"$name\"
            }
        }
    }"
    
    http_post "$SUPABASE_AUTH_URL/signup" "$data"
}

# Sign in
# Usage: supabase_login <email> <password>
supabase_login() {
    local email="$1"
    local password="$2"
    
    local data="{
        \"email\": \"$email\",
        \"password\": \"$password\"
    }"
    
    http_post "$SUPABASE_AUTH_URL/token?grant_type=password" "$data"
}

# Sign out
# Usage: supabase_logout <access_token>
supabase_logout() {
    local token="$1"
    
    http_post "$SUPABASE_AUTH_URL/logout" "{}" "$token"
}

# Get user
# Usage: supabase_get_user <access_token>
supabase_get_user() {
    local token="$1"
    
    http_get "$SUPABASE_AUTH_URL/user" "$token"
}

# Refresh token
# Usage: supabase_refresh <refresh_token>
supabase_refresh() {
    local refresh_token="$1"
    
    local data="{
        \"refresh_token\": \"$refresh_token\"
    }"
    
    http_post "$SUPABASE_AUTH_URL/token?grant_type=refresh_token" "$data"
}

#===============================================================================
# PRAXIS API FUNCTIONS
#===============================================================================

# Praxis Backend API endpoints
PRAXIS_API="$PRAXIS_API_URL/api"

# Dashboard
api_get_dashboard() {
    local token="$1"
    local user_id="$2"
    
    http_get "$PRAXIS_API/dashboard/summary?userId=$user_id" "$token"
}

# Goals
api_get_goals() {
    local token="$1"
    local user_id="$2"
    
    http_get "$PRAXIS_API/goals?userId=$user_id" "$token"
}

api_create_goal() {
    local token="$1"
    local data="$2"
    
    http_post "$PRAXIS_API/goals" "$data" "$token"
}

api_update_goal() {
    local token="$1"
    local goal_id="$2"
    local data="$3"
    
    http_put "$PRAXIS_API/goals/$goal_id" "$data" "$token"
}

api_delete_goal() {
    local token="$1"
    local goal_id="$2"
    
    http_delete "$PRAXIS_API/goals/$goal_id" "$token"
}

# Journal
api_get_journal() {
    local token="$1"
    local user_id="$2"
    
    http_get "$PRAXIS_API/journal?userId=$user_id" "$token"
}

api_create_journal() {
    local token="$1"
    local data="$2"
    
    http_post "$PRAXIS_API/journal" "$data" "$token"
}

# Check-in
api_checkin() {
    local token="$1"
    local user_id="$2"
    local data="${3:-{}}"
    
    http_post "$PRAXIS_API/checkin" "$data" "$token"
}

# Axiom
api_get_axiom() {
    local token="$1"
    local user_id="$2"
    
    http_get "$PRAXIS_API/axiom?userId=$user_id" "$token"
}

# Points
api_get_points() {
    local token="$1"
    local user_id="$2"
    
    http_get "$PRAXIS_API/points?userId=$user_id" "$token"
}

# Tracker
api_get_tracker() {
    local token="$1"
    local user_id="$2"
    local days="${3:-7}"
    
    http_get "$PRAXIS_API/tracker?userId=$user_id&days=$days" "$token"
}

#===============================================================================
# SESSION MANAGEMENT
#===============================================================================

# Save session
save_session() {
    local access_token="$1"
    local refresh_token="$2"
    local user_data="$3"
    local expires_at="$4"
    
    mkdir -p "$PRAXIS_DATA_DIR"
    
    cat > "$SESSION_FILE" << EOF
{
    "access_token": "$access_token",
    "refresh_token": "$refresh_token",
    "user": $user_data,
    "expires_at": $expires_at,
    "created_at": $(date +%s)
}
EOF
}

# Load session
load_session() {
    if [[ -f "$SESSION_FILE" ]]; then
        cat "$SESSION_FILE"
    else
        echo "{}"
    fi
}

# Get access token from session
get_access_token() {
    if [[ -f "$SESSION_FILE" ]]; then
        grep -o '"access_token"[[:space:]]*:[[:space:]]*"[^"]*"' "$SESSION_FILE" | cut -d'"' -f4
    fi
}

# Get refresh token from session
get_refresh_token() {
    if [[ -f "$SESSION_FILE" ]]; then
        grep -o '"refresh_token"[[:space:]]*:[[:space:]]*"[^"]*"' "$SESSION_FILE" | cut -d'"' -f4
    fi
}

# Get user ID from session
get_user_id() {
    if [[ -f "$SESSION_FILE" ]]; then
        grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' "$SESSION_FILE" | head -1 | cut -d'"' -f4
    fi
}

# Clear session
clear_session() {
    rm -f "$SESSION_FILE"
}

# Check if session is valid
is_session_valid() {
    if [[ ! -f "$SESSION_FILE" ]]; then
        return 1
    fi
    
    local expires_at
    expires_at=$(grep -o '"expires_at"[[:space:]]*:[[:space:]]*[0-9]*' "$SESSION_FILE" | grep -o '[0-9]*$')
    
    if [[ -z "$expires_at" ]]; then
        return 1
    fi
    
    local now
    now=$(date +%s)
    
    if [[ $now -ge $expires_at ]]; then
        # Try to refresh
        refresh_session
        return $?
    fi
    
    return 0
}

# Refresh session
refresh_session() {
    local refresh_token
    refresh_token=$(get_refresh_token)
    
    if [[ -z "$refresh_token" ]]; then
        return 1
    fi
    
    local response
    response=$(supabase_refresh "$refresh_token")
    
    local new_access_token
    new_access_token=$(echo "$response" | grep -o '"access_token"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
    
    if [[ -n "$new_access_token" ]]; then
        # Update session file with new token
        local old_session
        old_session=$(cat "$SESSION_FILE")
        
        # Simple sed replacement
        sed -i "s/\"access_token\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"access_token\": \"$new_access_token\"/" "$SESSION_FILE"
        return 0
    fi
    
    return 1
}

#===============================================================================
# CONFIGURATION
#===============================================================================

# Save configuration
save_config() {
    local api_url="$1"
    local supabase_url="$2"
    local supabase_key="$3"
    
    mkdir -p "$PRAXIS_CONFIG_DIR"
    
    cat > "$CONFIG_FILE" << EOF
{
    "api_url": "$api_url",
    "supabase_url": "$supabase_url",
    "supabase_anon_key": "$supabase_key"
}
EOF
}

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        cat "$CONFIG_FILE"
    else
        echo "{}"
    fi
}

# Initialize config from environment or defaults
init_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        save_config "$PRAXIS_API_URL" "$PRAXIS_SUPABASE_URL" "$PRAXIS_SUPABASE_ANON_KEY"
    fi
    
    # Load values from config
    if [[ -f "$CONFIG_FILE" ]]; then
        PRAXIS_API_URL=$(grep -o '"api_url"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
        PRAXIS_SUPABASE_URL=$(grep -o '"supabase_url"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
        PRAXIS_SUPABASE_ANON_KEY=$(grep -o '"supabase_anon_key"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
    fi
}

#===============================================================================
# UTILITY FUNCTIONS
#===============================================================================

# Parse JSON response (simple grep-based)
json_get() {
    local json="$1"
    local key="$2"
    
    echo "$json" | grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | cut -d'"' -f4
}

json_get_number() {
    local json="$1"
    local key="$2"
    
    echo "$json" | grep -o "\"$key\"[[:space:]]*:[[:space:]]*[0-9]*" | head -1 | grep -o '[0-9]*$'
}

# Print API error
print_api_error() {
    local error="$1"
    echo -e "${RED}API Error: $error${RESET}" >&2
}

# Check API connectivity
check_api_connection() {
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" "$PRAXIS_API_URL" --connect-timeout 5)
    
    if [[ "$response" == "000" ]]; then
        echo -e "${RED}✗ Cannot connect to Praxis API at $PRAXIS_API_URL${RESET}"
        return 1
    else
        echo -e "${GREEN}✓ Connected to Praxis API${RESET}"
        return 0
    fi
}

#===============================================================================
# CLI COMMANDS
#===============================================================================

cmd_login() {
    echo -e "${BOLD}Login to Praxis${RESET}"
    echo -n "Email: "
    read -r email
    
    echo -n "Password: "
    read -r -s password
    echo
    
    local response
    response=$(supabase_login "$email" "$password")
    
    local access_token
    access_token=$(json_get "$response" "access_token")
    
    if [[ -n "$access_token" ]]; then
        local refresh_token user_json expires_at
        refresh_token=$(json_get "$response" "refresh_token")
        expires_at=$(($(date +%s) + 3600)) # 1 hour from now
        user_json=$(echo "$response" | grep -o '"user"[[:space:]]*:[[:space:]]*{[^}]*}' | sed 's/"user"[[:space:]]*:[[:space:]]*//')
        
        save_session "$access_token" "$refresh_token" "$user_json" "$expires_at"
        
        echo -e "${GREEN}✓ Login successful!${RESET}"
        return 0
    else
        local error_msg
        error_msg=$(json_get "$response" "msg")
        echo -e "${RED}✗ Login failed: ${error_msg:-Unknown error}${RESET}"
        return 1
    fi
}

cmd_logout() {
    local token
    token=$(get_access_token)
    
    if [[ -n "$token" ]]; then
        supabase_logout "$token" 2>/dev/null || true
    fi
    
    clear_session
    echo -e "${GREEN}✓ Logged out successfully${RESET}"
}

cmd_status() {
    echo -e "${BOLD}Praxis CLI Status${RESET}"
    echo
    
    if is_session_valid; then
        local user_id
        user_id=$(get_user_id)
        echo -e "${GREEN}✓ Logged in${RESET}"
        echo -e "  User ID: $user_id"
        echo -e "  API URL: $PRAXIS_API_URL"
    else
        echo -e "${YELLOW}⚠ Not logged in${RESET}"
    fi
}

cmd_config() {
    echo -e "${BOLD}Praxis CLI Configuration${RESET}"
    echo
    
    echo -e "API URL: ${CYAN}$PRAXIS_API_URL${RESET}"
    echo -e "Supabase URL: ${CYAN}$PRAXIS_SUPABASE_URL${RESET}"
    echo
    
    echo -e "${DIM}To configure, set environment variables:${RESET}"
    echo -e "  export PRAXIS_API_URL=https://your-api.herokuapp.com"
    echo -e "  export PRAXIS_SUPABASE_URL=https://xxx.supabase.co"
    echo -e "  export PRAXIS_SUPABASE_ANON_KEY=your-anon-key"
}

cmd_help() {
    echo -e "${BOLD}Praxis CLI - API Client${RESET}"
    echo
    echo -e "Usage: $0 <command> [options]"
    echo
    echo -e "${BOLD}Commands:${RESET}"
    echo -e "  login       Login to your Praxis account"
    echo -e "  logout      Logout from your account"
    echo -e "  status      Show login status"
    echo -e "  config      Show configuration"
    echo -e "  dashboard   Get dashboard summary"
    echo -e "  goals       List your goals"
    echo -e "  journal     List journal entries"
    echo -e "  checkin     Log a daily check-in"
    echo -e "  help        Show this help"
    echo
    echo -e "${DIM}Environment Variables:${RESET}"
    echo -e "  PRAXIS_API_URL         - Backend API URL"
    echo -e "  PRAXIS_SUPABASE_URL    - Supabase project URL"
    echo -e "  PRAXIS_SUPABASE_ANON_KEY - Supabase anon/public key"
}

#===============================================================================
# MAIN
#===============================================================================

# Initialize configuration
init_config

# Handle commands
case "${1:-}" in
    login)
        cmd_login
        ;;
    logout)
        cmd_logout
        ;;
    status)
        cmd_status
        ;;
    config)
        cmd_config
        ;;
    dashboard)
        if is_session_valid; then
            local token user_id
            token=$(get_access_token)
            user_id=$(get_user_id)
            api_get_dashboard "$token" "$user_id"
        else
            echo -e "${RED}Not logged in. Run: $0 login${RESET}"
            exit 1
        fi
        ;;
    goals)
        if is_session_valid; then
            local token user_id
            token=$(get_access_token)
            user_id=$(get_user_id)
            api_get_goals "$token" "$user_id"
        else
            echo -e "${RED}Not logged in${RESET}"
            exit 1
        fi
        ;;
    journal)
        if is_session_valid; then
            local token user_id
            token=$(get_access_token)
            user_id=$(get_user_id)
            api_get_journal "$token" "$user_id"
        else
            echo -e "${RED}Not logged in${RESET}"
            exit 1
        fi
        ;;
    checkin)
        if is_session_valid; then
            local token user_id
            token=$(get_access_token)
            user_id=$(get_user_id)
            api_checkin "$token" "$user_id"
            echo -e "${GREEN}✓ Check-in logged${RESET}"
        else
            echo -e "${RED}Not logged in${RESET}"
            exit 1
        fi
        ;;
    help|-h|--help)
        cmd_help
        ;;
    *)
        if [[ -n "${1:-}" ]]; then
            echo -e "${RED}Unknown command: $1${RESET}"
        fi
        cmd_help
        ;;
esac
