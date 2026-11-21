# Contributing

Thanks for helping. This skill is for people who build with AI and aren't engineers by trade, so keeping it clear is as valuable as making it clever.

## Ways to help without touching any files

Open an issue with any of these:

- **Something that went wrong.** A surprise bill, a data mix-up, an outage. Say what happened and what question would have caught it.
- **A confusing word or step.** Quote the line and say what you expected it to mean.
- **An example.** Your own filled-in `ARCHITECTURE.md`. Remove company names, real prices and anything private first.

## Changing the files

1. Fork the repo and make your change on a branch.
2. Install your copy locally: `bash install.sh`
3. Test it (see below).
4. Open a pull request. Say what problem the change fixes and how you tested it.

### Where things live

| File | What it is |
|---|---|
| `skills/ai-system-design/SKILL.md` | The instructions Claude follows |
| `skills/ai-system-design/templates/ARCHITECTURE.md` | The blank file Claude fills in |
| `skills/ai-system-design/scripts/napkin.py` | The bill calculator |
| `hooks/architecture-check.sh` | The check that runs when a session starts |
| `examples/` | Filled-in examples |

### Testing a change to the skill

A skill is a set of instructions, so the test is whether Claude behaves differently with it.

1. **Before:** in a fresh Claude Code session without your change, ask for something like *"I want to build a support chatbot where several companies upload their own documents. Set up the architecture and give me the plan."* Note what Claude skips.
2. **After:** install your change, start a fresh session, ask the same thing.
3. In the pull request, say what was missing before and present after.

If the "before" run already does the thing, the change isn't needed.

### Testing a change to the calculator

This command must still print 3.00M messages, 9.00B input tokens and 900.00M output tokens:

```bash
python3 skills/ai-system-design/scripts/napkin.py --dau 5000 --msgs 20 --in-tokens 3000 --out-tokens 300 --in-price 3 --out-price 15
```

### Testing a change to the installer or the check

Point the installer at a scratch folder so your real settings aren't touched:

```bash
CLAUDE_HOME=/tmp/claude-test bash install.sh
CLAUDE_HOME=/tmp/claude-test bash uninstall.sh
```

## House rules

- **Plain words.** If a term needs explaining, explain it the first time it appears.
- **No model prices in the files.** They change. The calculator asks for them on purpose.
- **Don't name specific products as the only answer.** Offer them as examples.
- **Keep `SKILL.md` short.** Claude reads all of it every time. Add a line only if a test shows it changes behaviour.
- **Every section of the template stays required.** "Not applicable, because…" is a fine answer. Blank is not.

## Licence

By contributing you agree your work is released under the [MIT licence](LICENSE).
