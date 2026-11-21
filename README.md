# AI System Design

**The questions a senior engineer would ask before you build. Your coding agent asks them for you, in about five minutes.**

AI can write your app in an afternoon. It won't tell you what the app will cost to run each month, whether one customer can see another customer's data, or what happens on the day your AI provider goes down.

Those are design decisions. Most builders skip them, usually because nobody told them the questions existed.

This is a free skill for AI coding agents. A coding agent is a tool that writes code for you from plain-language requests: Claude Code, Codex, Cursor, Gemini CLI, GitHub Copilot, OpenCode and others. A skill is a folder of instructions the agent follows for one kind of job.

This one asks those questions before any code is written, does the maths, and writes the answers into one file in your project: `ARCHITECTURE.md`. It isn't tied to any one agent or AI provider. It uses the open [Agent Skills](https://agentskills.io) format, which most coding agents read.

---

## What goes wrong without it

| What gets skipped | What happens later |
|---|---|
| Working out the monthly AI bill | The first real invoice is a shock. A leaked key can run up thousands overnight. |
| Keeping each customer's data separate | Someone asks your chatbot a question and gets another company's answer. |
| Planning for the AI being slow or down | Your app hangs, or shows a blank screen, and users leave. |
| Treating uploads and web pages as untrusted | A document with hidden instructions inside takes control of your bot. |
| Recording what each request did and cost | Something breaks and you have no way to see why. |
| Starting simple | You spend weeks setting up infrastructure for users you don't have yet. |

None of these show up in a demo. All of them show up with real users.

## What it does

**1. Asks four questions.** Each comes with a suggested answer, so you can just say "defaults" and keep moving.

- How many people will use this, and how often?
- How fast does it need to answer?
- What does one user cost you, and what do they pay?
- What data does it touch?

**2. Does the maths.** A small calculator works out your monthly AI bill before you've spent anything (output shortened here):

```
Messages / month     : 54.00K
Input tokens / month : 162.00M
Output tokens / month: 16.20M

                          no caching      with caching
TOTAL / month                $729.00           $433.75

LLM cost per tenant / month: $43.38
Monthly revenue: $1,500.00  ->  gross margin after LLM: 71%
Suggested hard spend cap (2x expected): $867.51 / month
```

("Tokens" are the units AI providers bill in, roughly three-quarters of a word each. "Caching" means reusing work instead of paying for it twice.)

**3. Writes `ARCHITECTURE.md`.** One file with ten short sections: your numbers, your bill, how customer data is kept apart, what happens when things fail, and the specific numbers that tell you when it's time to add the next piece. The skill also adds a line to your project's agent instructions telling the agent to read the file before changing the system, so the decisions stick.

See a filled-in one: [examples/ARCHITECTURE.example.md](examples/ARCHITECTURE.example.md).

## Install

You need a coding agent that supports skills, and a Mac or Linux machine. Python 3 is used for the calculator and is already on most machines.

```bash
git clone https://github.com/santoshbpathak/ai-system-design.git
cd ai-system-design
bash install.sh
```

Then restart your coding agent, or reload your editor window.

The installer looks for the agents on your machine and copies the skill into each one's skills folder:

| Agent | Where the skill goes |
|---|---|
| Claude Code | `~/.claude/skills/` |
| Codex, Cline, Zed, Warp and others that read the shared folder | `~/.agents/skills/` |
| Cursor | `~/.cursor/skills/` |
| Gemini CLI | `~/.gemini/skills/` |
| GitHub Copilot | `~/.copilot/skills/` |
| OpenCode | `~/.config/opencode/skills/` |
| Windsurf | `~/.codeium/windsurf/skills/` |
| Goose | `~/.config/goose/skills/` |

The shared folder is always filled in, because several agents read it.

**Other ways to install:**

- **One agent only:** `bash install.sh --agent codex` (run `bash install.sh --list` for the names).
- **An agent that isn't in the table:** `bash install.sh --dir /path/to/its/skills/folder`.
- **With the `skills` tool,** if you have Node.js: `npx skills add santoshbpathak/ai-system-design -g`. It supports many more agents and asks which ones you want.
- **No skills support at all:** clone the repo and tell your agent *"Read skills/ai-system-design/SKILL.md in that folder and follow it for this project."*

