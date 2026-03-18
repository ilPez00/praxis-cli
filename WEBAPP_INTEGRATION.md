# Praxis CLI - Webapp Integration Guide

## Overview

The Praxis CLI can operate in two modes:

1. **Offline Mode** - Local-only data storage, no internet required
2. **Online Mode** - Connects to your Praxis Webapp backend for real-time sync

## Quick Start

### Offline Mode (Default)

```bash
cd /home/gio/Praxis/praxis_cli
./praxis-simple.sh
```

Login with default credentials:
- Username: `admin` / Password: `admin`
- Username: `user` / Password: `user`

### Online Mode

To connect to the Praxis webapp backend:

1. **Get your Supabase credentials** from your webapp deployment
2. **Create a config file** at `~/.config/praxis/config.json`
3. **Run the CLI** - it will automatically detect and use online mode

## Configuration

### Step 1: Get Supabase Credentials

From your Praxis Webapp deployment (Supabase Dashboard):

1. Go to: https://supabase.com/dashboard/project/YOUR_PROJECT/settings/api
2. Copy:
   - **Project URL** (e.g., `https://xyzcompany.supabase.co`)
   - **anon/public key** (starts with `eyJ...`)

⚠️ **Important**: Use the `anon` key, NOT the `service_role` key!

### Step 2: Create Config File

Create `~/.config/praxis/config.json`:

```bash
mkdir -p ~/.config/praxis
cat > ~/.config/praxis/config.json << 'EOF'
{
    "api_url": "https://your-praxis-api.herokuapp.com",
    "supabase_url": "https://xyzcompany.supabase.co",
    "supabase_anon_key": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
EOF
```

Or use environment variables:

```bash
export PRAXIS_API_URL="https://your-praxis-api.herokuapp.com"
export PRAXIS_SUPABASE_URL="https://xyzcompany.supabase.co"
export PRAXIS_SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### Step 3: Run and Login

```bash
./praxis-simple.sh
```

The login screen will show:
```
✓ Online Mode - Connected to Praxis API
Enter your Praxis account credentials
```

Enter your **Praxis webapp email and password**.

## Features Comparison

| Feature | Offline Mode | Online Mode |
|---------|-------------|-------------|
| **Authentication** | Local accounts | Supabase Auth |
| **Data Storage** | Local JSON files | Supabase Database |
| **Sync** | None | Real-time |
| **Internet Required** | No | Yes (for login) |
| **Multi-device** | No | Yes |
| **Data Persistence** | Local only | Cloud backup |

## API Endpoints Used

The CLI connects to these Praxis webapp API endpoints:

```
POST /auth/v1/token?grant_type=password  - Login
GET  /api/dashboard/summary              - Dashboard data
GET  /api/goals                          - Get goals
GET  /api/journal                        - Get journal entries
POST /api/checkin                        - Log check-in
```

## Commands

### TUI Mode (Interactive)

```bash
./praxis-simple.sh          # Launch interactive TUI
```

### API Mode (Command Line)

```bash
# Login
./praxis-api.sh login

# Get dashboard
./praxis-api.sh dashboard

# List goals
./praxis-api.sh goals

# List journal
./praxis-api.sh journal

# Log check-in
./praxis-api.sh checkin

# Logout
./praxis-api.sh logout

# Show status
./praxis-api.sh status
```

### Unified Entry Point

```bash
./praxis.sh                 # Launch TUI
./praxis.sh login           # API login
./praxis.sh dashboard       # Get dashboard JSON
./praxis.sh help            # Show all commands
```

## Session Management

### Session File

Location: `~/.local/share/praxis/session.json`

Contains:
```json
{
    "username": "your@email.com",
    "user_id": "uuid-from-supabase",
    "access_token": "jwt-token",
    "online_mode": true,
    "login_time": "2026-03-18 10:30"
}
```

### Session Persistence

- Sessions are automatically saved
- CLI remembers your login between runs
- Sessions expire after 1 hour (Supabase default)
- Auto-refresh on expiration

## Troubleshooting

### "Cannot connect to Praxis API"

1. Check your internet connection
2. Verify Supabase URL is correct
3. Ensure your webapp backend is running

### "Invalid or expired token"

1. Run `logout` and login again
2. Check if your Supabase anon key is valid
3. Verify your account exists in the webapp

### "Offline Mode" when expecting Online

1. Check config file exists: `~/.config/praxis/config.json`
2. Verify JSON syntax is correct
3. Test Supabase URL in browser

### Data Not Syncing

1. Ensure you're logged in with webapp credentials
2. Check `ONLINE_MODE=true` in session file
3. Verify API endpoints are accessible

## Local Development Setup

### Run Praxis Webapp Locally

```bash
cd /home/gio/Praxis/praxis_webapp
npm install
npm run dev
```

### Configure CLI for Local Dev

```bash
cat > ~/.config/praxis/config.json << 'EOF'
{
    "api_url": "http://localhost:3001",
    "supabase_url": "https://your-dev-supabase.supabase.co",
    "supabase_anon_key": "your-dev-anon-key"
}
EOF
```

### Test Connection

```bash
./praxis-api.sh status
```

## Production Deployment

### Railway/Heroku Deployment

1. Deploy Praxis webapp to Railway/Heroku
2. Get the deployed URL
3. Configure CLI with production URL

```bash
cat > ~/.config/praxis/config.json << EOF
{
    "api_url": "https://praxis-yourname.railway.app",
    "supabase_url": "https://your-prod.supabase.co",
    "supabase_anon_key": "prod-anon-key"
}
EOF
```

## Security Notes

### Token Storage

- Access tokens stored in `~/.local/share/praxis/session.json`
- Tokens expire after 1 hour
- Auto-refresh extends session

### Best Practices

1. **Never commit** config files to git
2. **Use environment variables** in shared environments
3. **Logout** on shared computers
4. **Keep anon key secret** - don't share publicly

## Data Models

### User Data (Online Mode)

Stored in Supabase tables:
- `users` - User profiles
- `goals` - Goal trees
- `journal_entries` - Journal entries
- `checkins` - Daily check-ins
- `points` - Praxis points history

### User Data (Offline Mode)

Stored in local JSON files:
- `~/.local/share/praxis/user_<username>.json`

## Architecture

```
┌─────────────────┐
│   Praxis CLI    │
│                 │
│  ┌───────────┐  │
│  │   TUI     │  │
│  │  Interface│  │
│  └─────┬─────┘  │
│        │        │
│  ┌─────▼─────┐  │
│  │ API Client│  │
│  └─────┬─────┘  │
└────────┼────────┘
         │
         │ HTTPS
         │
         ▼
┌─────────────────┐
│  Praxis Webapp  │
│    Backend      │
│                 │
│  ┌───────────┐  │
│  │  Supabase │  │
│  │   Auth    │  │
│  └───────────┘  │
└─────────────────┘
```

## Migration

### Offline → Online

1. Configure online mode
2. Login with webapp credentials
3. Data syncs automatically

### Online → Offline

1. Delete session file: `rm ~/.local/share/praxis/session.json`
2. Run CLI - uses offline mode
3. Create local account

## Support

- **Issues**: GitHub Issues
- **Documentation**: `praxis_cli/README.md`
- **Webapp Docs**: `praxis_webapp/docs/`

---

**Praxis CLI** - Your goals, aligned anywhere.
