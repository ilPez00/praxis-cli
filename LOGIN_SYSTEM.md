# Praxis CLI - Login System Implementation

## Overview

Added a complete user authentication system to the Praxis CLI/TUI client with:
- User login/logout
- Session persistence
- User registration
- Per-user data storage

## Features

### Login System
- **Login Screen** - Displays on first run or when not logged in
- **Default Accounts** - `admin/admin` and `user/user`
- **Session Persistence** - Remembers logged-in user between sessions
- **Password Input** - Hidden password entry (using `read -s`)

### User Registration
- **Create New Account** - Press `r` on login screen
- **Password Confirmation** - Validates password match
- **Auto-Login** - Automatically logs in after registration
- **Username Validation** - Prevents duplicate usernames

### Per-User Data
- **Separate Data Files** - Each user has `user_<username>.json`
- **Independent Progress** - Streak, points, goals per user
- **Session Management** - `session.json` tracks current user

## Files Modified

### `praxis-simple.sh`
Added functions:
- `check_session()` - Check for existing login session
- `save_session()` - Save current session to file
- `clear_session()` - Clear session on logout
- `show_login_screen()` - Display login UI
- `login()` - Handle user login
- `logout()` - Handle user logout
- `register_user()` - Create new user account

### Data Files Created
```
~/.local/share/praxis/
├── users.json           # User credentials
├── session.json         # Current session
└── user_<name>.json     # Per-user data
```

## Usage

### Login
```bash
./praxis-simple.sh
# Enter username: admin
# Enter password: admin
```

### Register New User
```bash
./praxis-simple.sh
# Press 'r' at login screen
# Enter new username
# Enter password
# Confirm password
```

### Logout
```
Press 'o' from dashboard
```

### Commands
| Key | Action |
|-----|--------|
| `l` | Login |
| `o` | Logout |
| `r` | Register |

## Security Notes

⚠️ **Warning**: This is a simple authentication system for local use only.
- Passwords are stored in plain text
- No encryption
- No password hashing
- Suitable for personal/local use only

For production use, consider:
- Password hashing (bcrypt, argon2)
- Encrypted storage
- Token-based authentication
- Server-side validation

## Session Flow

```
┌─────────────┐
│  Start App  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Check Session│
└──────┬──────┘
       │
   ┌───┴───┐
   │       │
   ▼       ▼
┌──────┐ ┌──────┐
│ Valid│ │ Invalid│
└──┬───┘ └───┬──┘
   │         │
   │         ▼
   │    ┌────────┐
   │    │ Login  │
   │    │ Screen │
   │    └───┬────┘
   │        │
   │    ┌───┴────┐
   │    │        │
   │    ▼        ▼
   │ ┌──────┐ ┌────────┐
   │ │Login │ │Register│
   │ └──┬───┘ └───┬────┘
   │    │         │
   │    └────┬────┘
   │         │
   ▼         ▼
┌────────────────┐
│  Load User Data│
└────────┬───────┘
         │
         ▼
┌────────────────┐
│  Main Loop     │
└────────────────┘
```

## Testing

```bash
# Test installation
./praxis-simple.sh --test

# Show help with login info
./praxis-simple.sh --help

# Run and login
./praxis-simple.sh
```

## Future Enhancements

- [ ] Password hashing
- [ ] Password reset
- [ ] Multiple sessions
- [ ] Session timeout
- [ ] User profiles
- [ ] Avatar/images
- [ ] Email verification (if online)
- [ ] Two-factor authentication
