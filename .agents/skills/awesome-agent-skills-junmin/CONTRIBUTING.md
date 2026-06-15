# Contributing to Awesome Agent Skills

Thank you for your interest in contributing! This project aims to build a comprehensive, curated collection of agent skills, patterns, and resources for AI-powered development workflows.

## Table of Contents

- [Types of Contributions](#types-of-contributions)
- [Getting Started](#getting-started)
- [How to Contribute Skills](#how-to-contribute-skills)
- [Skill Categories](#skill-categories)
- [Skill Structure & Template](#skill-structure--template)
- [Quality Standards](#quality-standards)
- [Submission Guidelines](#submission-guidelines)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Code of Conduct](#code-of-conduct)
- [Security](#security)
- [License](#license)

---

## Types of Contributions

We welcome various types of contributions:

### 1. **Adding Skills**
- New reusable workflows, prompts, or automation patterns
- Tool wrappers and CLI recipes
- Evaluation rubrics and testing frameworks
- Platform-specific implementations (Codex, Claude Code)

### 2. **Improving Documentation**
- Fixing typos or clarifying existing documentation
- Adding examples and use cases
- Translating documentation (especially Chinese translations)
- Improving setup and installation guides

### 3. **Bug Reports & Feature Requests**
- Reporting broken links or outdated information
- Suggesting new skill categories or patterns
- Proposing improvements to existing skills

### 4. **Code & Infrastructure**
- Improving repository structure
- Adding automation tools (linters, validators)
- Enhancing CI/CD workflows

---

## Getting Started

### Prerequisites

- Familiarity with Git and GitHub workflow
- Basic understanding of agent skills concepts (see [README.md](README.md))
- Account on GitHub

### Setup

1. **Fork the repository**
   ```bash
   # Click "Fork" button on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/awesome-agent-skills.git
   cd awesome-agent-skills
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-skill-name
   # or
   git checkout -b fix/description-of-fix
   ```

3. **Make your changes** (see specific guides below)

4. **Test locally** - Verify markdown renders correctly and links work

5. **Commit your changes** (follow [commit guidelines](#commit-message-guidelines))

6. **Push and create Pull Request**
   ```bash
   git push origin feature/your-skill-name
   ```

---

## How to Contribute Skills

### Quick Start

1. **Choose the right location** based on platform:
   - `skills/codex/` - OpenAI Codex skills
   - `skills/claude_code/` - Anthropic Claude Code skills
   - `skills/kiro_cli/` - kiro-cli skills (TBD)

2. **Choose a category folder name**

Use the same category folder naming convention as the repository (see [Skill Categories](#skill-categories) for a suggested mapping table).

3. **Create skill directory**
   ```bash
   # Example
   mkdir -p skills/claude_code/document_processing/your_skill_name
   cd skills/claude_code/document_processing/your_skill_name
   ```

4. **Create SKILL.md** (see [template below](#skill-structure--template))

5. **Add optional resources**
   - `scripts/` - Executable code and automation scripts
   - `references/` - Documentation, examples, or guides
   - `assets/` - Templates, configuration files, or media

6. **Update platform index** - Add your skill to the relevant platform README(s):
   - `skills/[platform]/README.md`
   - `skills/[platform]/README_ZH.md` (if present)

7. **Test your skill** - Verify it works as documented

---

## Skill Categories

Skills should be organized by functional category (choose the most relevant one):

### Core Categories

- **Document Processing** - PDF parsing, format conversion, OCR, text extraction
- **Development & Code Tools** - Refactoring, testing, code review, debugging
- **Data & Analysis** - Data transformation, visualization, statistical analysis
- **Business & Marketing** - Market research, content generation, analytics
- **Communication & Writing** - Email drafting, technical writing, translation
- **Creative & Media** - Image generation, video editing, content creation
- **Productivity & Organization** - Task management, note-taking, scheduling
- **Collaboration & Project Management** - Team coordination, planning, tracking
- **Security & Systems** - Penetration testing, system administration, monitoring

### Choosing a Category

- Select the **primary use case** for your skill
- If a skill spans multiple categories, choose the most specific one
- Create a new category only if none of the existing ones fit (discuss in an issue first)

### Category Folder Naming

Use consistent, lowercase, hyphenated folder names for categories. Suggested mapping:

| Category (README)                  | Folder Name                        |
| ---------------------------------- | ---------------------------------- |
| Document Processing                | `document_processing`              |
| Development & Code Tools           | `development_code_tools`           |
| Data & Analysis                    | `data_analysis`                    |
| Business & Marketing               | `business_marketing`               |
| Communication & Writing            | `communication_writing`            |
| Creative & Media                   | `creative_media`                   |
| Productivity & Organization        | `productivity_organization`        |
| Collaboration & Project Management | `collaboration_project_management` |
| Security & Systems                 | `security_systems`                 |

---

## Skill Structure & Template

### Directory Structure

```
your_skill_name/
├── SKILL.md          # Required: Main skill documentation (YAML frontmatter required for Claude Code)
├── scripts/          # Optional: Executable code
│   ├── setup.sh
│   └── run.py
├── references/       # Optional: Supporting documentation
│   ├── examples.md
│   └── api-docs.md
└── assets/           # Optional: Templates and resources
    ├── config.json
    └── template.txt
```

### SKILL.md Template

Create your `SKILL.md` file with the following structure:

Note:
- **Claude Code** skills require YAML frontmatter.
- **Codex** skills should **not** include YAML frontmatter.

````markdown
---
name: your-skill-name
description: Brief description of what this skill does and when to use it (max 1024 chars)
---

# Your Skill Name

**Platforms:** Codex | Claude Code
**Tags:** tag1, tag2, tag3
**Use cases:** When to use this skill

## Objective

Clear statement of what this skill accomplishes and what "done" looks like.

## Inputs

- **Input A**: Description of required input
- **Input B**: Description of optional input with default value

## Outputs

- **Output A**: Description of primary output
- **Output B**: Description of secondary output or side effects

## Workflow

1. **Step 1**: First action to take
2. **Step 2**: Follow-up action
3. **Step 3**: Final verification or output

## Constraints & Guardrails

- **What not to do**: Specific anti-patterns
- **Safety notes**: Security or privacy considerations
- **Stop conditions**: When to abort or escalate

## Examples

### Example 1: Basic Usage

**Input:**
```text
[Example input data or command]
```

**Expected Output:**
```text
[Example output or result]
```

**Notes:** Any important context or variations

### Example 2: Advanced Usage

**Input:**
```text
[More complex example]
```

**Expected Output:**
```text
[Expected result]
```

## Evaluation Checklist

- [ ] **Correctness**: Produces accurate results
- [ ] **Completeness**: Handles all specified inputs
- [ ] **Safety**: No security vulnerabilities or data leaks
- [ ] **Reproducibility**: Works consistently across runs
- [ ] **Performance**: Completes within reasonable time
- [ ] **Documentation**: Clear and sufficient for users

## References

- [Documentation link](https://example.com)
- [Related skill](../related-skill/)
- [External resource](https://example.com)

## Version History

- **v1.0.0** (2026-01-13): Initial release
````

### YAML Frontmatter Requirements

YAML frontmatter is **required** for Claude Code skills.
For Codex skills, do **not** include YAML frontmatter.

- **`name`**:
  - Max 64 characters
  - Lowercase letters, numbers, and hyphens only
  - No XML tags or reserved words ("anthropic", "claude", "openai")
  - Example: `pdf-to-markdown-converter`

- **`description`**:
  - Max 1024 characters
  - Non-empty, clear, and concise
  - No XML tags
  - Should explain **what** the skill does and **when** to use it
  - Example: "Converts PDF documents to clean Markdown format with preserved formatting. Use for documentation migration or content extraction tasks."

---

## Quality Standards

All contributions must meet these quality criteria:

### Content Requirements

- [ ] **Complete structure**: Includes all required sections (Objective, Inputs, Outputs, Workflow, Constraints, Examples, Evaluation)
- [ ] **Clear objective**: States what the skill does and success criteria
- [ ] **Documented inputs/outputs**: Specifies all parameters and return values
- [ ] **Step-by-step workflow**: Provides actionable implementation steps
- [ ] **Safety constraints**: Lists limitations, risks, and stop conditions
- [ ] **Working examples**: Includes at least one complete, tested example
- [ ] **Evaluation checklist**: Provides criteria for verifying correctness

### Writing Style

- **Be concise**: Prefer bullet points over paragraphs
- **Be specific**: Use concrete examples over abstract descriptions
- **Be accurate**: Test all code and commands before submitting
- **Be consistent**: Follow existing patterns in the repository
- **Be inclusive**: Use clear, professional language

### Technical Standards

- **Tested**: All examples and code must be tested and working
- **Documented**: All assumptions and dependencies must be explicit
- **Secure**: No hardcoded credentials, API keys, or sensitive data
- **Portable**: Works across common environments (specify requirements)
- **Versioned**: Include version numbers for external dependencies

---

## Submission Guidelines

### Before Submitting

1. **Check existing skills** - Avoid duplicates; improve existing skills instead
2. **Test thoroughly** - Verify all examples and code work as documented
3. **Lint markdown (optional)** - If you have `markdownlint` available, use it; otherwise ensure Markdown renders correctly and headings/links/code fences look good
4. **Update index** - Add your skill to the platform-specific `README.md`
5. **Update main READMEs (when applicable)** - If you add/modify entries under Skill Categories or change the taxonomy, update both `README.md` and `README_ZH.md`

### Pull Request Process

1. **Use descriptive PR title**
   - ✅ Good: "Add PDF-to-Markdown converter for Claude Code"
   - ❌ Bad: "New skill"

2. **Fill out PR template** (if provided)

3. **Link related issues** - Reference any issues your PR addresses

4. **Describe changes**
   - What skill/improvement does this add?
   - What category does it belong to?
   - Have you tested it? (provide evidence if possible)

5. **Respond to feedback** - Be open to suggestions and iterate

### PR Checklist

Before submitting, verify:

- [ ] Skill follows the [SKILL.md template](#skillmd-template)
- [ ] YAML frontmatter is valid with `name` and `description`
- [ ] Added to platform-specific index (`skills/[platform]/README.md`)
- [ ] At least one complete, tested example included
- [ ] Evaluation checklist provided
- [ ] No sensitive data (API keys, credentials, personal info)
- [ ] Markdown is properly formatted
- [ ] All links are valid and working
- [ ] Commit messages follow [guidelines](#commit-message-guidelines)
- [ ] Branch is up-to-date with `main`

---

## Commit Message Guidelines

Use clear, descriptive commit messages following this format:

### Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

### Types

- **feat**: New skill or feature
- **fix**: Bug fix or correction
- **docs**: Documentation changes
- **style**: Formatting, typos (no code change)
- **refactor**: Code restructuring (no feature change)
- **test**: Adding or updating tests
- **chore**: Maintenance tasks (dependencies, CI/CD)

### Examples

✅ **Good:**
```
feat(claude-code): add PDF-to-Markdown converter skill

Implements a skill for converting PDF documents to clean Markdown format
with preserved formatting, tables, and images.

Closes #42
```

```
docs(readme): update installation instructions for Claude Code

Clarifies the difference between user-level and project-level skill
installation paths.
```

```
fix(codex): correct file path in deployment-automation skill

The script was pointing to wrong config directory. Updated to use
correct path relative to CODEX_HOME.
```

❌ **Bad:**
```
update stuff
```

```
fixed bug
```

```
new skill added
```

---

## Code of Conduct

### Our Standards

- **Be respectful**: Treat all contributors with respect and empathy
- **Be constructive**: Provide helpful feedback and suggestions
- **Be collaborative**: Work together to improve the project
- **Be inclusive**: Welcome contributors of all backgrounds and skill levels
- **Be professional**: Maintain professional communication in all interactions

### Unacceptable Behavior

- Harassment, discrimination, or offensive comments
- Personal attacks or trolling
- Sharing others' private information without permission
- Any conduct that would be inappropriate in a professional setting

### Enforcement

Violations may result in temporary or permanent ban from the project. Report issues to the maintainers.

---

## Security

### Security Best Practices

When contributing skills:

- **Never include credentials**: No API keys, passwords, tokens, or secrets
- **Sanitize inputs**: Validate and escape all user inputs
- **Avoid command injection**: Be cautious with shell commands and user-provided data
- **Document risks**: Clearly state security implications
- **Review dependencies**: Only use trusted libraries and tools
- **Test for vulnerabilities**: Check for common security issues (XSS, SQL injection, etc.)

### Reporting Security Issues

If you discover a security vulnerability:

1. **Do NOT** open a public issue
2. Email the maintainers privately (check README for contact)
3. Provide detailed description and steps to reproduce
4. Allow reasonable time for a fix before public disclosure

### Using Skills from Others

- **Only use skills from trusted sources**
- **Review code before running** - Especially scripts and executable files
- **Understand what skills do** - Read documentation thoroughly
- **Test in isolated environments** - Use sandboxes or containers when possible

---

## License

By contributing to Awesome Agent Skills, you agree that your contributions will be licensed under the [MIT License](LICENSE).

### What This Means

- Your contributions become part of the open-source project
- Anyone can use, modify, and distribute your contributions
- You retain copyright to your original work
- You provide contributions "as-is" without warranties

### Attribution

- Original authors will be credited in commit history
- Significant contributions may be acknowledged in README
- Derivative works should maintain attribution chain

---

## Questions?

If you have questions:

1. **Check the [README](README.md)** - Most common questions are answered there
2. **Search existing issues** - Your question may have been asked before
3. **Open a new issue** - Use the "Question" template
4. **Be specific** - Provide context and examples

---

## Thank You!

We appreciate your contributions to making agent skills more accessible and useful for everyone! 🎉

For more information:
- [README](README.md) - Project overview and getting started
- [LICENSE](LICENSE) - Full license text
- [Issues](https://github.com/junminhong/awesome-agent-skills/issues) - Bug reports and feature requests
