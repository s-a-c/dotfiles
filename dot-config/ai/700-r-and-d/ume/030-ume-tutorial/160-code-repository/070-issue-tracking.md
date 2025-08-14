# Issue Tracking Information

<link rel="stylesheet" href="../assets/css/styles.css">

This guide provides comprehensive information about the issue tracking system used for the UME project. It covers how to report issues, understand issue statuses, work with labels, and participate effectively in the issue resolution process.

## Issue Tracking System

The UME project uses GitHub Issues for tracking bugs, feature requests, improvements, and other tasks. The issue tracker is available at:

[https://github.com/ume-tutorial/ume-core/issues](https://github.com/ume-tutorial/ume-core/issues)

## Reporting Issues

### Before Reporting

Before reporting an issue, please:

1. **Search Existing Issues**: Check if the issue has already been reported
2. **Check Documentation**: Ensure the behavior isn't documented or intentional
3. **Update Your Code**: Make sure you're using the latest version
4. **Isolate the Problem**: Create a minimal reproduction case

### Creating a New Issue

To create a new issue:

1. Go to the [Issues page](https://github.com/ume-tutorial/ume-core/issues)
2. Click "New Issue"
3. Select the appropriate issue template:
   - Bug Report
   - Feature Request
   - Documentation Issue
   - Performance Issue
   - Security Vulnerability (private)

4. Fill out all required information in the template
5. Add appropriate labels
6. Submit the issue

### Issue Templates

#### Bug Report Template

```markdown
## Description
A clear description of the bug

## Environment
- UME Version: [e.g., 1.0.0]
- Laravel Version: [e.g., 10.0.0]
- PHP Version: [e.g., 8.1.0]
- Database: [e.g., MySQL 8.0]
- Browser (if applicable): [e.g., Chrome 90]

## Steps to Reproduce
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

## Expected Behavior
A clear description of what you expected to happen

## Actual Behavior
A clear description of what actually happened

## Screenshots
If applicable, add screenshots to help explain your problem

## Additional Context
Any other context about the problem
```

#### Feature Request Template

```markdown
## Problem Statement
A clear description of the problem this feature would solve

## Proposed Solution
A clear description of what you want to happen

## Alternative Solutions
A clear description of any alternative solutions you've considered

## Additional Context
Any other context or screenshots about the feature request
```

## Understanding Issue Statuses

Issues in the UME project go through several statuses:

| Status | Description |
|--------|-------------|
| **Open** | Issue has been reported but not yet triaged |
| **Triaged** | Issue has been reviewed and confirmed |
| **In Progress** | Work on the issue has started |
| **Review Needed** | A solution has been proposed and needs review |
| **Blocked** | Progress is blocked by another issue or external factor |
| **Closed** | Issue has been resolved or determined not actionable |

## Issue Labels

The UME project uses a comprehensive labeling system to categorize issues:

### Type Labels

| Label | Description |
|-------|-------------|
| `bug` | Something isn't working as expected |
| `feature` | New feature request |
| `enhancement` | Improvement to existing functionality |
| `documentation` | Documentation-related issues |
| `question` | Further information is requested |
| `security` | Security-related issue |
| `performance` | Performance-related issue |
| `refactoring` | Code refactoring without functional changes |
| `testing` | Testing-related issues |
| `maintenance` | Repository maintenance tasks |

### Priority Labels

| Label | Description |
|-------|-------------|
| `priority:critical` | Must be fixed ASAP |
| `priority:high` | High priority, should be fixed soon |
| `priority:medium` | Normal priority |
| `priority:low` | Low priority, fix when convenient |

### Status Labels

| Label | Description |
|-------|-------------|
| `status:confirmed` | Issue has been confirmed |
| `status:in-progress` | Work is in progress |
| `status:needs-review` | Needs code review |
| `status:blocked` | Blocked by another issue |
| `status:needs-information` | More information needed |
| `status:duplicate` | Duplicate of another issue |
| `status:wontfix` | This will not be fixed |
| `status:invalid` | This isn't a valid issue |

### Component Labels

| Label | Description |
|-------|-------------|
| `component:auth` | Authentication-related |
| `component:teams` | Team functionality |
| `component:permissions` | Permission system |
| `component:ui` | User interface |
| `component:api` | API-related |
| `component:database` | Database-related |
| `component:real-time` | Real-time features |
| `component:state-machine` | State machine functionality |

### Difficulty Labels

| Label | Description |
|-------|-------------|
| `difficulty:easy` | Easy to implement, good for beginners |
| `difficulty:medium` | Moderate difficulty |
| `difficulty:hard` | Complex implementation |

### Special Labels

| Label | Description |
|-------|-------------|
| `good-first-issue` | Good for newcomers |
| `help-wanted` | Extra attention is needed |
| `hacktoberfest` | Suitable for Hacktoberfest participants |
| `breaking-change` | Introduces a breaking change |
| `dependencies` | Related to dependencies |

## Issue Assignment

### Who Can Be Assigned

Issues can be assigned to:
- Core team members
- Regular contributors
- New contributors who have expressed interest

### How to Get Assigned

To get assigned to an issue:

1. Comment on the issue expressing your interest
2. Provide any relevant experience or approach
3. Wait for a maintainer to assign you
4. If approved, the issue will be assigned to you

### Assignment Expectations

When assigned an issue:

1. Begin work within 7 days
2. Provide regular updates (at least weekly)
3. If you cannot complete the issue, notify the team
4. Create a pull request when the work is complete

## Issue Workflow

### Typical Issue Lifecycle

1. **Issue Creation**: Someone reports an issue
2. **Triage**: Maintainers review and categorize the issue
3. **Confirmation**: Issue is confirmed and prioritized
4. **Assignment**: Issue is assigned to a contributor
5. **Implementation**: Work is done to resolve the issue
6. **Pull Request**: A PR is created referencing the issue
7. **Review**: The PR is reviewed and approved
8. **Merge**: The PR is merged
9. **Closure**: The issue is closed

### Issue References

When working on issues:

1. **Reference Issues in Commits**:
   ```
   fix(auth): resolve login redirect issue (#123)
   ```

2. **Reference Issues in PRs**:
   ```
   Fixes #123
   ```
   This will automatically close the issue when the PR is merged.

3. **Reference Related Issues**:
   ```
   Related to #456
   ```
   This creates a link without closing the issue.

## Issue Prioritization

Issues are prioritized based on several factors:

1. **Severity**: How severely the issue affects users
2. **Scope**: How many users are affected
3. **Effort**: How much work is required to fix
4. **Strategic Importance**: Alignment with project goals

The priority is indicated by the priority labels.

## Issue Resolution Time

Expected resolution times by priority:

| Priority | Target Resolution Time |
|----------|------------------------|
| Critical | 1-3 days |
| High | 1-2 weeks |
| Medium | 2-4 weeks |
| Low | When resources are available |

## Issue Reporting Best Practices

### Do's

- Provide clear, concise descriptions
- Include all relevant information
- Use proper formatting for code and logs
- Attach screenshots or videos when applicable
- Be responsive to questions
- Check if the issue still exists in the latest version

### Don'ts

- Don't report multiple issues in one report
- Don't use issues for general questions (use Discussions)
- Don't assign priority labels yourself
- Don't @mention contributors unless necessary
- Don't bump issues repeatedly

## Working with Security Issues

For security vulnerabilities:

1. **Do Not** report security issues publicly
2. Use the private security vulnerability reporting feature
3. Or email [security@ume-tutorial.com](mailto:security@ume-tutorial.com)
4. Include detailed information about the vulnerability
5. If possible, include steps to reproduce

## Issue Analytics

The UME project tracks issue metrics:

- Average time to first response
- Average resolution time
- Issues by component
- Issues by priority
- Contributor participation

These metrics are reviewed monthly to improve the process.

## Issue Notifications

### Subscribing to Issues

To stay updated on issues:

1. Click "Subscribe" on individual issues
2. Watch the repository for all notifications
3. Watch releases only for version updates

### Notification Management

Manage your notification settings:

1. Go to your GitHub settings
2. Select "Notifications"
3. Configure email and web notifications
4. Set up custom routing for UME notifications

## Issue Search and Filtering

### Advanced Search

Use GitHub's advanced search to find issues:

- `is:issue is:open label:bug` - Open bug reports
- `is:issue author:username` - Issues created by a user
- `is:issue assignee:username` - Issues assigned to a user
- `is:issue milestone:v1.0` - Issues in a milestone
- `is:issue label:component:auth label:bug` - Auth-related bugs

### Saved Searches

Create saved searches for common queries:

1. Perform a search
2. Bookmark the URL
3. Use it for quick access to filtered issues

## Issue-Related Automation

The UME project uses GitHub Actions for issue automation:

1. **Issue Triage**: Automatically labels new issues
2. **Stale Issues**: Marks inactive issues as stale
3. **Issue Templates**: Enforces structured reporting
4. **Issue Linking**: Links related issues and PRs
5. **Issue Assignment**: Tracks assignment activity

## Contributing to Issue Resolution

Ways to contribute to issue resolution:

1. **Reproduce Issues**: Confirm and provide additional details
2. **Suggest Solutions**: Comment with potential approaches
3. **Test Fixes**: Verify that proposed fixes work
4. **Document Workarounds**: Share temporary solutions
5. **Improve Issue Reports**: Add missing information

## Issue Tracking Integration

The UME issue tracker integrates with:

1. **Pull Requests**: Linked to related issues
2. **Discussions**: Referenced in issue comments
3. **Project Boards**: Visual tracking of progress
4. **Milestones**: Grouping issues for releases
5. **External Tools**: API access for custom dashboards

## Getting Help with Issues

If you need help with the issue tracking system:

1. Check the [Contributing Guidelines](060-contributing-guidelines.md)
2. Ask in the GitHub Discussions
3. Contact the maintainers at [issues@ume-tutorial.com](mailto:issues@ume-tutorial.com)

## Issue Tracking Roadmap

Planned improvements to the issue tracking system:

1. Enhanced issue templates
2. Automated issue classification
3. Improved search and filtering
4. Better integration with external tools
5. More detailed issue analytics

## Conclusion

Effective issue tracking is essential for the UME project's success. By following these guidelines, you can help ensure that issues are reported, tracked, and resolved efficiently.
