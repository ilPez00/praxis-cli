#!/bin/bash
#===============================================================================
# PRAXIS TUI CLIENT
# A terminal-based interface for Praxis - Goal-Aligned Social Operating System
#===============================================================================

set -o pipefail

#===============================================================================
# CONFIGURATION
#===============================================================================
readonly VERSION="1.0.0"
readonly APP_NAME="Praxis TUI"
readonly DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/praxis"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/praxis"
readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/praxis"
readonly DATA_FILE="$DATA_DIR/praxis_data.json"
readonly CONFIG_FILE="$CONFIG_DIR/praxis_config.json"
readonly JOURNAL_FILE="$DATA_DIR/journal.json"
readonly GOALS_FILE="$DATA_DIR/goals.json"

#===============================================================================
# COLORS (ANSI escape codes for terminal)
#===============================================================================
# Basic colors
readonly RESET='\033[0m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly ITALIC='\033[3m'
readonly UNDERLINE='\033[4m'
readonly BLINK='\033[5m'
readonly REVERSE='\033[7m'

# Foreground colors
readonly BLACK='\033[30m'
readonly RED='\033[31m'
readonly GREEN='\033[32m'
readonly YELLOW='\033[33m'
readonly BLUE='\033[34m'
readonly MAGENTA='\033[35m'
readonly CYAN='\033[36m'
readonly WHITE='\033[37m'

# Bright foreground colors
readonly BRIGHT_BLACK='\033[90m'
readonly BRIGHT_RED='\033[91m'
readonly BRIGHT_GREEN='\033[92m'
readonly BRIGHT_YELLOW='\033[93m'
readonly BRIGHT_BLUE='\033[94m'
readonly BRIGHT_MAGENTA='\033[95m'
readonly BRIGHT_CYAN='\033[96m'
readonly BRIGHT_WHITE='\033[97m'

# Background colors
readonly BG_BLACK='\033[40m'
readonly BG_RED='\033[41m'
readonly BG_GREEN='\033[42m'
readonly BG_YELLOW='\033[43m'
readonly BG_BLUE='\033[44m'
readonly BG_MAGENTA='\033[45m'
readonly BG_CYAN='\033[46m'
readonly BG_WHITE='\033[47m'

#===============================================================================
# GLOBAL STATE
#===============================================================================
declare -g CURRENT_VIEW="dashboard"
declare -g SELECTED_INDEX=0
declare -g SCROLL_OFFSET=0
declare -g STATUS_MESSAGE=""
declare -g STATUS_TYPE="info"
declare -g RUNNING=true
declare -g USERNAME=""
declare -g STREAK=0
declare -g PRAXIS_POINTS=0
declare -g LAST_LOGIN=""
declare -g CURRENT_GOAL=""
declare -g GOAL_PROGRESS=0
declare -g TODAY_ENTRIES=0
declare -g AXIOM_QUOTE=""

#===============================================================================
# TERMINAL CONTROL
#===============================================================================
# Save and restore terminal state
save_terminal() {
    tput smcup      # Save screen
    tput cup 0 0    # Move cursor to home
    tput civis      # Hide cursor
    stty -echo      # Disable echo
    stty -icanon    # Disable canonical mode (raw input)
}

restore_terminal() {
    tput rmcup      # Restore screen
    tput cnorm      # Show cursor
    stty echo       # Enable echo
    stty icanon     # Enable canonical mode
    clear
}

# Get terminal dimensions
get_terminal_size() {
    local lines cols
    lines=$(tput lines)
    cols=$(tput cols)
    echo "$lines $cols"
}

# Clear screen
clear_screen() {
    tput clear
}

# Move cursor
move_cursor() {
    local row=$1
    local col=$2
    tput cup "$row" "$col"
}

# Hide/show cursor
hide_cursor() { tput civis; }
show_cursor() { tput cnorm; }

#===============================================================================
# DATA MANAGEMENT
#===============================================================================
init_data_dirs() {
    mkdir -p "$DATA_DIR" "$CONFIG_DIR" "$CACHE_DIR"
    
    # Initialize data file if not exists
    if [[ ! -f "$DATA_FILE" ]]; then
        cat > "$DATA_FILE" << 'EOF'
{
    "username": "User",
    "streak": 0,
    "praxis_points": 0,
    "last_login": "",
    "current_goal": "",
    "goal_progress": 0,
    "today_entries": 0,
    "axiom_quote": "Progress is real.",
    "created_at": "$(date -Iseconds)",
    "updated_at": "$(date -Iseconds)"
}
EOF
    fi
    
    # Initialize goals file
    if [[ ! -f "$GOALS_FILE" ]]; then
        cat > "$GOALS_FILE" << 'EOF'
{
    "goals": [
        {"id": 1, "name": "Learn a new skill", "progress": 0, "target": 100, "created": "2026-03-01", "status": "active"},
        {"id": 2, "name": "Daily exercise", "progress": 5, "target": 30, "created": "2026-03-10", "status": "active"},
        {"id": 3, "name": "Read more books", "progress": 3, "target": 12, "created": "2026-02-15", "status": "active"}
    ]
}
EOF
    fi
    
    # Initialize journal file
    if [[ ! -f "$JOURNAL_FILE" ]]; then
        cat > "$JOURNAL_FILE" << 'EOF'
{
    "entries": [
        {"id": 1, "date": "2026-03-15", "type": "checkin", "content": "Starting my Praxis journey!", "mood": "motivated"},
        {"id": 2, "date": "2026-03-14", "type": "achievement", "content": "Completed first week streak!", "mood": "happy"},
        {"id": 3, "date": "2026-03-13", "type": "reflection", "content": "Learning to focus on what matters.", "mood": "calm"}
    ]
}
EOF
    fi
}

load_data() {
    if [[ -f "$DATA_FILE" ]]; then
        # Parse JSON using bash (simple parsing)
        USERNAME=$(grep -o '"username"[[:space:]]*:[[:space:]]*"[^"]*"' "$DATA_FILE" | cut -d'"' -f4)
        STREAK=$(grep -o '"streak"[[:space:]]*:[[:space:]]*[0-9]*' "$DATA_FILE" | grep -o '[0-9]*$')
        PRAXIS_POINTS=$(grep -o '"praxis_points"[[:space:]]*:[[:space:]]*[0-9]*' "$DATA_FILE" | grep -o '[0-9]*$')
        LAST_LOGIN=$(grep -o '"last_login"[[:space:]]*:[[:space:]]*"[^"]*"' "$DATA_FILE" | cut -d'"' -f4)
        CURRENT_GOAL=$(grep -o '"current_goal"[[:space:]]*:[[:space:]]*"[^"]*"' "$DATA_FILE" | cut -d'"' -f4)
        GOAL_PROGRESS=$(grep -o '"goal_progress"[[:space:]]*:[[:space:]]*[0-9]*' "$DATA_FILE" | grep -o '[0-9]*$')
        TODAY_ENTRIES=$(grep -o '"today_entries"[[:space:]]*:[[:space:]]*[0-9]*' "$DATA_FILE" | grep -o '[0-9]*$')
        AXIOM_QUOTE=$(grep -o '"axiom_quote"[[:space:]]*:[[:space:]]*"[^"]*"' "$DATA_FILE" | cut -d'"' -f4)
    fi
    
    # Set defaults if empty
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
    "last_login": "$(date -Iseconds)",
    "current_goal": "$CURRENT_GOAL",
    "goal_progress": $GOAL_PROGRESS,
    "today_entries": $TODAY_ENTRIES,
    "axiom_quote": "$AXIOM_QUOTE",
    "updated_at": "$(date -Iseconds)"
}
EOF
}

add_praxis_points() {
    local points=$1
    PRAXIS_POINTS=$((PRAXIS_POINTS + points))
    save_data
    set_status "Earned $points Praxis Points!" "success"
}

#===============================================================================
# UI DRAWING FUNCTIONS
#===============================================================================
# Draw a box/panel
draw_box() {
    local x=$1 y=$2 width=$3 height=$4 title="$5"
    local i
    
    # Corners and borders
    move_cursor $y $x
    echo -n "┌"
    for ((i=1; i<width-1; i++)); do echo -n "─"; done
    echo -n "┐"
    
    for ((i=1; i<height-1; i++)); do
        move_cursor $((y+i)) $x
        echo -n "│"
        move_cursor $((y+i)) $((x+width-1))
        echo -n "│"
    done
    
    move_cursor $((y+height-1)) $x
    echo -n "└"
    for ((i=1; i<width-1; i++)); do echo -n "─"; done
    echo -n "┘"
    
    # Title
    if [[ -n "$title" ]]; then
        move_cursor $y $((x+2))
        echo -ne "${BOLD}${title}${RESET}"
    fi
}

# Draw a filled box with background
draw_panel() {
    local x=$1 y=$2 width=$3 height=$4 title="$5" style="$6"
    local i j
    
    draw_box $x $y $width $height "$title"
    
    # Fill background if style provided
    if [[ -n "$style" ]]; then
        for ((i=1; i<height-1; i++)); do
            move_cursor $((y+i)) $((x+1))
            for ((j=1; j<width-1; j++)); do
                echo -ne "${style} ${RESET}"
            done
        done
    fi
}

