---
track: capstone
level: 101
phase: 0
phase_name: primers
lesson: 01
title: "Git and GitHub"
time: 40 min
prerequisites: [none]
versions: { git: "2.28 or newer (needs git init -b and git switch)" }
verified: not yet run
source: capstones/platform/source/phase-0-primers/01-git-and-github/
assets: []
---

# 01. Git and GitHub

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- install Git and create a repository with `git init`, `git add` and `git commit`;
- make a branch, read a `git diff` and merge the branch back;
- push a repository to GitHub and clone the Code101 repository;
- explain why a file named `.env` must never be committed, and keep it out with `.gitignore`.

## Recap
None, this is the first primer. You only need a computer, a terminal and a text editor (Notepad or VS Code is fine).

## Why it matters
Think of a video game with save points. Before a hard level you save; if you fail, you load the save and nothing is lost. Git is a save-point system for a folder of files, and every save point (a **commit**) carries a short caption saying what changed. GitHub is a website that keeps a copy of your saves so you can share them, back them up, and download other people's projects. Every chapter of the platform capstone, and every later capstone, is delivered as a Git repository, so this is the first skill.

## What you will build
A tiny practice repository called `tasks-notes` with three commits, one branch that you merge, a `.gitignore` that hides a fake secret file, and a copy on GitHub. Then you clone the Code101 course repository to see where the capstone files live.

