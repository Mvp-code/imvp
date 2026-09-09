---
name: mvpx-git-sync
description: >-
  Fully automate Git sync for MVPx to github.com/Mvp-code/imvp. After any
  code/JSP/SQL/config change, commit and push to origin/main without waiting
  to be asked. Also when the user says sync, commit, push, save to git, or version.
---

# MVPx Git Sync (automated → GitHub)

Remote (fixed): `https://github.com/Mvp-code/imvp.git`  
Repo root: `C:\Program Files\Apache Software Foundation\Tomcat 9.0\webapps\MVPx`  
Branch: `main`

## When (automatic)

Run at the **end of every turn** where you created, edited, or deleted project files.
Do not wait for the user to ask. Also run on explicit: sync / commit / push / save to git / version.

## Procedure (no prompts)

```powershell
cd "C:\Program Files\Apache Software Foundation\Tomcat 9.0\webapps\MVPx"
git status -sb
git diff
git diff --cached
git log -5 --oneline
```

1. Ensure `origin` is `https://github.com/Mvp-code/imvp.git`. If missing:  
   `git remote add origin https://github.com/Mvp-code/imvp.git`  
   Never replace a different existing remote without asking.
2. **Secret scan before stage** — refuse to commit if these appear in the diff:  
   Twilio `AC…` SIDs, auth tokens, `.env`, `META-INF/context*.xml`, `*credential*`, `google-drive-sa.json`, private keys.  
   Load Twilio from Admin Configuration / env — never hardcode.
3. Stage intentional paths (prefer explicit adds). Respect `.gitignore`.
4. If nothing to commit, skip commit (no empty commits).
5. Commit (PowerShell):

```powershell
git commit -m @"
Why-focused one-line summary of this change set.
"@
```

6. **Always push** when a commit was made (or when ahead of origin):

```powershell
git push -u origin main
```

7. On auth failure: tell the user once to sign in to GitHub for this machine. Do not invent tokens or change `git config`.
8. On push-protection (secrets): scrub files, rewrite/amend only if safe per commit rules, then push again. Never force-push `main` unless the user explicitly asks.

## Hard limits

- No `git config` changes
- No force-push / hard reset unless user explicitly requests
- No secrets in commits
- No empty commits
- Do not create a second remote if `origin` already points elsewhere — ask first
