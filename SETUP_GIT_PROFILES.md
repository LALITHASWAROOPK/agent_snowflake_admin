# Git Profile Setup Guide - Two GitHub Accounts

## Step 1: Generate SSH Keys for Both Accounts

```powershell
# Generate SSH key for ltangudu account
ssh-keygen -t ed25519 -C "ltangudu@github.com" -f ~/.ssh/id_ed25519_ltangudu

# Generate SSH key for LALITHASWAROOPK account
ssh-keygen -t ed25519 -C "lalithaswaroop@github.com" -f ~/.ssh/id_ed25519_lalitha
```

(Press Enter when prompted for passphrase, or set one for extra security)

## Step 2: Add SSH Keys to SSH Agent

```powershell
# Start SSH agent
Start-Service ssh-agent

# Add both keys
ssh-add ~/.ssh/id_ed25519_ltangudu
ssh-add ~/.ssh/id_ed25519_lalitha
```

## Step 3: Add Public Keys to GitHub

Copy each public key and add to the respective GitHub account:

```powershell
# Copy ltangudu's public key
Get-Content ~/.ssh/id_ed25519_ltangudu.pub | Set-Clipboard
# Go to: https://github.com/settings/keys (logged in as ltangudu)
# Click "New SSH key" and paste

# Copy LALITHASWAROOPK's public key
Get-Content ~/.ssh/id_ed25519_lalitha.pub | Set-Clipboard
# Go to: https://github.com/settings/keys (logged in as LALITHASWAROOPK)
# Click "New SSH key" and paste
```

## Step 4: Create SSH Config File

Create `~/.ssh/config`:

```
# ltangudu account (default)
Host github.com-ltangudu
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_ltangudu

# LALITHASWAROOPK account
Host github.com-lalitha
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_lalitha
```

## Step 5: Update This Repository's Remote URL

```powershell
# Change from HTTPS to SSH for LALITHASWAROOPK account
git remote set-url origin git@github.com-lalitha:LALITHASWAROOPK/agent_snowflake_admin.git

# Configure local git identity for this repo
git config user.name "LALITHASWAROOPK"
git config user.email "lalithaswaroop@github.com"
```

## Step 6: Test the Connection

```powershell
# Test connection with LALITHASWAROOPK account
ssh -T git@github.com-lalitha
# Should see: "Hi LALITHASWAROOPK! You've successfully authenticated..."
```

## Step 7: Push Your Changes

```powershell
git push origin main
```

## Future Usage

### For LALITHASWAROOPK Repositories:
```powershell
git clone git@github.com-lalitha:LALITHASWAROOPK/repo-name.git
cd repo-name
git config user.name "LALITHASWAROOPK"
git config user.email "lalithaswaroop@github.com"
```

### For ltangudu Repositories:
```powershell
git clone git@github.com-ltangudu:ltangudu/repo-name.git
cd repo-name
git config user.name "ltangudu"
git config user.email "ltangudu@github.com"
```

## Quick Fix for This Repository

Run these commands now:

```powershell
# 1. Generate keys (follow prompts)
ssh-keygen -t ed25519 -C "lalithaswaroop@github.com" -f ~/.ssh/id_ed25519_lalitha

# 2. Start SSH agent and add key
Start-Service ssh-agent
ssh-add ~/.ssh/id_ed25519_lalitha

# 3. Copy public key to add to GitHub
Get-Content ~/.ssh/id_ed25519_lalitha.pub | Set-Clipboard
Write-Host "Public key copied! Add it to https://github.com/settings/keys (logged in as LALITHASWAROOPK)"
```

After adding the key to GitHub, continue with steps 4-7 above.
