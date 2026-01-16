---

name: Start
description: Project starter template for LLM chats in IDE. Structured workflow with goal definition, task list, context files, clarity checks, conventions, and cost-efficient tool usage. Ensures alignment before implementation
---

# Start

## How to use this skill

When the user invokes this skill (e.g., `/start`), they will provide:

1. **Goal** - the main objective of the session
2. **Tasks** - a list of specific tasks to accomplish

**Example usage:**

```
/start #Cel: Refaktoryzacja aplikacji. ##Tasks:
- wprowadź zmianę "ABC"
- zredaguj treść w sekcji "XYZ"
```

Your job as LLM is to:

1. **Extract** the Goal and Tasks from the user's message
2. **Follow** the workflow sections below (Context, Task clarity, Constraints, Tools)
3. **Repeat** the goal and tasks in your own words
4. **Ask** clarifying questions before implementation
5. **Wait** for acceptance before proceeding

---

## Goal

**[User will provide the goal here]**

---

## Tasks

**Task list:**

- **[User will provide tasks here]**

---

## Context

**Read these files before starting:**

- `README.md`
- Other relevant project documentation

**Instructions for LLM:**

- Check if these files exist in the project
- Read them to understand project structure and requirements
- Ask the user if there are additional context files to review

---

## Task clarity

**Apply this process:**

1. **Repeat** the goal and tasks in your own words
2. **Don't guess** - check the project files to find answers to your questions
3. **Add ambiguities** to the implementation plan in the form of questions
4. **Wait** for the implementation plan to be accepted before coding

---

## Constraints

**Observe these guidelines:**

- `Claude.md` - general Claude behavior guidelines
- `docs/conventions.md` - project coding conventions
- `docs/contributing.md` - contribution guidelines

**Instructions for LLM:**

- Check if these files exist
- Follow their guidelines strictly
- If they don't exist, ask the user about conventions to follow

---

## Tools

**Use when needed with *restriction: cost efficiency***

##### **Primary tools:**

- Hosting and domain on hostido.pl
- Vercel
- Gemini API

##### **Secondary tools:**

- Railway
- Flutter
- Resend

**Instructions for LLM:**

- Prefer primary tools for their cost-efficiency
- Only suggest secondary tools when primary tools are insufficient
- Always consider cost implications when recommending solutions

---

## Workflow Summary

1. User invokes skill with Goal + Tasks
2. LLM reads Context files
3. LLM repeats understanding and asks clarifying questions
4. User answers questions
5. LLM creates implementation plan
6. User accepts the plan
7. LLM implements the tasks following Constraints and using appropriate Tools

---

## After Implementation

**IMPORTANT:** After completing implementation:

- **DO NOT** create commits automatically
- **DO NOT** push changes
- **WAIT** for the user to invoke `/end` workflow

The `/end` workflow (see `end.md`) handles:
- Code review checklist
- Documentation updates
- Proper commit numbering (#N format)
- Git push to `claude/*` branch
