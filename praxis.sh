#!/bin/bash
#===============================================================================
# PRAXIS CLI - Main Entry Point
# Unified CLI client with API integration
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/praxis-api.sh" 2>/dev/null || true

# If no arguments or TUI requested, run the simple TUI
if [[ $# -eq 0 ]] || [[ "${1:-}" == "tui" ]] || [[ "${1:-}" == "--tui" ]]; then
    if [[ -x "$SCRIPT_DIR/praxis-simple.sh" ]]; then
        exec "$SCRIPT_DIR/praxis-simple.sh"
    else
        echo "Error: praxis-simple.sh not found or not executable"
        exit 1
    fi
fi

# Otherwise handle API commands
case "${1:-}" in
    # TUI mode
    tui|--tui)
        exec "$SCRIPT_DIR/praxis-simple.sh"
        ;;
    
    # API commands
    login|logout|status|config|dashboard|goals|journal|checkin)
        # Source API client and run command
        source "$SCRIPT_DIR/praxis-api.sh"
        ;;
    
    # Help
    help|-h|--help)
        echo -e "\033[1mPraxis CLI\033[0m"
        echo ""
        echo "Usage: praxis [command]"
        echo ""
        echo "Commands:"
        echo "  (no args)   Launch interactive TUI"
        echo "  tui         Launch interactive TUI"
        echo "  login       Login to Praxis account (API)"
        echo "  logout      Logout from account"
        echo "  status      Show login status"
        echo "  config      Show/show configuration"
        echo "  dashboard   Get dashboard data (API)"
        echo "  goals       List goals (API)"
        echo "  journal     List journal entries (API)"
        echo "  checkin     Log daily check-in (API)"
        echo "  help        Show this help"
        echo ""
        echo "Examples:"
        echo "  praxis                    # Launch TUI"
        echo "  praxis login              # Login via API"
        echo "  praxis dashboard          # Get dashboard JSON"
        echo "  praxis checkin            # Log check-in"
        ;;
    
    *)
        echo "Unknown command: $1"
        echo "Run 'praxis help' for usage"
        exit 1
        ;;
esac
