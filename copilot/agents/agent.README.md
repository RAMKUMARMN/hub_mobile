# Project Agent for Hub Mobile

This folder defines a project-specific agent to improve prompt engineering and assistant responses for the Hub Mobile Flutter app.

Files added:
- `agent.md` — agent manifest (persona, capabilities, scoped files).
- `agent.instructions.md` — behavior rules, testing, PR requirements.
- `agent.prompts.md` — ready-to-use prompt templates for common tasks.

How to use:
- Start prompts using templates from `agent.prompts.md` and include relevant file paths and error logs.
- Follow verification steps from `agent.instructions.md` after applying code changes.

Customization:
- Add more task-specific templates in `agent.prompts.md` as needed.
- Modify `agent.md` metadata to tune agent persona or add additional capabilities.
