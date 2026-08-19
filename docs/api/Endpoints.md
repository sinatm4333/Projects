---
description: API Endpoint design standards for ASP.NET Core applications
globs:
  - "**/*.cs"
  - "**/*.razor"
alwaysApply: true
---

# API Endpoint Development Rules

## General Principles

- All APIs must follow REST principles.
- Endpoints must be predictable and consistent.
- Never expose database entities directly.
- Always use DTOs.
- All endpoints must have validation, authorization and logging.

---

# Endpoint Architecture

Required flow:
