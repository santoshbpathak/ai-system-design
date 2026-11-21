# AI System Design

**The questions a senior engineer would ask before you build. Claude asks them for you, in about five minutes.**

AI can write your app in an afternoon. It won't tell you what the app will cost to run each month, whether one customer can see another customer's data, or what happens on the day your AI provider goes down.

Those are design decisions. Most builders skip them, usually because nobody told them the questions existed.

This is a free skill for [Claude Code](https://claude.com/claude-code) that asks those questions before any code is written, does the maths, and writes the answers into one file in your project: `ARCHITECTURE.md`.

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

**3. Writes `ARCHITECTURE.md`.** One file with ten short sections: your numbers, your bill, how customer data is kept apart, what happens when things fail, and the specific numbers that tell you when it's time to add the next piece. Claude reads it at the start of every later session, so the decisions stick.

See a filled-in one: [examples/ARCHITECTURE.example.md](examples/ARCHITECTURE.example.md).

## Install

You need Claude Code and a Mac or Linux machine. Python 3 is used for the calculator and is already on most machines.

```bash
git clone https://github.com/santoshbpathak/ai-system-design.git
cd ai-system-design
bash install.sh
```

Then restart Claude Code, or reload your editor window.

**What the installer changes on your machine:**

- Copies the skill into `~/.claude/skills/ai-system-design/`.
- Adds a small check that runs when a Claude Code session starts. If the project has no `ARCHITECTURE.md`, it reminds Claude to run the skill before building. If the file exists, it reminds Claude to read it.
- Adds one entry to `~/.claude/settings.json` to switch that check on. Your old settings are saved as `settings.json.bak` first. This step needs a tool called `jq`; if you don't have it, the installer shows you the three lines to paste in yourself.

Prefer to run it only when you ask? Use `bash install.sh --no-hook`.

To remove everything: `bash uninstall.sh`. Your projects' `ARCHITECTURE.md` files are left alone.

Windows isn't tested yet. It should work inside WSL. If you try it, please tell us how it went.

## Use it

- **Starting something new:** open the folder in Claude Code and describe what you want to build. Claude runs the pre-flight first.
- **On a project you've already built:** say *"Run ai-system-design on this project."*
- **Any time:** type `/ai-system-design`.
- **Just the bill:** run the calculator yourself.

  ```bash
  python3 ~/.claude/skills/ai-system-design/scripts/napkin.py \
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
  SKILL.md                     the instructions Claude follows
  templates/ARCHITECTURE.md    the blank file it fills in
  scripts/napkin.py            the bill calculator
hooks/architecture-check.sh    the startup check
examples/                      a filled-in ARCHITECTURE.md
install.sh, uninstall.sh
```

## Help make it better

You don't need to be an engineer to contribute. The most useful things are:

- **A story.** Something that went wrong in a project you built with AI, and what you wish you'd been asked first.
- **A plain-language fix.** Anywhere the skill or this page uses a word you had to look up.
- **An example.** Your own filled-in `ARCHITECTURE.md`, with private details removed.

Open an issue to share any of these. If you'd like to change the files yourself, [CONTRIBUTING.md](CONTRIBUTING.md) explains how.

## Credits

The five rules, the four questions and the "nine boxes" picture come from a live system design session run by the Outskill community. This project turns those ideas into something Claude does for you automatically.

## Licence

[MIT](LICENSE). Use it, change it, share it.
