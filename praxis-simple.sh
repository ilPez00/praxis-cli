#!/bin/bash
#===============================================================================
# PRAXIS CLI - Simple Text Mode
# A simple terminal interface for Praxis (no ncurses/tput required)
# Can work in offline mode or connected to Praxis Webapp API
#===============================================================================

readonly VERSION="1.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/praxis"
readonly DATA_FILE="$DATA_DIR/praxis_data.json"
readonly GOALS_FILE="$DATA_DIR/goals.json"
readonly JOURNAL_FILE="$DATA_DIR/journal.json"
readonly USERS_FILE="$DATA_DIR/users.json"
readonly SESSION_FILE="$DATA_DIR/session.json"
readonly CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/praxis/config.json"

# API Configuration (optional - for online mode)
PRAXIS_API_URL="${PRAXIS_API_URL:-http://localhost:3001}"
PRAXIS_SUPABASE_URL="${PRAXIS_SUPABASE_URL:-}"
PRAXIS_SUPABASE_ANON_KEY="${PRAXIS_SUPABASE_ANON_KEY:-}"

# Online mode flag
ONLINE_MODE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# Global state
USERNAME=""
STREAK=0
PRAXIS_POINTS=0
CURRENT_GOAL=""
GOAL_PROGRESS=0
TODAY_ENTRIES=0
AXIOM_QUOTE="Progress is real."
LAST_LOGIN=""
LOGGED_IN=false
USER_ID=""
ACCESS_TOKEN=""

