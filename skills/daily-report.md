---
name: daily-report
description: Generate a daily work report in markdown format. Use when the user asks to create a daily report, end-of-day summary, daily standup notes, or work log. Triggers on phrases like "daily report", "end of day report", "what did I do today", "generate my daily summary", or "create standup notes".
---

# Daily Report Generator

Generate a structured daily report by gathering information from the user interactively.

## Workflow

1. **Gather information** - Ask the user about each section (can be done conversationally or all at once based on user preference)
2. **Generate report** - Create the markdown file with today's date
3. **Save to outputs** - Place the file in `/mnt/user-data/outputs/`

## Report Template

```markdown
# Daily Report - [YYYY-MM-DD]

## Tasks Completed
- [Task 1 with brief description]
- [Task 2 with brief description]

## Time Tracking
| Task | Time Spent |
|------|------------|
| [Task name] | [X hrs] |
| **Total** | **[X hrs]** |

## Issues & Blockers
- [Issue 1 and current status]
- [Issue 2 and current status]
- *(None if no blockers)*

## Plans for Tomorrow
- [ ] [Planned task 1]
- [ ] [Planned task 2]
```

## Guidelines

- Use today's actual date from the system
- Keep task descriptions concise but meaningful
- For time tracking, round to nearest 15 minutes (0.25 hrs)
- If user has no blockers, write "None" rather than omitting the section
- Plans for tomorrow use checkbox format for easy tracking
- Save file as `daily-report-YYYY-MM-DD.md`