## Before you start
- A terminal. On Windows use **PowerShell** (press the Windows key, type `PowerShell`, press Enter). On macOS use **Terminal**. The text before `>` (Windows) or `$` (macOS and Linux) is the folder you are in.
- A text editor that saves plain text (Notepad, VS Code). Press Enter at the end of every line you type into a file, so the file ends with a new line.
- A free GitHub account (https://github.com/signup). You need it only in Step 9.
- Time: about 40 minutes. Everything is typed; nothing is installed except Git.
- Source pack (optional): every file is shown in full here. The finished files, the exercise starter and the solution are in the course repository https://github.com/Uee03/Code101 under `capstones/platform/source/phase-0-primers/01-git-and-github/` (you learn to clone it in Step 10).

## Steps
### Step 1. Install Git and say who you are
Check whether Git is already there:

**Terminal (any folder)**
```powershell
git --version
```
If you see a line like `git version 2.47.1.windows.1` (the numbers differ), skip to the identity commands below. If the terminal says the command is not found, install Git:

| System | Command |
|--------|---------|
| Windows 10 and 11 | `winget install --id Git.Git -e --source winget`, then close the terminal and open a new one |
| macOS | `git --version` offers to install the Apple command line tools; accept. Or `brew install git` if you use Homebrew |
| Debian and Ubuntu | `sudo apt install git` |
| Fedora | `sudo dnf install git` |

Git writes your name and e-mail into every commit, so tell it once. Use any name; the e-mail may be the private address GitHub shows in your settings.

**Terminal (any folder)**
```powershell
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
```
These commands print nothing when they work. The last one makes new repositories start on a branch called `main`.

### Step 2. Make a folder and turn it into a repository
A **repository** (repo) is a folder that Git watches, plus a hidden folder named `.git` where the save points live.

**Terminal (any folder where you keep projects)**
```powershell
mkdir tasks-notes
cd tasks-notes
git init -b main
```
Expected output (the path is yours; Git prints forward slashes even on Windows):
```text
Initialized empty Git repository in C:/Users/you/tasks-notes/.git/
```

### Step 3. Your first commit
Git has three places, like a photo studio: the **working folder** is the room where you arrange things, the **staging area** is the table where you put the things for the next photo, and the **commit** is the photo itself.

Create the file `team-notes.md` in the `tasks-notes` folder with these two lines:

**File: `team-notes.md` (first version)**
```markdown
# Team notes
- API port: 8000
```

Ask Git what it sees:

**Terminal (folder: `tasks-notes`)**
```powershell
git status
```
**Predict first:** will Git call the file *tracked* or *untracked*? It has never been added, so *untracked*. Expected output:
```text
On branch main

No commits yet

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        team-notes.md

nothing added to commit but untracked files present (use "git add" to track)
```
Put the file on the staging table, then take the photo:

**Terminal (folder: `tasks-notes`)**
```powershell
git add team-notes.md
git commit -m "Add team notes"
```
`-m` gives the caption in quotes. Expected output (the seven-character code `3f2a9c1` is the commit's id and will differ on your computer):
```text
[main (root-commit) 3f2a9c1] Add team notes
 1 file changed, 2 insertions(+)
 create mode 100644 team-notes.md
```
Look at the history:

**Terminal (folder: `tasks-notes`)**
```powershell
git log --oneline
```
```text
3f2a9c1 (HEAD -> main) Add team notes
```
`HEAD` means "where you are now"; `main` is the branch. One line per commit: id, then caption.

### Step 4. Keep secrets out: `.env.example`, `.env` and `.gitignore`
Real projects need passwords (for a database, for Keycloak). They live in a file named `.env`. **A `.env` file must never be committed**: Git remembers every file forever, and a repository on GitHub can be copied by anyone who sees it. The pattern used by the platform capstone is:

- `.env.example` is committed and holds **fake** example values, so a newcomer knows which settings exist.
- `.env` is a private copy with the real values and is listed in `.gitignore`, a file that tells Git which files to pretend not to see.

Create `.env.example` (this is the platform's file, character for character):

**File: `.env.example`**
```text
# Disposable local practice only. Never reuse these values for a real system.
POSTGRES_DB=tasksteams
POSTGRES_USER=tasks_admin
POSTGRES_PASSWORD=tasks_admin_local_only
POSTGRES_PORT=5432
KEYCLOAK_ADMIN=kcadmin
KEYCLOAK_ADMIN_PASSWORD=kcadmin_local_only
KEYCLOAK_PORT=8180
TASKS_NETWORK=tasksteams-net
```
The lines after `#` are a comment. Every other line is `NAME=value`. Make the private copy, as the platform README tells you to do (on macOS and Linux use `cp .env.example .env`):

**Terminal (folder: `tasks-notes`)**
```powershell
Copy-Item .env.example .env
git status --short
```
`--short` prints one line per file; `??` means untracked. Expected output:
```text
?? .env
?? .env.example
```
**Predict:** if you commit now with `git add .` (add everything), `.env` goes in. That is exactly the mistake to avoid. Create `.gitignore` first:

**File: `.gitignore`**
```text
.env
.deps/
.venv/
__pycache__/
```
Line 1 hides `.env`. The other three hide folders that Python tools create later (`.deps/`, `.venv/`, `__pycache__/`); a trailing `/` means "a folder".

**Terminal (folder: `tasks-notes`)**
```powershell
git status --short
```
`.env` has disappeared from the list. Expected output:
```text
?? .env.example
?? .gitignore
```
Ask Git to prove it (`check-ignore` prints the path when the file is ignored):

**Terminal (folder: `tasks-notes`)**
```powershell
git check-ignore .env
```
```text
.env
```
Stage the two files and check again; `A` in the first column means "added to the staging area":

**Terminal (folder: `tasks-notes`)**
```powershell
git add .gitignore .env.example
git status --short
```
```text
A  .env.example
A  .gitignore
```
Commit:

**Terminal (folder: `tasks-notes`)**
```powershell
git commit -m "Add .gitignore and .env.example"
```
```text
[main 9b7d2e4] Add .gitignore and .env.example
 2 files changed, 13 insertions(+)
 create mode 100644 .env.example
 create mode 100644 .gitignore
```
`.env` is not in the list: the secret stayed on your computer.

### Step 5. Make a branch
A **branch** is a separate line of save points, like a copy of the story where you can try a change without touching the main story. `main` stays safe while you work.

**Terminal (folder: `tasks-notes`)**
```powershell
git switch -c add-keycloak-port
```
`-c` means "create". Expected output:
```text
Switched to a new branch 'add-keycloak-port'
```
Open `team-notes.md` and add one line at the end, so the file becomes:

**File: `team-notes.md` (final version)**
```markdown
# Team notes
- API port: 8000
- Keycloak port: 8180
```

### Step 6. Read a diff
A **diff** shows what changed between the last commit and your working folder.

**Terminal (folder: `tasks-notes`)**
```powershell
git diff
```
Expected output (the two `index` codes differ on your computer):
```text
diff --git a/team-notes.md b/team-notes.md
index 4d5e6f7..8a9b0c1 100644
--- a/team-notes.md
+++ b/team-notes.md
@@ -1,2 +1,3 @@
 # Team notes
 - API port: 8000
+- Keycloak port: 8180
```
How to read it, top to bottom:

| Line | Meaning |
|------|---------|
| `diff --git a/team-notes.md b/team-notes.md` | The file being compared: `a` is the old version, `b` the new one. |
| `index 4d5e6f7..8a9b0c1 100644` | Internal ids of the two versions and the file type. Ignore it at first. |
| `--- a/...` and `+++ b/...` | `---` marks the old file, `+++` the new file. |
| `@@ -1,2 +1,3 @@` | The old text had 2 lines starting at line 1; the new text has 3 lines starting at line 1. |
| ` # Team notes` (starts with a space) | Unchanged line, shown for context. |
| `+- Keycloak port: 8180` | A line that was **added**. A line starting with `-` would be one that was **removed**. |

Commit it:

**Terminal (folder: `tasks-notes`)**
```powershell
git add team-notes.md
git commit -m "Add the Keycloak port"
```
```text
[add-keycloak-port 5c8e1d0] Add the Keycloak port
 1 file changed, 1 insertion(+)
```

### Step 7. Go back to main and merge
**Predict:** if you switch back to `main` and open `team-notes.md`, will the Keycloak line be there? No: that commit lives only on the branch.

**Terminal (folder: `tasks-notes`)**
```powershell
git switch main
```
```text
Switched to branch 'main'
```
Open the file: it has only two lines again. Now **merge** (bring the branch's commits into `main`):

**Terminal (folder: `tasks-notes`)**
```powershell
git merge add-keycloak-port
```
```text
Updating 9b7d2e4..5c8e1d0
Fast-forward
 team-notes.md | 1 +
 1 file changed, 1 insertion(+)
```
`Fast-forward` means `main` had no new commits of its own, so Git simply moved it forward. The file has three lines again. See the whole story:

**Terminal (folder: `tasks-notes`)**
```powershell
git log --oneline
```
```text
5c8e1d0 (HEAD -> main, add-keycloak-port) Add the Keycloak port
9b7d2e4 Add .gitignore and .env.example
3f2a9c1 Add team notes
```

### Step 8. Create the empty repository on GitHub
1. Sign in at https://github.com and choose **New repository** (the green button or the **+** menu).
2. Name it `tasks-notes`. Choose **Private** if you prefer.
3. Leave **Add a README**, **.gitignore** and **license** unticked: your folder already has history, and GitHub must start empty.
4. Choose **Create repository**. The next page shows the web address, for example `https://github.com/YOUR-USER/tasks-notes.git`.

### Step 9. Push your commits to GitHub
A **remote** is a named address of another copy. `origin` is the usual name for "the copy on GitHub". **Push** sends your commits there.

**Terminal (folder: `tasks-notes`; replace `YOUR-USER` with your GitHub user name)**
```powershell
git remote add origin https://github.com/YOUR-USER/tasks-notes.git
git push -u origin main
```
The first push opens a browser window (Git Credential Manager on Windows and macOS) so you can sign in to GitHub once; you never type your GitHub password in the terminal. `-u` remembers that local `main` goes with `origin/main`, so later a plain `git push` is enough. Typical output (the object counts and sizes differ):
```text
Enumerating objects: 9, done.
Counting objects: 100% (9/9), done.
Writing objects: 100% (9/9), 1.02 KiB | 1.02 MiB/s, done.
Total 9 (delta 0), reused 0 (delta 0), pack-reused 0
To https://github.com/YOUR-USER/tasks-notes.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
```
Refresh the repository page on GitHub. You see `team-notes.md`, `.gitignore` and `.env.example`, and **no** `.env`. Click **3 commits** to see your captions.

### Step 10. Clone the Code101 repository
**Clone** downloads a full copy of a repository, including its whole history. Go to the folder where you keep projects (not inside `tasks-notes`):

**Terminal (a projects folder, outside `tasks-notes`)**
```powershell
cd ..
git clone https://github.com/Uee03/Code101.git
```
Typical output (the numbers grow as the repository grows):
```text
Cloning into 'Code101'...
remote: Enumerating objects: ..., done.
Receiving objects: 100% (...), done.
Resolving deltas: 100% (...), done.
```
Look at where the platform capstone lives:

**Terminal (a projects folder)**
```powershell
cd Code101\capstones\platform
Get-ChildItem -Name
```
On macOS and Linux use `cd Code101/capstones/platform` and `ls`. You will see the folders and files of the capstone, for example:
```text
source
tutorials
README.md
TDD.md
```
Later, `git pull` inside the `Code101` folder downloads new commits from GitHub. You do not need an account to clone a public repository.

## Run it
Check that everything you did is in place. From the `tasks-notes` folder:

**Terminal (folder: `tasks-notes`)**
```powershell
git status
```
```text
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```
"Working tree clean" means every change is saved in a commit, and "up to date with `origin/main`" means GitHub has the same commits.

## How it works
- **Commit.** A snapshot of all tracked files plus your caption, name and time. It points to its parent commit, so commits form a chain. A good caption says *why* in a few words ("Add the Keycloak port").
- **Staging area.** `git add` chooses what goes into the next commit, so one commit can hold one idea even when you changed several files.
- **Branch.** A movable label on a commit. Creating one costs nothing, which is why teams make one per task.
- **Remote, push, clone, pull.** `origin` is a nickname for a web address. `push` uploads your commits, `pull` downloads new ones, `clone` is the first download of a whole repository.
- **`.gitignore`.** Patterns of files Git must not offer to track. It only helps for files that were **never committed**: once a file is in history, ignoring it later does not remove it.
- **Misconception to drop:** "GitHub *is* Git." Git is the tool on your computer; GitHub is one website that hosts Git repositories (others exist, for example GitLab).

## Try it
Starter: `exercise/starter/answers.txt` (a text file where you write commands). Work in your `tasks-notes` folder.
1. **Guided.** Fill every `TODO` in `answers.txt` with the right command: make a branch `add-database-port`, add the line `- Database port: 5432` to `team-notes.md`, commit it with the message "Add the database port", switch to `main`, merge the branch and print the history. Then really run the commands.
2. **Change.** Add the line `*.log` to `.gitignore`, create an empty file named `server.log`, and run `git status --short`. Which files are listed?
3. **Stretch (no single answer).** A teammate pushed a `.env` with a real password to GitHub. Write the order of the steps you would take and say why the order matters.

The starter file:

**File: `exercise/starter/answers.txt`**
```text
Write the Git command for each step. Replace every TODO.
Start in your tasks-notes folder, on branch main, with a clean "git status".

1. Create a branch called add-database-port and switch to it:
TODO

2. (Edit team-notes.md: add the line "- Database port: 5432" and save.)
   Stage team-notes.md:
TODO

3. Commit with the message "Add the database port":
TODO

4. Go back to the branch main:
TODO

5. Bring the branch into main:
TODO

6. Show the history, one line per commit:
TODO
```

<details><summary>Solution</summary>

**File: `exercise/solution/answers.txt`**
```text
Write the Git command for each step. Replace every TODO.
Start in your tasks-notes folder, on branch main, with a clean "git status".

1. Create a branch called add-database-port and switch to it:
git switch -c add-database-port

2. (Edit team-notes.md: add the line "- Database port: 5432" and save.)
   Stage team-notes.md:
git add team-notes.md

3. Commit with the message "Add the database port":
git commit -m "Add the database port"

4. Go back to the branch main:
git switch main

5. Bring the branch into main:
git merge add-database-port

6. Show the history, one line per commit:
git log --oneline

Rung 2 (change): add the line "*.log" to .gitignore, create a file named server.log,
then run "git status --short". Only .gitignore is listed, server.log is not.

Rung 3 (stretch), one possible plan for a .env that was pushed by mistake:
1. Treat the secret as public: change the password or revoke the key at its provider.
2. git rm --cached .env, add .env to .gitignore, commit and push.
3. Only then, if the repository must be clean, rewrite history (a tool such as git filter-repo) and tell everyone who cloned it.
```
For rung 2, `.gitignore` is listed as modified (` M .gitignore`) because you changed it; `server.log` is not listed because the new `*.log` pattern hides it. For rung 3 the order matters because anyone could have copied the secret the moment it was public: rotating it first makes the leaked value useless; removing the file from the repository only stops *future* copies.

</details>

## Check yourself
1. What is the difference between `git add` and `git commit`? <details><summary>Answer</summary>`add` puts changes on the staging table; `commit` takes the snapshot of what is staged and gives it a caption.</details>
2. You run `git status --short` and see `?? notes.txt`. What does `??` mean? <details><summary>Answer</summary>The file is untracked: Git sees it but has never been told to save it.</details>
3. In a diff, what does a line that starts with `+` mean, and one that starts with `-`? <details><summary>Answer</summary>`+` is a line added in the new version, `-` is a line removed from the old version.</details>
4. Why is `.env.example` committed but `.env` is not? <details><summary>Answer</summary>`.env.example` has only fake values and documents the settings; `.env` may hold real secrets, and anything committed stays in the history for good.</details>
5. **Find the bug:** you committed `.env` yesterday, today you added `.env` to `.gitignore` and the file still shows in `git ls-files`. Why? <details><summary>Answer</summary>`.gitignore` only affects untracked files. The file is already tracked, so you must also run `git rm --cached .env`, and because it is in history the secret must be rotated.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `git: command not found` or "git is not recognized" | Git is not installed, or the terminal was opened before the install. | Install Git (Step 1), close the terminal and open a new one. |
| `fatal: not a git repository (or any of the parent directories): .git` | You are not inside the repository folder. | `cd tasks-notes`, or run `git init -b main` there. |
| `Author identity unknown` or "Please tell me who you are" | `user.name` and `user.email` are not set. | Run the two `git config --global` commands from Step 1, then repeat the commit. |
| `nothing added to commit but untracked files present` | You committed without `git add`. | `git add <file>`, then commit again. |
| `error: src refspec main does not match any` on push | The repository has no commit yet, or the branch has another name. | Commit first; check the branch name with `git branch`. |
| `remote: Repository not found` or a sign-in failure on push | The address has a typo, the repository does not exist, or you signed in with another account. | Check `git remote -v`, and sign in as the account that owns the repository. |
| `\ No newline at end of file` inside a diff | The file does not end with a new line. | Press Enter at the end of the last line and save again. |

(The error texts above are typical; your Git version may word them slightly differently.)

## Best practice
Commit small, with a caption that says why, and never commit secrets: commit `.env.example` with fake values and ignore `.env`. If a secret is ever pushed, treat it as public and rotate it first. Source: [Pro Git, chapter 2 Git Basics](https://git-scm.com/book/en/v2/Git-Basics-Getting-a-Git-Repository) and [GitHub Docs: Removing sensitive data from a repository](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository).

## Going further
- Pro Git is a free book; chapters 1 to 3 cover this lesson in depth: https://git-scm.com/book.
- A **pull request** is how teams on GitHub propose a branch for review before it is merged. The backend and client capstones use branches the same way.

## Summary
- You installed Git, set your identity and created a repository with three commits.
- You used `.gitignore` to keep a fake `.env` out of the history and committed `.env.example` instead.
- You made a branch, read a diff line by line and merged the branch with a fast-forward.
- You pushed the repository to GitHub and cloned the Code101 course repository.

## Next lesson
02. HTTP and REST: how programs talk to the Tasks and Teams API with requests and responses, and your first calls with `curl` and PowerShell.
