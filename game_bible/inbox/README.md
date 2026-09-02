# Game Bible Inbox

Put exactly one active Game Bible here before manually starting the workflow.

Supported formats:
- `.docx`
- `.md`
- `.txt`

The workflow reads the newest supported file, extracts the project ID when present, and otherwise creates a new project ID. If a known project ID is present, the request is treated as an update to that project rather than a new project.

Keep proprietary source code and credentials out of this folder. Game Bible files are project specifications, not secret stores.