### Make it run by itself

Installed like this, the skill runs when you ask for it, and most agents will also pick it up when you describe a new project. To make sure it is never skipped:

- **Any agent:** add a short note to your project's `AGENTS.md`, the instructions file most coding agents read at the start of a session.

  ```bash
  bash install.sh --project /path/to/your/project
  ```

  The note says: no `ARCHITECTURE.md` yet, run the skill before building; if there is one, read it first.

- **Claude Code:** nothing to do. The installer also adds a small check that runs when a session starts and does the same job in every project. It adds one entry to `~/.claude/settings.json` and saves your old settings as `settings.json.bak` first. This step needs a tool called `jq`; without it, the installer shows you the lines to paste in yourself. To leave the check out, use `bash install.sh --no-hook`.

To remove everything: `bash uninstall.sh`. Your projects' `ARCHITECTURE.md` and `AGENTS.md` files are left alone.

Windows isn't tested yet. It should work inside WSL. If you try it, please tell us how it went.

## Use it

- **Starting something new:** open the folder in your coding agent and describe what you want to build. The agent runs the pre-flight first.
- **On a project you've already built:** say *"Run ai-system-design on this project."*
- **By name:** most agents let you call a skill directly, for example by typing `/ai-system-design` in Claude Code.
- **Just the bill:** run the calculator yourself from the folder you cloned.

  ```bash
  python3 skills/ai-system-design/scripts/napkin.py \
    --dau 300 --msgs 6 --in-tokens 3000 --out-tokens 300 \
    --in-price 3 --out-price 15
  ```

  `--dau` is daily users and `--msgs` is messages per user per day. The two prices are what your AI provider charges per million tokens, in US dollars. Look them up on the provider's pricing page; the `3` and `15` above are placeholders.

It works for apps with no AI in them too. The AI-specific sections just get marked "not applicable".

## The five rules

Everything in the skill comes back to these.

1. **Size it before you build it.** Work out users, speed, cost and data on the back of a napkin first. Most new apps need to stay cheap, not handle millions.
2. **Treat every input as untrusted.** Anything that reaches the AI can carry hidden instructions: what users type, files they upload, web pages, results from other tools. Never hide a password or an access rule inside the AI's instructions and hope it keeps the secret.
3. **Guard the data.** "Who can see what" is decided where the data is stored. Asking the AI nicely doesn't count.
4. **Assume it fails.** The AI will sometimes be slow, wrong or offline. Set time limits, have a backup, and make sure a retry can't send the same email twice.
5. **Measure everything.** Record what each request did, how long it took and what it cost. If you can't see it, you can't fix it.

Plus one habit: **start boring.** One app, one database, one AI provider. Add more only when a real number forces you to.

## What's in this repo

```
skills/ai-system-design/
  SKILL.md                     the instructions your agent follows
  templates/ARCHITECTURE.md    the blank file it fills in
  scripts/napkin.py            the bill calculator
hooks/architecture-check.sh    the startup check for Claude Code
examples/                      a filled-in ARCHITECTURE.md
install.sh, uninstall.sh       copy the skill into your agents' folders, or take it out
lib-agents.sh                  the list of agents and their folders
```

## Help make it better

You don't need to be an engineer to contribute. The most useful things are:

- **A story.** Something that went wrong in a project you built with AI, and what you wish you'd been asked first.
- **A plain-language fix.** Anywhere the skill or this page uses a word you had to look up.
- **An example.** Your own filled-in `ARCHITECTURE.md`, with private details removed.

Open an issue to share any of these. If you'd like to change the files yourself, [CONTRIBUTING.md](CONTRIBUTING.md) explains how.

## Credits

The five rules, the four questions and the "nine boxes" picture come from a live system design session run by the Outskill community. This project turns those ideas into something your coding agent does for you automatically.

## Licence

[MIT](LICENSE). Use it, change it, share it.
