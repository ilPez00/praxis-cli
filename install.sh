#!/bin/bash
#===============================================================================
# PRAXIS CLI INSTALLATION SCRIPT
# Installs the Praxis TUI client system-wide
#===============================================================================

set -e

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly INSTALL_DIR="/opt/praxis-cli"
readonly BIN_DIR="/usr/local/bin"

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

print_header() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║              PRAXIS CLI - Installation Script                     ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

install() {
    print_header
    
    print_step "Installing Praxis CLI to $INSTALL_DIR..."
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    
    # Copy files
    cp "$SCRIPT_DIR/praxis-simple.sh" "$INSTALL_DIR/praxis-tui.sh"
    cp "$SCRIPT_DIR/README.md" "$INSTALL_DIR/README.md" 2>/dev/null || true
    cp "$SCRIPT_DIR/QUICKSTART.md" "$INSTALL_DIR/QUICKSTART.md" 2>/dev/null || true
    
    # Make executable
    chmod +x "$INSTALL_DIR/praxis-tui.sh"
    
    # Create symlink
    ln -sf "$INSTALL_DIR/praxis-tui.sh" "$BIN_DIR/praxis"
    
    # Create data directories for user
    if [[ -n "$SUDO_USER" ]]; then
        local user_home
        user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
        
        mkdir -p "$user_home/.local/share/praxis"
        mkdir -p "$user_home/.config/praxis"
        
        chown -R "$SUDO_USER:$SUDO_USER" "$user_home/.local/share/praxis"
        chown -R "$SUDO_USER:$SUDO_USER" "$user_home/.config/praxis"
    fi
    
    print_success "Praxis CLI installed successfully!"
    echo ""
    echo -e "You can now run Praxis TUI by typing:"
    echo -e "  ${GREEN}praxis${NC}"
    echo ""
    echo -e "Or run the script directly:"
    echo -e "  ${GREEN}$INSTALL_DIR/praxis-tui.sh${NC}"
    echo ""
    echo -e "For help, run:"
    echo -e "  ${GREEN}praxis --help${NC}"
}

uninstall() {
    print_header
    
    print_warning "This will remove Praxis CLI from your system."
    read -p "Continue? (y/n): " -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_step "Uninstall cancelled"
        exit 0
    fi
    
    print_step "Removing Praxis CLI..."
    
    # Remove symlink
    rm -f "$BIN_DIR/praxis"
    
    # Remove installation directory
    rm -rf "$INSTALL_DIR"
    
    print_success "Praxis CLI uninstalled successfully!"
    echo ""
    print_warning "User data in ~/.local/share/praxis/ was preserved"
    echo "To remove it, run: rm -rf ~/.local/share/praxis ~/.config/praxis"
}

show_help() {
    echo "Praxis CLI Installation Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --install, -i    Install Praxis CLI (default)"
    echo "  --uninstall, -u  Uninstall Praxis CLI"
    echo "  --help, -h       Show this help message"
    echo ""
}

# Main
case "${1:-}" in
    --install|-i|"")
        check_root
        install
        ;;
    --uninstall|-u)
        check_root
        uninstall
        ;;
    --help|-h)
        show_help
        ;;
    *)
        print_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
