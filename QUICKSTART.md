# Quick Start - Praxis CLI

## Run Immediately (No Installation)

```bash
cd /home/gio/Praxis/praxis_cli
./praxis-simple.sh
```

## Install System-Wide

```bash
cd /home/gio/Praxis/praxis_cli
sudo ./install.sh
```

Then run from anywhere:
```bash
praxis
```

## Login

When you start Praxis, you'll see the login screen:

**Default Accounts:**
| Username | Password |
|----------|----------|
| admin    | admin    |
| user     | user     |

**Or press `r` to register a new account!**

## Keyboard Controls

Once logged in:

| Key | Action |
|-----|--------|
| `d` | Dashboard |
| `g` | Goals |
| `j` | Journal |
| `t` | Tracker (press Enter to log activity) |
| `a` | Axiom |
| `s` | Settings |
| `l` | Login |
| `o` | Logout |
| `r` | Register new account |
| `h` | Help |
| `q` | Quit |
| `b` | Back |

## Example Session

```bash
# Start Praxis
./praxis-simple.sh

# Login screen appears
# Enter: admin
# Password: admin (hidden)

# You'll see the Dashboard with:
# - Your streak and points
# - Current goal with progress
# - Daily axiom

# Press 't' to go to Tracker
# Press 'Enter' to log an activity (earns 10 points!)

# Press 'g' to view Goals
# Use navigation keys

# Press 'j' to view Journal entries

# Press 'o' to logout when done
# Press 'q' to quit
```

## Session Persistence

Praxis remembers your login session. When you restart:
- If you were logged in, you'll be automatically logged back in
- Your data is saved per user
- Multiple users can have separate data

## Your Data

All data is stored locally:
- `~/.local/share/praxis/` - Your data files
- `~/.local/share/praxis/user_<username>.json` - Your personal data
- `~/.local/share/praxis/users.json` - User accounts

No internet required. No accounts needed.
