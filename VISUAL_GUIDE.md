# Praxis CLI - Visual Guide

## What You See When Running

### 1. Login Screen (First Run - Offline Mode)

```
╔════════════════════════════════════════════════════════════════════╗
║                    PRAXIS CLI - Goal-Aligned Social OS              ║
╚════════════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│         Welcome to Praxis CLI - Goal-Aligned Social OS          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

  ⚠ Offline Mode - Local accounts only
  Default accounts:
    Username: admin  Password: admin
    Username: user   Password: user

──────────────────────────────────────────────────────────────────────

  Username: _
```

### 2. Login Screen (Online Mode - API Configured)

```
╔════════════════════════════════════════════════════════════════════╗
║                    PRAXIS CLI - Goal-Aligned Social OS              ║
╚════════════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│         Welcome to Praxis CLI - Goal-Aligned Social OS          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

  ✓ Online Mode - Connected to Praxis API
  Enter your Praxis account credentials

──────────────────────────────────────────────────────────────────────

  Username/Email: _
```

### 3. Main Dashboard

```
╔════════════════════════════════════════════════════════════════════╗
║                    PRAXIS CLI - Goal-Aligned Social OS              ║
╚════════════════════════════════════════════════════════════════════╝

  ✓ Online | Logged in as: gio

  ┌─────────────────────────────┐   ┌─────────────────────────────┐
  │ Welcome                     │   │ Statistics                  │
  │                             │   │                             │
  │ Hello, gio                  │   │ 🔥 Streak: 5 days           │
  │                             │   │ ⭐ Points: 150              │
  │ Last login: 2026-03-18      │   │ 📊 Entries Today: 3         │
  │ Version: 1.0.0              │   │                             │
  └─────────────────────────────┘   └─────────────────────────────┘

  ┌─────────────────────────────┐   ┌─────────────────────────────┐
  │ Current Goal                │   │ Daily Axiom                 │
  │                             │   │                             │
  │ 🎯 Learn Kotlin             │   │ "Progress is real."         │
  │ [████████████░░░░░░░] 45%   │   │                             │
  │                             │   │ Press 'a' for more axioms   │
  └─────────────────────────────┘   └─────────────────────────────┘

  Quick Actions:
  [j] Journal Entry  [g] Goals  [t] Tracker  [s] Settings

──────────────────────────────────────────────────────────────────────
Commands: d=Dashboard g=Goals j=Journal t=Tracker a=Axiom s=Settings
          h=Help o=Logout q=Quit
praxis> _
```

### 4. Goals View

```
╔════════════════════════════════════════════════════════════════════╗
║                    PRAXIS CLI - Goal-Aligned Social OS              ║
╚════════════════════════════════════════════════════════════════════╝

Your Goals:

──────────────────────────────────────────────────────────────────────

  1. Learn Kotlin
  2. Daily exercise
  3. Read more books
  4. Build Praxis CLI

──────────────────────────────────────────────────────────────────────
Press n to add goal, d to delete, b to go back
praxis/goals> _
```

### 5. Tracker View

```
╔════════════════════════════════════════════════════════════════════╗
║                    PRAXIS CLI - Goal-Aligned Social OS              ║
╚════════════════════════════════════════════════════════════════════╝

Activity Tracker

──────────────────────────────────────────────────────────────────────

  Today's entries: 3

  Press ENTER to log an activity (+10 points)

──────────────────────────────────────────────────────────────────────
Press b to go back
praxis/tracker> _
```

### 6. Settings View

```
╔════════════════════════════════════════════════════════════════════╗
║                    PRAXIS CLI - Goal-Aligned Social OS              ║
╚════════════════════════════════════════════════════════════════════╝

Settings

──────────────────────────────────────────────────────────────────────

  Username:     gio
  Data Dir:     /home/gio/.local/share/praxis
  Mode:         Online
  API URL:      https://praxis-api.herokuapp.com
  Streak:       5 days
  Total Points: 150

──────────────────────────────────────────────────────────────────────
Press b to go back
praxis/settings> _
```

### 7. Help Screen

```
╔════════════════════════════════════════════════════════════════════╗
║                    PRAXIS CLI - Goal-Aligned Social OS              ║
╚════════════════════════════════════════════════════════════════════╝

Help - Keyboard Shortcuts

──────────────────────────────────────────────────────────────────────

  Navigation:
    d  Dashboard
    g  Goals
    j  Journal
    t  Tracker
    a  Axiom
    s  Settings

  Actions:
    h  Help
    b  Back
    o  Logout
    q  Quit

──────────────────────────────────────────────────────────────────────
Press any key to continue...
```

## Color Legend

| Color | Meaning |
|-------|---------|
| 🟦 Blue (Cyan) | Headers, titles |
| 🟩 Green | Success, online status |
| 🟨 Yellow | Warnings, offline status |
| 🟪 Magenta | Points, highlights |
| ⬜ White | Regular text |
| ⬛ Dim | Secondary info, help text |

## Keyboard Controls Summary

### Global
- `q` - Quit
- `h` - Help

### Navigation
- `d` - Dashboard
- `g` - Goals
- `j` - Journal
- `t` - Tracker
- `a` - Axiom
- `s` - Settings

### Actions
- `l` - Login
- `o` - Logout
- `r` - Register
- `b` - Back
- `Enter` - Confirm/Log activity

## Example Session Flow

```
1. Run: ./praxis-simple.sh
   ↓
2. Login screen appears
   ↓
3. Enter credentials (admin/admin)
   ↓
4. Dashboard shows
   ↓
5. Press 't' for Tracker
   ↓
6. Press Enter to log activity (+10 points)
   ↓
7. Press 'b' to go back
   ↓
8. Dashboard shows updated points
   ↓
9. Press 'g' for Goals
   ↓
10. Browse goals
    ↓
11. Press 'b' to go back
    ↓
12. Press 'o' to logout
    ↓
13. Press 'q' to quit
```

## Installation Visual

```bash
# Clone/navigate to directory
cd /home/gio/Praxis/praxis_cli

# Make executable
chmod +x *.sh

# Optional: Install system-wide
sudo ./install.sh

# Run
./praxis-simple.sh

# Or from anywhere (after install)
praxis
```

## Config Setup Visual

```bash
# Create config directory
mkdir -p ~/.config/praxis

# Create config file
cat > ~/.config/praxis/config.json << 'EOF'
{
    "api_url": "https://praxis-api.herokuapp.com",
    "supabase_url": "https://xyz.supabase.co",
    "supabase_anon_key": "eyJhbGc..."
}
EOF

# Run - will auto-detect online mode
./praxis-simple.sh
```

## Online vs Offline Visual

```
┌─────────────────────────────────────────────────────────────┐
│                    OFFLINE MODE                             │
├─────────────────────────────────────────────────────────────┤
│  ⚠ Offline | Logged in as: admin                            │
│                                                             │
│  Data: Local JSON files                                     │
│  Auth: Local username/password                              │
│  Sync: None                                                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                     ONLINE MODE                             │
├─────────────────────────────────────────────────────────────┤
│  ✓ Online | Logged in as: gio                               │
│                                                             │
│  Data: Supabase Database                                    │
│  Auth: Supabase JWT                                         │
│  Sync: Real-time                                            │
└─────────────────────────────────────────────────────────────┘
```

---

**Praxis CLI** - Beautiful terminal interface for your goals.
