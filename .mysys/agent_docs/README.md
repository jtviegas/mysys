# agents documentation

agent documentation files

## claude
- CLAUDE.md is for onboarding Claude into your codebase. It should define your project's WHY, WHAT, and HOW.
- Less (instructions) is more. While you shouldn't omit necessary instructions, you should include as few instructions as reasonably possible in the file.
- Keep the contents of your CLAUDE.md concise and universally applicable.
- Use Progressive Disclosure - don't tell Claude all the information you could possibly want it to know. Rather, tell it how to find important information so that it can find and use it, but only when it needs to to avoid bloating your context window or instruction count.
- Claude is not a linter. Use linters and code formatters, and use other features like Hooks and Slash Commands as necessary.
- CLAUDE.md is the highest leverage point of the harness, so avoid auto-generating it. You should carefully craft its contents for best results.