init_data() {
    mkdir -p "$DATA_DIR"

    if [[ ! -f "$DATA_FILE" ]]; then
        cat > "$DATA_FILE" << 'EOF'
{
    "username": "User",
    "streak": 0,
    "praxis_points": 0,
    "current_goal": "",
    "goal_progress": 0,
    "today_entries": 0,
    "axiom_quote": "Progress is real."
}
EOF
    fi

    if [[ ! -f "$GOALS_FILE" ]]; then
        cat > "$GOALS_FILE" << 'EOF'
{
    "goals": [
        {"id": 1, "name": "Learn a new skill", "progress": 25, "target": 100, "status": "active"},
        {"id": 2, "name": "Daily exercise", "progress": 5, "target": 30, "status": "active"},
        {"id": 3, "name": "Read more books", "progress": 3, "target": 12, "status": "active"}
    ]
}
EOF
    fi

    if [[ ! -f "$JOURNAL_FILE" ]]; then
        cat > "$JOURNAL_FILE" << 'EOF'
{
    "entries": [
        {"id": 1, "date": "2026-03-15", "type": "checkin", "content": "Starting my Praxis journey!", "mood": "motivated"},
        {"id": 2, "date": "2026-03-14", "type": "achievement", "content": "Completed first week streak!", "mood": "happy"}
    ]
}
EOF
    fi

    # Initialize users file
    if [[ ! -f "$USERS_FILE" ]]; then
        cat > "$USERS_FILE" << 'EOF'
{
    "users": [
        {"username": "admin", "password": "admin", "created": "2026-03-01"},
        {"username": "user", "password": "user", "created": "2026-03-01"}
    ]
}
EOF
    fi
    
    # Load config if exists
    if [[ -f "$CONFIG_FILE" ]]; then
        PRAXIS_API_URL=$(grep -o '"api_url"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4 || echo "http://localhost:3001")
        PRAXIS_SUPABASE_URL=$(grep -o '"supabase_url"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4 || echo "")
        PRAXIS_SUPABASE_ANON_KEY=$(grep -o '"supabase_anon_key"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4 || echo "")
    fi
}

#===============================================================================
# API FUNCTIONS (Online Mode)
#===============================================================================

# Supabase login
api_login() {
    local email="$1"
    local password="$2"
    
    if [[ -z "$PRAXIS_SUPABASE_URL" ]] || [[ -z "$PRAXIS_SUPABASE_ANON_KEY" ]]; then
        return 1
    fi
    
    local auth_url="$PRAXIS_SUPABASE_URL/auth/v1/token?grant_type=password"
    local data="{\"email\":\"$email\",\"password\":\"$password\"}"
    
    local response
    response=$(curl -s -X POST "$auth_url" \
        -H "Content-Type: application/json" \
        -H "apikey: $PRAXIS_SUPABASE_ANON_KEY" \
        -H "Authorization: Bearer $PRAXIS_SUPABASE_ANON_KEY" \
        -d "$data")
    
    echo "$response"
}

# Get dashboard data
api_get_dashboard() {
    local user_id="$1"
    local token="$2"
    
    if [[ -z "$token" ]]; then
        return 1
    fi
    
    local response
    response=$(curl -s -X GET "$PRAXIS_API_URL/api/dashboard/summary?userId=$user_id" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        --connect-timeout 5)
    
    echo "$response"
}

# Get goals
api_get_goals() {
    local user_id="$1"
    local token="$2"
    
    curl -s -X GET "$PRAXIS_API_URL/api/goals?userId=$user_id" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        --connect-timeout 5
}

# Get journal
api_get_journal() {
    local user_id="$1"
    local token="$2"
    
    curl -s -X GET "$PRAXIS_API_URL/api/journal?userId=$user_id" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        --connect-timeout 5
}

# Check in
api_checkin() {
    local user_id="$1"
    local token="$2"
    
    local data="{\"userId\":\"$user_id\"}"
    
    curl -s -X POST "$PRAXIS_API_URL/api/checkin" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "$data" \
        --connect-timeout 5
}

# Test API connection
test_api_connection() {
    if [[ -z "$PRAXIS_SUPABASE_URL" ]] || [[ -z "$PRAXIS_SUPABASE_ANON_KEY" ]]; then
        return 1
    fi
    
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" "$PRAXIS_SUPABASE_URL" --connect-timeout 3)
    
    if [[ "$response" == "000" ]]; then
        return 1
    fi
    
    return 0
}

load_data() {
    if [[ -f "$DATA_FILE" ]]; then
        USERNAME=$(grep -o '"username"[[:space:]]*:[[:space:]]*"[^"]*"' "$DATA_FILE" | cut -d'"' -f4 || echo "User")
        STREAK=$(grep -o '"streak"[[:space:]]*:[[:space:]]*[0-9]*' "$DATA_FILE" | grep -o '[0-9]*$' || echo "0")
        PRAXIS_POINTS=$(grep -o '"praxis_points"[[:space:]]*:[[:space:]]*[0-9]*' "$DATA_FILE" | grep -o '[0-9]*$' || echo "0")
        CURRENT_GOAL=$(grep -o '"current_goal"[[:space:]]*:[[:space:]]*"[^"]*"' "$DATA_FILE" | cut -d'"' -f4 || echo "")
        GOAL_PROGRESS=$(grep -o '"goal_progress"[[:space:]]*:[[:space:]]*[0-9]*' "$DATA_FILE" | grep -o '[0-9]*$' || echo "0")
        TODAY_ENTRIES=$(grep -o '"today_entries"[[:space:]]*:[[:space:]]*[0-9]*' "$DATA_FILE" | grep -o '[0-9]*$' || echo "0")
        AXIOM_QUOTE=$(grep -o '"axiom_quote"[[:space:]]*:[[:space:]]*"[^"]*"' "$DATA_FILE" | cut -d'"' -f4 || echo "Progress is real.")
        LAST_LOGIN=$(grep -o '"last_login"[[:space:]]*:[[:space:]]*"[^"]*"' "$DATA_FILE" | cut -d'"' -f4 || echo "")
    fi
    
    USERNAME=${USERNAME:-"User"}
    STREAK=${STREAK:-0}
    PRAXIS_POINTS=${PRAXIS_POINTS:-0}
    AXIOM_QUOTE=${AXIOM_QUOTE:-"Progress is real."}
}

save_data() {
    cat > "$DATA_FILE" << EOF
{
    "username": "$USERNAME",
    "streak": $STREAK,
    "praxis_points": $PRAXIS_POINTS,
    "last_login": "$(date '+%Y-%m-%d %H:%M')",
    "current_goal": "$CURRENT_GOAL",
    "goal_progress": $GOAL_PROGRESS,
    "today_entries": $TODAY_ENTRIES,
    "axiom_quote": "$AXIOM_QUOTE"
}
EOF
}

#===============================================================================
# LOGIN/LOGOUT FUNCTIONS
#===============================================================================
check_session() {
    if [[ -f "$SESSION_FILE" ]]; then
        local saved_user
        saved_user=$(grep -o '"username"[[:space:]]*:[[:space:]]*"[^"]*"' "$SESSION_FILE" | cut -d'"' -f4)
        if [[ -n "$saved_user" ]]; then
            USERNAME="$saved_user"
            LOGGED_IN=true
            
            # Check if online mode
            if grep -q '"online_mode"[[:space:]]*:[[:space:]]*true' "$SESSION_FILE"; then
                ONLINE_MODE=true
                ACCESS_TOKEN=$(grep -o '"access_token"[[:space:]]*:[[:space:]]*"[^"]*"' "$SESSION_FILE" | cut -d'"' -f4)
                USER_ID=$(grep -o '"user_id"[[:space:]]*:[[:space:]]*"[^"]*"' "$SESSION_FILE" | cut -d'"' -f4)
                
                # Try to load from API
                if test_api_connection && load_data_from_api; then
                    return 0
                fi
                # Fallback to local data if API unavailable
                echo -e "${YELLOW}⚠ API unavailable, using cached data${RESET}"
            fi
            
            # Load user-specific data (offline mode)
            local user_data_file="$DATA_DIR/user_${USERNAME}.json"
            if [[ -f "$user_data_file" ]]; then
                DATA_FILE="$user_data_file"
                load_data
            fi
            return 0
        fi
    fi
    return 1
}

# Load data from API (online mode)
load_data_from_api() {
    if [[ -z "$ACCESS_TOKEN" ]] || [[ -z "$USER_ID" ]]; then
        return 1
    fi
    
    # Get dashboard summary
    local dashboard
    dashboard=$(api_get_dashboard "$USER_ID" "$ACCESS_TOKEN")
    
    if [[ -n "$dashboard" ]] && [[ "$dashboard" != *"error"* ]]; then
        # Parse API response and update state
        # This is a simplified version - in production you'd parse the full JSON
        PRAXIS_POINTS=$(echo "$dashboard" | grep -o '"points"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*$' || echo "0")
        STREAK=$(echo "$dashboard" | grep -o '"streak"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*$' || echo "0")
        return 0
    fi
    
    return 1
}

save_session() {
    cat > "$SESSION_FILE" << EOF
{
    "username": "$USERNAME",
    "login_time": "$(date '+%Y-%m-%d %H:%M')"
}
EOF
}

clear_session() {
    rm -f "$SESSION_FILE"
}

show_login_screen() {
    clear
    draw_header
    echo
    echo -e "${BOLD}${CYAN}┌─────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${CYAN}│${RESET}                                                                 ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}         ${BOLD}Welcome to Praxis CLI${RESET} - Goal-Aligned Social OS          ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}                                                                 ${CYAN}│${RESET}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────┘${RESET}"
    echo
    
    # Check if API is configured
    if test_api_connection; then
        echo -e "  ${GREEN}✓ Online Mode${RESET} - Connected to Praxis API"
        echo -e "  ${DIM}Enter your Praxis account credentials${RESET}"
    else
        echo -e "  ${YELLOW}⚠ Offline Mode${RESET} - Local accounts only"
        echo -e "  ${DIM}Default accounts:${RESET}"
        echo -e "    Username: ${BOLD}admin${RESET}  Password: ${BOLD}admin${RESET}"
        echo -e "    Username: ${BOLD}user${RESET}   Password: ${BOLD}user${RESET}"
    fi
    echo
    draw_line
    echo
}

login() {
    show_login_screen

    echo -n -e "  ${BOLD}Username/Email:${RESET} "
    read -r input_username

    echo -n -e "  ${BOLD}Password:${RESET} "
    read -r -s input_password
    echo

    # Try online mode first if API is configured
    if test_api_connection; then
        echo -e "${DIM}Connecting to Praxis API...${RESET}"
        
        local response
        response=$(api_login "$input_username" "$input_password")
        
        local access_token
        access_token=$(echo "$response" | grep -o '"access_token"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
        
        if [[ -n "$access_token" ]]; then
            # Online login successful
            USERNAME="$input_username"
            LOGGED_IN=true
            ONLINE_MODE=true
            ACCESS_TOKEN="$access_token"
            
            # Get user ID
            USER_ID=$(echo "$response" | grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4)
            
            # Save session with token
            cat > "$SESSION_FILE" << EOF
{
    "username": "$USERNAME",
    "user_id": "$USER_ID",
    "access_token": "$access_token",
    "online_mode": true,
    "login_time": "$(date '+%Y-%m-%d %H:%M')"
}
EOF
            
            # Load user data from API
            load_data_from_api
            
            echo
            echo -e "${GREEN}✓ Login successful! Welcome, $USERNAME!${RESET}"
            echo
            sleep 1
            return 0
        fi
    fi
    
    # Fallback to offline mode
    echo -e "${DIM}Using offline mode...${RESET}"
    if [[ -f "$USERS_FILE" ]]; then
        local found=false
        while IFS= read -r line; do
            if [[ "$line" =~ \"username\".*\"$input_username\" ]] && \
               [[ "$line" =~ \"password\".*\"$input_password\" ]]; then
                found=true
                break
            fi
        done < "$USERS_FILE"

        if $found; then
            USERNAME="$input_username"
            LOGGED_IN=true
            ONLINE_MODE=false
            save_session

            # Load or create user data
            DATA_FILE="$DATA_DIR/user_${USERNAME}.json"
            if [[ ! -f "$DATA_FILE" ]]; then
                cat > "$DATA_FILE" << EOF
{
    "username": "$USERNAME",
    "streak": 0,
    "praxis_points": 0,
    "current_goal": "",
    "goal_progress": 0,
    "today_entries": 0,
    "axiom_quote": "Progress is real.",
    "created": "$(date '+%Y-%m-%d')"
}
EOF
            fi
            load_data

            echo
            echo -e "${GREEN}✓ Login successful! Welcome, $USERNAME!${RESET}"
            echo
            sleep 1
            return 0
        fi
    fi

    echo
    echo -e "${RED}✗ Invalid username or password${RESET}"
    echo
    echo -e "${DIM}Press Enter to try again...${RESET}"
    read -r
    return 1
}

logout() {
    save_data
    clear_session
    USERNAME=""
    LOGGED_IN=false
    DATA_FILE="$DATA_DIR/praxis_data.json"
    echo -e "${GREEN}✓ Logged out successfully${RESET}"
    sleep 1
}

register_user() {
    show_login_screen
    echo -e "${BOLD}Create New Account${RESET}"
    echo
    echo -n -e "  ${BOLD}New Username:${RESET} "
    read -r new_username
    
    if [[ -z "$new_username" ]]; then
        echo -e "${RED}Username cannot be empty${RESET}"
        sleep 1
        return 1
    fi
    
    # Check if user exists
    if grep -q "\"username\".*\"$new_username\"" "$USERS_FILE" 2>/dev/null; then
        echo -e "${RED}Username already exists${RESET}"
        sleep 1
        return 1
    fi
    
    echo -n -e "  ${BOLD}Password:${RESET} "
    read -r -s new_password
    echo
    echo -n -e "  ${BOLD}Confirm Password:${RESET} "
    read -r -s confirm_password
    echo
    
    if [[ "$new_password" != "$confirm_password" ]]; then
        echo -e "${RED}Passwords do not match${RESET}"
        sleep 1
        return 1
    fi
    
    # Add new user
    local temp_file=$(mktemp)
    sed 's/}$/},/' "$USERS_FILE" > "$temp_file"
    cat >> "$temp_file" << EOF

    {"username": "$new_username", "password": "$new_password", "created": "$(date '+%Y-%m-%d')}
}
EOF
    mv "$temp_file" "$USERS_FILE"
    
    echo
    echo -e "${GREEN}✓ Account created successfully!${RESET}"
    echo -e "${DIM}You can now login with your credentials${RESET}"
    sleep 1
    
    # Auto-login
    USERNAME="$new_username"
    LOGGED_IN=true
    save_session
    DATA_FILE="$DATA_DIR/user_${USERNAME}.json"
    cat > "$DATA_FILE" << EOF
{
    "username": "$USERNAME",
    "streak": 0,
    "praxis_points": 0,
    "current_goal": "",
    "goal_progress": 0,
    "today_entries": 0,
    "axiom_quote": "Progress is real.",
    "created": "$(date '+%Y-%m-%d')"
}
EOF
    load_data
}

draw_line() {
    printf "─%.0s" $(seq 1 70)
    echo
}

draw_header() {
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}                    ${BOLD}PRAXIS CLI${RESET} - Goal-Aligned Social OS              ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════╝${RESET}"
    echo
}

draw_dashboard() {
    clear
    draw_header

    # Show login status and mode
    if $LOGGED_IN; then
        if $ONLINE_MODE; then
            echo -e "  ${GREEN}✓ Online${RESET} | Logged in as: ${BOLD}$USERNAME${RESET}"
        else
            echo -e "  ${YELLOW}⚠ Offline${RESET} | Logged in as: ${BOLD}$USERNAME${RESET}"
        fi
    else
        echo -e "  ${YELLOW}⚠ Not logged in - using guest mode${RESET}"
    fi
    echo

    # Welcome & Stats row
    echo -e "${CYAN}┌─────────────────────────────┐   ┌─────────────────────────────┐${RESET}"
    echo -e "${CYAN}│${RESET} ${BOLD}Welcome${RESET}                       ${CYAN}│   │${RESET} ${BOLD}Statistics${RESET}                     ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}                             ${CYAN}│   │${RESET}                                 ${CYAN}│${RESET}"
    printf "${CYAN}│${RESET} Hello, ${BOLD}${CYAN}%-15s${RESET}        ${CYAN}│   │${RESET} ${BOLD}${YELLOW}🔥 Streak:${RESET} %-22s ${CYAN}│${RESET}\n" "$USERNAME" "$STREAK days"
    printf "${CYAN}│${RESET}                             ${CYAN}│   │${RESET} ${BOLD}${MAGENTA}⭐ Points:${RESET} %-22s ${CYAN}│${RESET}\n" "$PRAXIS_POINTS"
    printf "${CYAN}│${RESET} Last login: ${DIM}%-16s${RESET}  ${CYAN}│   │${RESET} ${BOLD}${CYAN}📊 Entries Today:${RESET} %-11s ${CYAN}│${RESET}\n" "${LAST_LOGIN:0:16}" "$TODAY_ENTRIES"
    printf "${CYAN}│${RESET} Version: ${DIM}%-20s${RESET}  ${CYAN}│   │${RESET}                                 ${CYAN}│${RESET}\n" "$VERSION"
    echo -e "${CYAN}│${RESET}                             ${CYAN}│   │${RESET}                                 ${CYAN}│${RESET}"
    echo -e "${CYAN}└─────────────────────────────┘   └─────────────────────────────┘${RESET}"
    echo
}

draw_goal_panel() {
    echo -e "${CYAN}┌─────────────────────────────┐   ┌─────────────────────────────┐${RESET}"
    echo -e "${CYAN}│${RESET} ${BOLD}Current Goal${RESET}                  ${CYAN}│   │${RESET} ${BOLD}Daily Axiom${RESET}                   ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}                             ${CYAN}│   │${RESET}                                 ${CYAN}│${RESET}"
    printf "${CYAN}│${RESET} ${BOLD}${GREEN}🎯${RESET} %-26s  ${CYAN}│   │${RESET} ${ITALIC}\"%s\"${RESET}          ${CYAN}│${RESET}\n" "${CURRENT_GOAL:-No active goal}" "${AXIOM_QUOTE:0:25}"
    echo -e "${CYAN}│${RESET}                             ${CYAN}│   │${RESET}                                 ${CYAN}│${RESET}"
    
    # Progress bar
    local filled=$((GOAL_PROGRESS / 5))
    local empty=$((20 - filled))
    printf "${CYAN}│${RESET} ["
    for ((i=0; i<filled; i++)); do printf "${GREEN}█${RESET}"; done
    for ((i=0; i<empty; i++)); do printf "${DIM}░${RESET}"; done
    printf "] %3d%%          ${CYAN}│   │${RESET} Press ${BOLD}a${RESET} for more axioms     ${CYAN}│${RESET}\n" "$GOAL_PROGRESS"
    
    echo -e "${CYAN}│${RESET}                             ${CYAN}│   │${RESET}                                 ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET} Press ${BOLD}g${RESET} to manage goals        ${CYAN}│   │${RESET}                                 ${CYAN}│${RESET}"
    echo -e "${CYAN}└─────────────────────────────┘   └─────────────────────────────┘${RESET}"
    echo
}

draw_menu() {
    echo -e "${BOLD}Quick Actions:${RESET}"
    if $LOGGED_IN; then
        echo -e "  ${CYAN}[j]${RESET} Journal Entry   ${CYAN}[g]${RESET} Goals   ${CYAN}[t]${RESET} Tracker   ${CYAN}[s]${RESET} Settings   ${CYAN}[o]${RESET} Logout"
    else
        echo -e "  ${CYAN}[j]${RESET} Journal Entry   ${CYAN}[g]${RESET} Goals   ${CYAN}[t]${RESET} Tracker   ${CYAN}[s]${RESET} Settings   ${CYAN}[l]${RESET} Login"
    fi
    echo
    draw_line
    echo -e "${DIM}Commands: ${CYAN}d${RESET}=Dashboard ${CYAN}g${RESET}=Goals ${CYAN}j${RESET}=Journal ${CYAN}t${RESET}=Tracker ${CYAN}a${RESET}=Axiom ${CYAN}s${RESET}=Settings ${CYAN}h${RESET}=Help"
    if $LOGGED_IN; then
        echo -e "${DIM}         ${CYAN}o${RESET}=Logout ${CYAN}q${RESET}=Quit${RESET}"
    else
        echo -e "${DIM}         ${CYAN}l${RESET}=Login ${CYAN}r${RESET}=Register ${CYAN}q${RESET}=Quit${RESET}"
    fi
    echo -n -e "${BOLD}praxis>${RESET} "
}

draw_goals() {
    clear
    draw_header
    echo -e "${BOLD}Your Goals:${RESET}"
    echo
    draw_line
    
    if [[ -f "$GOALS_FILE" ]]; then
        local id=1
        grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$GOALS_FILE" | cut -d'"' -f4 | while read -r goal; do
            printf "  ${CYAN}%d.${RESET} %s\n" "$id" "$goal"
            ((id++))
        done
    else
        echo "  No goals yet. Press ${BOLD}n${RESET} to add one."
    fi
    
    echo
    draw_line
    echo -e "${DIM}Press ${CYAN}n${RESET} to add goal, ${CYAN}d${RESET} to delete, ${CYAN}b${RESET} to go back${RESET}"
    echo -n -e "${BOLD}praxis/goals>${RESET} "
}

draw_journal() {
    clear
    draw_header
    echo -e "${BOLD}Journal Entries:${RESET}"
    echo
    draw_line
    
    if [[ -f "$JOURNAL_FILE" ]]; then
        grep -o '"date"[[:space:]]*:[[:space:]]*"[^"]*"' "$JOURNAL_FILE" | cut -d'"' -f4 | head -5 | while read -r date; do
            echo -e "  ${CYAN}📅${RESET} $date"
        done
        echo -e "  ${DIM}... and more entries${RESET}"
    else
        echo "  No entries yet. Press ${BOLD}n${RESET} to add one."
    fi
    
    echo
    draw_line
    echo -e "${DIM}Press ${CYAN}n${RESET} to add entry, ${CYAN}b${RESET} to go back${RESET}"
    echo -n -e "${BOLD}praxis/journal>${RESET} "
}

draw_tracker() {
    clear
    draw_header
    echo -e "${BOLD}Activity Tracker${RESET}"
    echo
    draw_line
    echo
    echo -e "  Today's entries: ${BOLD}${CYAN}$TODAY_ENTRIES${RESET}"
    echo
    echo -e "  Press ${BOLD}${GREEN}ENTER${RESET} to log an activity (+10 points)"
    echo
    draw_line
    echo -e "${DIM}Press ${CYAN}b${RESET} to go back${RESET}"
    echo -n -e "${BOLD}praxis/tracker>${RESET} "
}

draw_settings() {
    clear
    draw_header
    echo -e "${BOLD}Settings${RESET}"
    echo
    draw_line
    echo
    echo -e "  ${BOLD}Username:${RESET}     $USERNAME"
    echo -e "  ${BOLD}Data Dir:${RESET}     $DATA_DIR"
    echo -e "  ${BOLD}Streak:${RESET}       $STREAK days"
    echo -e "  ${BOLD}Total Points:${RESET} $PRAXIS_POINTS"
    echo
    draw_line
    echo -e "${DIM}Press ${CYAN}b${RESET} to go back${RESET}"
    echo -n -e "${BOLD}praxis/settings>${RESET} "
}

draw_help() {
    clear
    draw_header
    echo -e "${BOLD}Help - Keyboard Shortcuts${RESET}"
    echo
    draw_line
    echo
    echo -e "  ${CYAN}Navigation:${RESET}"
    echo -e "    ${BOLD}d${RESET}  Dashboard"
    echo -e "    ${BOLD}g${RESET}  Goals"
    echo -e "    ${BOLD}j${RESET}  Journal"
    echo -e "    ${BOLD}t${RESET}  Tracker"
    echo -e "    ${BOLD}a${RESET}  Axiom"
    echo -e "    ${BOLD}s${RESET}  Settings"
    echo
    echo -e "  ${CYAN}Actions:${RESET}"
    echo -e "    ${BOLD}h${RESET}  Help"
    echo -e "    ${BOLD}b${RESET}  Back"
    echo -e "    ${BOLD}q${RESET}  Quit"
    echo
    draw_line
    echo -e "${DIM}Press any key to continue...${RESET}"
    read -n 1
}

show_axiom() {
    local quotes=(
        "Progress is real."
        "Small steps lead to big changes."
        "Focus on what matters."
        "Consistency beats intensity."
        "Your goals are within reach."
        "Every day is a new opportunity."
        "Action creates momentum."
        "Discipline equals freedom."
    )
    local idx=$((RANDOM % ${#quotes[@]}))
    AXIOM_QUOTE="${quotes[$idx]}"
    save_data
    echo -e "${CYAN}New axiom:${RESET} ${ITALIC}\"$AXIOM_QUOTE\"${RESET}"
}

# Main loop
main_loop() {
    local view="dashboard"
    
    while true; do
        case "$view" in
            dashboard)
                draw_dashboard
                draw_goal_panel
                draw_menu
                ;;
            goals)
                draw_goals
                ;;
            journal)
                draw_journal
                ;;
            tracker)
                draw_tracker
                ;;
            settings)
                draw_settings
                ;;
            help)
                draw_help
                view="dashboard"
                continue
                ;;
        esac
        
        read -r input
        
        case "$input" in
            q|Q)
                echo -e "\n${CYAN}Thanks for using Praxis CLI!${RESET}"
                save_data
                break
                ;;
            d|D) view="dashboard" ;;
            g|G) view="goals" ;;
            j|J) view="journal" ;;
            t|T) view="tracker" ;;
            s|S) view="settings" ;;
            h|H) view="help" ;;
            a|A) show_axiom ;;
            b|B) view="dashboard" ;;
            l|L)
                if ! $LOGGED_IN; then
                    if login; then
                        view="dashboard"
                    fi
                else
                    echo -e "${YELLOW}Already logged in as $USERNAME${RESET}"
                fi
                ;;
            o|O)
                if $LOGGED_IN; then
                    logout
                    view="dashboard"
                else
                    echo -e "${YELLOW}Not logged in${RESET}"
                fi
                ;;
            r|R)
                if ! $LOGGED_IN; then
                    register_user
                    view="dashboard"
                else
                    echo -e "${YELLOW}Already logged in as $USERNAME${RESET}"
                fi
                ;;
            "")
                if [[ "$view" == "tracker" ]]; then
                    ((TODAY_ENTRIES++))
                    ((PRAXIS_POINTS+=10))
                    save_data
                    echo -e "${GREEN}+10 points!${RESET}"
                else
                    view="dashboard"
                fi
                ;;
            *)
                echo -e "${DIM}Unknown command. Press ${CYAN}h${RESET} for help.${RESET}"
                ;;
        esac
    done
}

# Entry point
init_data

# Handle arguments - check BEFORE login
case "${1:-}" in
    --help|-h)
        echo "Praxis CLI v$VERSION"
        echo ""
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show help"
        echo "  --version, -v  Show version"
        echo "  --test         Test installation"
        echo ""
        echo "Default accounts:"
        echo "  admin/admin"
        echo "  user/user"
        exit 0
        ;;
    --version|-v)
        echo "Praxis CLI v$VERSION"
        exit 0
        ;;
    --test)
        echo "Praxis CLI v$VERSION - Test Mode"
        echo ""
        echo "✓ Data directories: $DATA_DIR"
        load_data
        echo "✓ Data loaded successfully"
        echo "  Username: $USERNAME"
        echo "  Streak: $STREAK days"
        echo "  Points: $PRAXIS_POINTS"
        echo ""
        echo "✓ All systems ready!"
        exit 0
        ;;
esac

# Check for existing session
if ! check_session; then
    # No existing session - show login
    login
fi

main_loop