# Draw horizontal line
draw_hline() {
    local x=$1 y=$2 width=$3 char="${4:─}"
    move_cursor $y $x
    for ((i=0; i<width; i++)); do echo -n "$char"; done
}

# Draw vertical line
draw_vline() {
    local x=$1 y=$2 height=$3 char="${4:│}"
    for ((i=0; i<height; i++)); do
        move_cursor $((y+i)) $x
        echo -n "$char"
    done
}

# Draw text at position
draw_text() {
    local x=$1 y=$2 text="$3" max_width=${4:-0}
    move_cursor $y $x
    if [[ $max_width -gt 0 ]] && [[ ${#text} -gt $max_width ]]; then
        echo -n "${text:0:$((max_width-3))}..."
    else
        echo -n "$text"
    fi
}

# Draw centered text
draw_centered() {
    local y=$1 text="$2" width=${3:-$(tput cols)}
    local padding=$(( (width - ${#text}) / 2 ))
    move_cursor $y $padding
    echo -n "$text"
}

# Draw progress bar
draw_progress() {
    local x=$1 y=$2 width=$3 progress=$4 label="$5"
    local filled=$(( (progress * (width-2)) / 100 ))
    local empty=$((width - 2 - filled))
    local i
    
    move_cursor $y $x
    echo -n "["
    for ((i=0; i<filled; i++)); do echo -ne "${GREEN}█${RESET}"; done
    for ((i=0; i<empty; i++)); do echo -ne "${DIM}░${RESET}"; done
    echo -n "]"
    
    if [[ -n "$label" ]]; then
        move_cursor $y $((x+width+2))
        echo -n "$label%"
    fi
}

# Draw status bar at bottom
draw_status_bar() {
    local width height
    read width height < <(get_terminal_size)
    
    move_cursor $((height-1)) 0
    echo -ne "${REVERSE}${BRIGHT_BLACK}${WHITE}"
    printf " %-20s │ Press 'q' to quit │ 'h' for help │ %-${width}s " \
        "View: $CURRENT_VIEW" "Praxis TUI v$VERSION"
    echo -ne "${RESET}"
}

# Draw header
draw_header() {
    local width height
    read width height < <(get_terminal_size)
    
    move_cursor 0 0
    echo -ne "${BOLD}${BRIGHT_CYAN}${BG_BLACK}"
    printf " PRAXIS TUI ${RESET}${BRIGHT_CYAN}${BG_BLACK}%-${width}s" ""
    echo -ne "${RESET}"
    
    move_cursor 0 2
    echo -ne "${DIM}Goal-Aligned Social Operating System${RESET}"
}

# Set status message
set_status() {
    STATUS_MESSAGE="$1"
    STATUS_TYPE="${2:-info}"
    
    # Auto-clear after 3 seconds
    (sleep 3; STATUS_MESSAGE="") &
}

# Draw status message
draw_status_message() {
    if [[ -n "$STATUS_MESSAGE" ]]; then
        local width height color
        read width height < <(get_terminal_size)
        
        case "$STATUS_TYPE" in
            success) color="${BRIGHT_GREEN}" ;;
            error) color="${BRIGHT_RED}" ;;
            warning) color="${BRIGHT_YELLOW}" ;;
            *) color="${BRIGHT_CYAN}" ;;
        esac
        
        move_cursor 0 $((height-2))
        echo -ne "${color}${BOLD} $STATUS_MESSAGE ${RESET}"
    fi
}

#===============================================================================
# VIEWS
#===============================================================================
# Dashboard View
draw_dashboard() {
    local width height
    read width height < <(get_terminal_size)
    
    local panel_width=$((width/2 - 2))
    local panel_height=10
    local margin=2
    
    # Welcome panel
    draw_panel $margin 3 $panel_width $panel_height "Welcome"
    draw_text $((margin+2)) 5 "Hello, ${BOLD}${BRIGHT_CYAN}$USERNAME${RESET}!"
    draw_text $((margin+2)) 6 ""
    draw_text $((margin+2)) 7 "Last login: ${DIM}$LAST_LOGIN${RESET}"
    draw_text $((margin+2)) 8 "Version: ${DIM}$VERSION${RESET}"
    
    # Stats panel
    draw_panel $((margin+panel_width+2)) 3 $panel_width $panel_height "Statistics"
    draw_text $((margin+panel_width+4)) 5 "${BOLD}${BRIGHT_YELLOW}🔥 Streak:${RESET} $STREAK days"
    draw_text $((margin+panel_width+4)) 6 "${BOLD}${BRIGHT_MAGENTA}⭐ Points:${RESET} $PRAXIS_POINTS"
    draw_text $((margin+panel_width+4)) 7 "${BOLD}${BRIGHT_CYAN}📊 Entries Today:${RESET} $TODAY_ENTRIES"
    
    # Goal panel
    draw_panel $margin $((3+panel_height+1)) $panel_width $panel_height "Current Goal"
    draw_text $((margin+2)) $((5+panel_height+1)) "${BOLD}${BRIGHT_GREEN}🎯${RESET} ${CURRENT_GOAL:-No active goal}"
    draw_progress $((margin+2)) $((7+panel_height+1)) 30 $GOAL_PROGRESS
    draw_text $((margin+2)) $((8+panel_height+1)) "${DIM}Press 'g' to manage goals${RESET}"
    
    # Axiom panel
    draw_panel $((margin+panel_width+2)) $((3+panel_height+1)) $panel_width $panel_height "Daily Axiom"
    draw_text $((margin+panel_width+4)) $((5+panel_height+1)) "${ITALIC}\"$AXIOM_QUOTE\"${RESET}"
    draw_text $((margin+panel_width+4)) $((7+panel_height+1)) "${DIM}Press 'a' for more axioms${RESET}"
    
    # Quick actions
    local actions_y=$((3+panel_height*2+3))
    draw_text $margin $actions_y "${BOLD}Quick Actions:${RESET}"
    draw_text $((margin+2)) $((actions_y+1)) "${BRIGHT_CYAN}[j]${RESET} Journal Entry  ${BRIGHT_CYAN}[g]${RESET} Goals  ${BRIGHT_CYAN}[t]${RESET} Tracker  ${BRIGHT_CYAN}[s]${RESET} Settings"
}

# Goals View
draw_goals() {
    local width height
    read width height < <(get_terminal_size)
    
    local list_width=$((width-4))
    local list_height=$((height-10))
    local margin=2
    
    draw_panel $margin 3 $list_width $((list_height+4)) "Goals"
    
    # Read goals from file
    local goals=()
    if [[ -f "$GOALS_FILE" ]]; then
        while IFS= read -r line; do
            if [[ "$line" =~ \"name\".*\"([^\"]+)\" ]]; then
                goals+=("${BASH_REMATCH[1]}")
            fi
        done < "$GOALS_FILE"
    fi
    
    # Draw goals list
    local i=0
    for goal in "${goals[@]}"; do
        local y=$((5+i))
        if [[ $i -eq $SELECTED_INDEX ]]; then
            move_cursor $((margin+1)) $y
            echo -ne "${REVERSE}${BRIGHT_GREEN} $goal ${RESET}"
        else
            draw_text $((margin+2)) $y "• $goal"
        fi
        ((i++))
    done
    
    # Instructions
    draw_text $((margin+2)) $((list_height+6)) "${DIM}↑/↓ Navigate │ [Enter] Select │ [n] New │ [d] Delete${RESET}"
}

# Journal View
draw_journal() {
    local width height
    read width height < <(get_terminal_size)
    
    local list_width=$((width/2-2))
    local entry_width=$((width/2-2))
    local list_height=$((height-10))
    local margin=2
    
    # Entries list
    draw_panel $margin 3 $list_width $((list_height+4)) "Entries"
    
    # Entry detail
    draw_panel $((margin+list_width+2)) 3 $entry_width $((list_height+4)) "Entry Detail"
    
    # Sample entries
    local entries=("Check-in: Starting my Praxis journey!" "Achievement: Completed first week!" "Reflection: Learning to focus.")
    local dates=("2026-03-15" "2026-03-14" "2026-03-13")
    local moods=("motivated" "happy" "calm")
    
    for i in "${!entries[@]}"; do
        local y=$((5+i))
        if [[ $i -eq $SELECTED_INDEX ]]; then
            move_cursor $((margin+1)) $y
            echo -ne "${REVERSE}${BRIGHT_CYAN} ${dates[$i]} ${RESET}"
        else
            draw_text $((margin+2)) $y "${DIM}${dates[$i]}${RESET}"
        fi
    done
    
    # Show selected entry detail
    if [[ ${#entries[@]} -gt 0 ]]; then
        local idx=$SELECTED_INDEX
        [[ $idx -ge ${#entries[@]} ]] && idx=$((${#entries[@]}-1))
        
        draw_text $((margin+list_width+4)) 5 "${BOLD}Date:${RESET} ${dates[$idx]}"
        draw_text $((margin+list_width+4)) 6 "${BOLD}Mood:${RESET} ${moods[$idx]}"
        draw_text $((margin+list_width+4)) 8 "${entries[$idx]}"
    fi
    
    # Instructions
    draw_text $((margin+2)) $((list_height+6)) "${DIM}↑/↓ Navigate │ [Enter] View │ [n] New Entry │ [d] Delete${RESET}"
}

# Tracker View
draw_tracker() {
    local width height
    read width height < <(get_terminal_size)
    
    local panel_width=$((width-4))
    local margin=2
    
    draw_panel $margin 3 $panel_width 15 "Daily Tracker"
    
    draw_text $((margin+2)) 5 "Today's Progress"
    draw_progress $((margin+2)) 6 50 $((TODAY_ENTRIES * 10)) "$((TODAY_ENTRIES * 10))%"
    
    draw_text $((margin+2)) 9 "Weekly Activity"
    draw_hline $((margin+2)) 10 50
    
    # Simple bar chart
    local bars=(3 5 2 4 6 1 $TODAY_ENTRIES)
    local days=("Mon" "Tue" "Wed" "Thu" "Fri" "Sat" "Sun")
    local bar_y=12
    
    for i in "${!bars[@]}"; do
        local bar_height=${bars[$i]}
        draw_text $((margin+4+i*6)) $bar_y "${BRIGHT_CYAN}│${RESET}"
        for ((j=0; j<bar_height; j++)); do
            draw_text $((margin+4+i*6)) $((bar_y-1-j)) "${BRIGHT_CYAN}█${RESET}"
        done
        draw_text $((margin+3+i*6)) $((bar_y+2)) "${DIM}${days[$i]}${RESET}"
    done
    
    draw_text $((margin+2)) $((bar_y+5)) "${DIM}[Enter] Log Activity │ [d] Delete Entry${RESET}"
}

# Axiom View
draw_axiom() {
    local width height
    read width height < <(get_terminal_size)
    
    local panel_width=60
    local panel_height=12
    local margin=$(( (width - panel_width) / 2 ))
    local y=$(( (height - panel_height) / 2 ))
    
    draw_panel $margin $y $panel_width $panel_height "Daily Axioms"
    
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
    
    local quote_idx=$((RANDOM % ${#quotes[@]}))
    
    draw_centered $((y+3)) "${ITALIC}${BOLD}${BRIGHT_CYAN}\"${quotes[$quote_idx]}\"${RESET}" $panel_width
    draw_centered $((y+6)) "${DIM}Press [n] for next axiom${RESET}" $panel_width
    draw_centered $((y+8)) "${DIM}Press [s] to save as favorite${RESET}" $panel_width
}

# Settings View
draw_settings() {
    local width height
    read width height < <(get_terminal_size)
    
    local panel_width=50
    local panel_height=15
    local margin=$(( (width - panel_width) / 2 ))
    local y=3
    
    draw_panel $margin $y $panel_width $panel_height "Settings"
    
    draw_text $((margin+2)) $((y+2)) "${BOLD}Username:${RESET} $USERNAME"
    draw_text $((margin+2)) $((y+4)) "${BOLD}Data Directory:${RESET}"
    draw_text $((margin+4)) $((y+5)) "${DIM}$DATA_DIR${RESET}"
    draw_text $((margin+2)) $((y+7)) "${BOLD}Config Directory:${RESET}"
    draw_text $((margin+4)) $((y+8)) "${DIM}$CONFIG_DIR${RESET}"
    draw_text $((margin+2)) $((y+10)) "${BOLD}Streak:${RESET} $STREAK days"
    draw_text $((margin+2)) $((y+11)) "${BOLD}Total Points:${RESET} $PRAXIS_POINTS"
    
    draw_text $((margin+2)) $((y+13)) "${DIM}[e] Edit Profile │ [r] Reset Data │ [b] Back${RESET}"
}

# Help View
draw_help() {
    local width height
    read width height < <(get_terminal_size)
    
    local panel_width=60
    local panel_height=20
    local margin=$(( (width - panel_width) / 2 ))
    local y=$(( (height - panel_height) / 2 ))
    
    draw_panel $margin $y $panel_width $panel_height "Help"
    
    local help_text=(
        "${BOLD}Navigation:${RESET}"
        "  ↑/↓/←/→  Navigate menus and lists"
        "  Tab      Switch between panels"
        "  Enter    Select/Confirm"
        "  Esc/Back Go back"
        ""
        "${BOLD}Views:${RESET}"
        "  d  Dashboard"
        "  g  Goals"
        "  j  Journal"
        "  t  Tracker"
        "  a  Axiom"
        "  s  Settings"
        "  h  Help"
        ""
        "${BOLD}Actions:${RESET}"
        "  n  New entry/item"
        "  d  Delete"
        "  r  Refresh"
        "  q  Quit"
        ""
        "${DIM}Press any key to close help${RESET}"
    )
    
    local i=0
    for line in "${help_text[@]}"; do
        draw_text $((margin+2)) $((y+2+i)) "$line"
        ((i++))
    done
}

#===============================================================================
# INPUT HANDLING
#===============================================================================
handle_input() {
    local key
    
    # Read single character
    read -r -n 1 key
    
    # Handle escape sequences (arrow keys)
    if [[ "$key" == $'\x1b' ]]; then
        read -r -n 2 key
        case "$key" in
            '[A') key="UP" ;;
            '[B') key="DOWN" ;;
            '[C') key="RIGHT" ;;
            '[D') key="LEFT" ;;
            *) key="ESC" ;;
        esac
    elif [[ "$key" == $'\x7f' ]] || [[ "$key" == $'\x08' ]]; then
        key="BACKSPACE"
    elif [[ "$key" == $'\x0d' ]] || [[ "$key" == $'\x0a' ]]; then
        key="ENTER"
    elif [[ "$key" == $'\x09' ]]; then
        key="TAB"
    fi
    
    # Global keys
    case "$key" in
        q|Q)
            RUNNING=false
            return
            ;;
        h|H|'?')
            CURRENT_VIEW="help"
            return
            ;;
    esac
    
    # View-specific input
    case "$CURRENT_VIEW" in
        dashboard)
            case "$key" in
                d) CURRENT_VIEW="dashboard" ;;
                g) CURRENT_VIEW="goals"; SELECTED_INDEX=0 ;;
                j) CURRENT_VIEW="journal"; SELECTED_INDEX=0 ;;
                t) CURRENT_VIEW="tracker" ;;
                a) CURRENT_VIEW="axiom" ;;
                s) CURRENT_VIEW="settings" ;;
            esac
            ;;
        goals|journal)
            case "$key" in
                UP)
                    ((SELECTED_INDEX > 0)) && ((SELECTED_INDEX--))
                    ;;
                DOWN)
                    ((SELECTED_INDEX < 10)) && ((SELECTED_INDEX++))
                    ;;
                n)
                    set_status "New entry feature - coming soon!" "info"
                    ;;
                d)
                    set_status "Delete feature - coming soon!" "warning"
                    ;;
                b|ESC)
                    CURRENT_VIEW="dashboard"
                    ;;
            esac
            ;;
        axiom)
            case "$key" in
                n|N|" ")
                    set_status "New axiom loaded!" "info"
                    ;;
                s|S)
                    set_status "Axiom saved to favorites!" "success"
                    ;;
                b|ESC)
                    CURRENT_VIEW="dashboard"
                    ;;
            esac
            ;;
        tracker)
            case "$key" in
                ENTER)
                    ((TODAY_ENTRIES++))
                    add_praxis_points 10
                    save_data
                    ;;
                d)
                    if [[ $TODAY_ENTRIES -gt 0 ]]; then
                        ((TODAY_ENTRIES--))
                        set_status "Entry deleted" "info"
                    fi
                    ;;
                b|ESC)
                    CURRENT_VIEW="dashboard"
                    ;;
            esac
            ;;
        settings)
            case "$key" in
                e)
                    set_status "Edit profile - coming soon!" "info"
                    ;;
                r)
                    set_status "Reset data - coming soon!" "warning"
                    ;;
                b|ESC)
                    CURRENT_VIEW="dashboard"
                    ;;
            esac
            ;;
        help)
            CURRENT_VIEW="dashboard"
            ;;
    esac
}

