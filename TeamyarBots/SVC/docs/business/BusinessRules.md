---
description: Business domain rules and enterprise application business logic standards
globs:
  - "**/*.cs"
  - "**/*.razor"
alwaysApply: true
---

# Business Rules Development Rules

## General Principles

- Business rules must be explicit and documented.
- Business logic must not be placed in UI components.
- Business rules belong to Domain/Application layers.
- Never duplicate business rules in multiple locations.
- Every important business decision must be traceable.

---

# Business Logic Location

Required flow:
