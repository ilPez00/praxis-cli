# Praxis CLI/TUI Client

A beautiful terminal-based interface for Praxis - the Goal-Aligned Social Operating System.

**Now with Webapp Integration!** Connect to your Praxis webapp backend for real-time sync, or use offline mode for local-only operation.

## Features

- **Dual Mode Operation** - Online (webapp sync) or Offline (local-only)
- **User Login System** - Supabase auth or local accounts
- **Dashboard** - View your streak, Praxis Points, and current goal
- **Goals Tracking** - Manage and track goals with progress bars
- **Journal** - Log daily entries, reflections, and achievements
- **Activity Tracker** - Visual tracker for daily activities
- **Daily Axioms** - Inspirational quotes
- **Settings** - Configure your experience
- **Keyboard Navigation** - Fast, keyboard-driven interface

## Modes of Operation

### Online Mode (Recommended)

Connects to your Praxis webapp backend for:
- Real-time data sync
- Cloud backup
- Multi-device access
- Full webapp integration

**Requirements:**
- Praxis webapp deployment (Railway, Heroku, etc.)
- Supabase project credentials

### Offline Mode

Local-only operation:
- No internet required
- Data stored locally
- Perfect for travel/offline use
- Default mode

## Default Accounts (Offline Mode)

| Username | Password |
|----------|----------|
| admin    | admin    |
| user     | user     |

**Or register a new account!**

## Screenshots

```
╔══════════════════════════════════════════════════════════════════════════════╗
 PRAXIS TUI                                                  Goal-Aligned Social Operating System
────────────────────────────────────────────────────────────────────────────────

  ┌─────────────────────────────┐   ┌─────────────────────────────┐
  │ Welcome                     │   │ Statistics                  │
  │                             │   │                             │
  │ Hello, User!                │   │ 🔥 Streak: 5 days           │
  │                             │   │ ⭐ Points: 150              │
  │ Last login: 2026-03-16      │   │ 📊 Entries Today: 3         │
  │ Version: 1.0.0              │   │                             │
  └─────────────────────────────┘   └─────────────────────────────┘

  ┌─────────────────────────────┐   ┌─────────────────────────────┐
  │ Current Goal                │   │ Daily Axiom                 │
  │                             │   │                             │
  │ 🎯 Learn a new skill        │   │ "Progress is real."         │
  │ [████████░░░░░░░░░░░] 45%   │   │                             │
  │                             │   │ Press 'a' for more axioms   │
  └─────────────────────────────┘   └─────────────────────────────┘

  Quick Actions:
  [j] Journal Entry  [g] Goals  [t] Tracker  [s] Settings

────────────────────────────────────────────────────────────────────────────────
 View: dashboard │ Press 'q' to quit │ 'h' for help │ Praxis TUI v1.0.0       
```

## Installation

### Quick Install

```bash
cd /home/gio/Praxis/praxis_cli
./praxis-simple.sh
```

### System-wide Installation

```bash
# Copy to system location
sudo cp praxis-simple.sh /usr/local/bin/praxis
sudo chmod +x /usr/local/bin/praxis

# Run from anywhere
praxis
```

### Create Desktop Shortcut (Optional)

```bash
cat > ~/.local/share/applications/praxis-tui.desktop << EOF
[Desktop Entry]
Name=Praxis TUI
Comment=Terminal-based Praxis Client
Exec=gnome-terminal -- praxis
Icon=utilities-terminal
Type=Application
Categories=Utility;Productivity;
Terminal=true
EOF
```

## Usage

### Starting the Application

```bash
./praxis-simple.sh
```

### Command Line Options

```bash
# Show help
./praxis-simple.sh --help

# Show version
./praxis-simple.sh --version

# Test installation
./praxis-simple.sh --test
```

### Keyboard Shortcuts

#### Global

| Key | Action |
|-----|--------|
| `q` | Quit application |
| `h` | Show help |
| `l` | Login |
| `o` | Logout |
| `r` | Register new account |

#### Views

| Key | View |
|-----|------|
| `d` | Dashboard |
| `g` | Goals |
| `j` | Journal |
| `t` | Tracker |
| `a` | Axiom |
| `s` | Settings |
| `b` | Back |

#### Actions

| Key | Action |
|-----|--------|
| `n` | New entry/item |
| `Enter` (in Tracker) | Log activity (+10 points) |

## Data Storage

All data is stored locally in JSON format:

```
~/.local/share/praxis/
├── praxis_data.json       # Guest/default user data
├── users.json             # User accounts (login credentials)
├── session.json           # Current login session
├── user_<username>.json   # Individual user data (per user)
├── goals.json             # Goals list
└── journal.json           # Journal entries
```

~/.config/praxis/
└── praxis_config.json  # Application configuration
```

### Data Format

**praxis_data.json:**
```json
{
    "username": "User",
    "streak": 5,
    "praxis_points": 150,
    "last_login": "2026-03-16T10:30:00",
    "current_goal": "Learn a new skill",
    "goal_progress": 45,
    "today_entries": 3,
    "axiom_quote": "Progress is real."
}
```

**goals.json:**
```json
{
    "goals": [
        {
            "id": 1,
            "name": "Learn a new skill",
            "progress": 45,
            "target": 100,
            "created": "2026-03-01",
            "status": "active"
        }
    ]
}
```

**journal.json:**
```json
{
    "entries": [
        {
            "id": 1,
            "date": "2026-03-15",
            "type": "checkin",
            "content": "Starting my Praxis journey!",
            "mood": "motivated"
        }
    ]
}
```

## Customization

### Change Color Scheme

Edit the color definitions at the top of `praxis-tui.sh`:

```bash
readonly BRIGHT_CYAN='\033[96m'  # Change this code
```

### Change Data Directory

Set environment variables before running:

```bash
export XDG_DATA_HOME=/custom/path
export XDG_CONFIG_HOME=/custom/config
./praxis-tui.sh
```

### Terminal Requirements

- **Minimum size:** 80x24 characters
- **Unicode support:** Required for box-drawing characters
- **256 colors:** Recommended for best appearance

## Troubleshooting

### Box characters not displaying correctly

Ensure your terminal supports UTF-8 and Unicode:

```bash
# Check locale
locale

# Should show UTF-8, e.g.:
# LANG=en_US.UTF-8
```

### Colors not displaying correctly

Ensure your terminal supports 256 colors:

```bash
echo $TERM
# Should be: xterm-256color or similar
```

### Terminal not restored after exit

If the terminal behaves strangely after exiting:

```bash
reset
```

Or the application should auto-restore on Ctrl+C.

### Data not persisting

Check file permissions:

```bash
ls -la ~/.local/share/praxis/
chmod 644 ~/.local/share/praxis/*.json
```

## Architecture

```
praxis-tui.sh
├── Configuration
│   ├── Paths and directories
│   ├── Color definitions
│   └── Global state
├── Terminal Control
│   ├── Screen buffer management
│   ├── Cursor control
│   └── Input mode handling
├── Data Management
│   ├── JSON file I/O
│   ├── Data initialization
│   └── State persistence
├── UI Drawing
│   ├── Box/panel rendering
│   ├── Text formatting
│   ├── Progress bars
│   └── Status messages
├── Views
│   ├── Dashboard
│   ├── Goals
│   ├── Journal
│   ├── Tracker
│   ├── Axiom
│   ├── Settings
│   └── Help
└── Main Loop
    ├── Input handling
    ├── State updates
    └── Rendering
```

## Development

### Running from Source

```bash
# Clone or navigate to the directory
cd /home/gio/Praxis/praxis_cli

# Make executable
chmod +x praxis-tui.sh

# Run
./praxis-tui.sh
```

### Debugging

Enable debug output by adding to the script:

```bash
set -x  # At the top of the script
```

### Testing Terminal Compatibility

```bash
# Test colors
for i in {0..255}; do
    printf "\x1b[38;5;%dmColor %3d\x1b[0m " $i $i
    (( (i+1) % 16 == 0 )) && echo
done
```

## Roadmap

- [ ] SQLite backend for better data management
- [ ] Sync with Praxis webapp
- [ ] More journal entry types
- [ ] Goal categories and tags
- [ ] Statistics and charts
- [ ] Export data (CSV, PDF)
- [ ] Themes and customization
- [ ] Plugin system
- [ ] Notifications/reminders

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

Proprietary - Praxis Project

## Support

- **Issues:** GitHub Issues
- **Documentation:** `praxis_cli/README.md`
- **Community:** Praxis Community Forums

---

**Praxis TUI** - Your goals, aligned in the terminal.