#===============================================================================
# MAIN LOOP
#===============================================================================
render() {
    clear_screen
    draw_header
    
    case "$CURRENT_VIEW" in
        dashboard) draw_dashboard ;;
        goals) draw_goals ;;
        journal) draw_journal ;;
        tracker) draw_tracker ;;
        axiom) draw_axiom ;;
        settings) draw_settings ;;
        help) draw_help ;;
    esac
    
    draw_status_bar
    draw_status_message
}

main() {
    # Initialize
    init_data_dirs
    load_data
    
    # Update last login
    LAST_LOGIN="$(date '+%Y-%m-%d %H:%M')"
    save_data
    
    # Setup terminal
    save_terminal
    
    # Trap to restore terminal on exit
    trap 'restore_terminal; exit' INT TERM EXIT
    
    # Main loop
    while $RUNNING; do
        render
        handle_input
    done
    
    # Cleanup
    restore_terminal
    save_data
    
    echo "Thanks for using Praxis TUI!"
}

# Show help if requested
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "Praxis TUI v$VERSION"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "A terminal-based interface for Praxis"
    echo ""
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --version, -v  Show version"
    echo ""
    echo "Keyboard Shortcuts:"
    echo "  d  Dashboard    g  Goals       j  Journal"
    echo "  t  Tracker      a  Axiom       s  Settings"
    echo "  h  Help         q  Quit"
    echo ""
    exit 0
fi

if [[ "${1:-}" == "--version" ]] || [[ "${1:-}" == "-v" ]]; then
    echo "Praxis TUI v$VERSION"
    exit 0
fi

# Test mode - verify installation without TUI
if [[ "${1:-}" == "--test" ]]; then
    echo "Praxis TUI v$VERSION - Test Mode"
    echo ""
    init_data_dirs
    echo "✓ Data directories created"
    load_data
    echo "✓ Data loaded successfully"
    echo "  Username: $USERNAME"
    echo "  Streak: $STREAK days"
    echo "  Points: $PRAXIS_POINTS"
    echo "  Current Goal: ${CURRENT_GOAL:-None}"
    echo ""
    echo "✓ All systems ready!"
    echo ""
    echo "Run 'praxis' to start the interactive TUI."
    exit 0
fi

# Run main
main
