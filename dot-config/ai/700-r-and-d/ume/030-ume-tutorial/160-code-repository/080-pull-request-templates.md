# Pull Request Templates

<link rel="stylesheet" href="../assets/css/styles.css">

This guide provides pull request templates for the UME project. These templates help ensure that pull requests contain all necessary information for efficient review and integration.

## Using Pull Request Templates

When creating a pull request on GitHub, you'll be prompted to select a template. Choose the template that best matches the type of change you're making. If none of the templates fit your specific case, you can use the general template.

## Template Location

Pull request templates are stored in the `.github/PULL_REQUEST_TEMPLATE/` directory of the repository. The following templates are available:

1. Feature template
2. Bug fix template
3. Documentation template
4. Refactoring template
5. Performance improvement template
6. Security fix template
7. General template (default)

## Feature Template

```markdown
# Feature Pull Request

## Description
<!-- Provide a detailed description of the changes introduced by this feature -->

## Related Issues
<!-- List any related issues using the format: "Closes #123" or "Related to #456" -->

## Type of Change
- [x] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)

## Feature Checklist
- [ ] I have added tests that prove my feature works
- [ ] I have added necessary documentation
- [ ] I have updated the CHANGELOG.md file
- [ ] I have updated any related feature flags
- [ ] I have added any necessary database migrations
- [ ] I have considered backward compatibility
- [ ] I have considered security implications

## Screenshots/Recordings
<!-- If applicable, add screenshots or screen recordings to demonstrate the feature -->

## Implementation Details
<!-- Provide technical details about the implementation that would help reviewers -->

## Potential Risks
<!-- Describe any potential risks or side effects of this change -->

## Deployment Notes
<!-- Note any special considerations for deploying this feature -->

## Additional Information
<!-- Any additional information that might be helpful for reviewers -->
```

## Bug Fix Template

```markdown
# Bug Fix Pull Request

## Description
<!-- Provide a detailed description of the bug and how this PR fixes it -->

## Related Issues
<!-- List any related issues using the format: "Fixes #123" -->

## Type of Change
- [x] Bug fix (non-breaking change which fixes an issue)
- [ ] Breaking change (fix that would cause existing functionality to not work as expected)

## Bug Fix Checklist
- [ ] I have added tests that prove my fix is effective
- [ ] I have verified the fix in multiple environments
- [ ] I have updated the CHANGELOG.md file
- [ ] I have updated any related documentation
- [ ] I have considered backward compatibility
- [ ] I have considered security implications

## Root Cause Analysis
<!-- Describe what caused the bug -->

## Fix Description
<!-- Explain how your solution fixes the issue -->

## Verification Steps
<!-- Steps to verify that the bug is fixed -->

## Screenshots/Recordings
<!-- If applicable, add screenshots or screen recordings to demonstrate the fix -->

## Additional Information
<!-- Any additional information that might be helpful for reviewers -->
```

## Documentation Template

```markdown
# Documentation Pull Request

## Description
<!-- Provide a detailed description of the documentation changes -->

## Related Issues
<!-- List any related issues using the format: "Closes #123" or "Related to #456" -->

## Type of Change
- [x] Documentation update (changes to documentation only)
- [ ] Documentation for new feature
- [ ] Documentation fix (correcting errors or omissions)

## Documentation Checklist
- [ ] I have verified all information is accurate
- [ ] I have checked for spelling and grammar errors
- [ ] I have used consistent terminology
- [ ] I have tested any code examples
- [ ] I have updated any related cross-references
- [ ] I have considered internationalization implications

## Screenshots
<!-- If applicable, add screenshots to demonstrate the documentation changes -->

## Additional Information
<!-- Any additional information that might be helpful for reviewers -->
```

## Refactoring Template

```markdown
# Refactoring Pull Request

## Description
<!-- Provide a detailed description of the refactoring changes -->

## Related Issues
<!-- List any related issues using the format: "Closes #123" or "Related to #456" -->

## Type of Change
- [x] Code refactoring (non-breaking change that improves code quality)
- [ ] Performance improvement (non-breaking change that improves performance)
- [ ] Breaking refactoring (refactoring that would cause existing functionality to not work as expected)

## Refactoring Checklist
- [ ] I have added tests that prove my refactoring doesn't change functionality
- [ ] I have updated any necessary documentation
- [ ] I have updated the CHANGELOG.md file
- [ ] I have considered backward compatibility
- [ ] I have considered performance implications
- [ ] I have considered security implications

## Before and After
<!-- Provide code snippets or descriptions of before and after the refactoring -->

## Motivation
<!-- Explain why this refactoring is necessary -->

## Technical Details
<!-- Provide technical details about the refactoring approach -->

## Additional Information
<!-- Any additional information that might be helpful for reviewers -->
```

## Performance Improvement Template

```markdown
# Performance Improvement Pull Request

## Description
<!-- Provide a detailed description of the performance improvements -->

## Related Issues
<!-- List any related issues using the format: "Closes #123" or "Related to #456" -->

## Type of Change
- [x] Performance improvement (non-breaking change that improves performance)
- [ ] Breaking change (improvement that would cause existing functionality to not work as expected)

## Performance Improvement Checklist
- [ ] I have added benchmarks that demonstrate the improvement
- [ ] I have tested the improvement in multiple environments
- [ ] I have updated any necessary documentation
- [ ] I have updated the CHANGELOG.md file
- [ ] I have considered backward compatibility
- [ ] I have considered security implications

## Benchmark Results
<!-- Provide before and after benchmark results -->

## Implementation Details
<!-- Provide technical details about the implementation -->

## Potential Risks
<!-- Describe any potential risks or side effects of this change -->

## Additional Information
<!-- Any additional information that might be helpful for reviewers -->
```

## Security Fix Template

```markdown
# Security Fix Pull Request

## Description
<!-- Provide a detailed description of the security vulnerability and how this PR fixes it -->

## Related Issues
<!-- List any related issues using the format: "Fixes #123" -->

## Type of Change
- [x] Security fix (non-breaking change which fixes a security issue)
- [ ] Breaking change (fix that would cause existing functionality to not work as expected)

## Security Fix Checklist
- [ ] I have added tests that prove my fix is effective
- [ ] I have verified the fix in multiple environments
- [ ] I have updated the CHANGELOG.md file
- [ ] I have updated any related documentation
- [ ] I have considered backward compatibility
- [ ] I have considered other security implications

## Vulnerability Details
<!-- Describe the vulnerability (be careful not to disclose exploitation details if the fix isn't released yet) -->

## Fix Description
<!-- Explain how your solution fixes the vulnerability -->

## Verification Steps
<!-- Steps to verify that the vulnerability is fixed -->

## Additional Information
<!-- Any additional information that might be helpful for reviewers -->
```

## General Template (Default)

```markdown
# Pull Request

## Description
<!-- Provide a detailed description of the changes in this PR -->

## Related Issues
<!-- List any related issues using the format: "Closes #123" or "Related to #456" -->

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Code refactoring
- [ ] Performance improvement
- [ ] Security fix
- [ ] Other (please describe)

## Checklist
- [ ] I have added tests that prove my fix/feature works
- [ ] I have updated any necessary documentation
- [ ] I have updated the CHANGELOG.md file
- [ ] I have considered backward compatibility
- [ ] I have considered security implications
- [ ] I have verified my changes in multiple environments

## Screenshots/Recordings
<!-- If applicable, add screenshots or screen recordings to demonstrate the changes -->

## Implementation Details
<!-- Provide technical details about the implementation -->

## Additional Information
<!-- Any additional information that might be helpful for reviewers -->
```

## Setting Up Pull Request Templates in Your Repository

To set up these templates in your repository:

1. Create a `.github/PULL_REQUEST_TEMPLATE/` directory in your repository
2. Add each template as a separate Markdown file:
   - `feature.md`
   - `bugfix.md`
   - `documentation.md`
   - `refactoring.md`
   - `performance.md`
   - `security.md`
   - `general.md` (default)

3. Create a `.github/pull_request_template.md` file that references the templates:

```markdown
<!-- 
Please use one of the following templates for your pull request:
- Feature: .github/PULL_REQUEST_TEMPLATE/feature.md
- Bug Fix: .github/PULL_REQUEST_TEMPLATE/bugfix.md
- Documentation: .github/PULL_REQUEST_TEMPLATE/documentation.md
- Refactoring: .github/PULL_REQUEST_TEMPLATE/refactoring.md
- Performance: .github/PULL_REQUEST_TEMPLATE/performance.md
- Security: .github/PULL_REQUEST_TEMPLATE/security.md

If none of these templates fit your PR, please use the general template.
-->

# Pull Request

## Description
<!-- Provide a detailed description of the changes in this PR -->

## Related Issues
<!-- List any related issues using the format: "Closes #123" or "Related to #456" -->

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Code refactoring
- [ ] Performance improvement
- [ ] Security fix
- [ ] Other (please describe)

## Checklist
- [ ] I have added tests that prove my fix/feature works
- [ ] I have updated any necessary documentation
- [ ] I have updated the CHANGELOG.md file
- [ ] I have considered backward compatibility
- [ ] I have considered security implications
- [ ] I have verified my changes in multiple environments

## Screenshots/Recordings
<!-- If applicable, add screenshots or screen recordings to demonstrate the changes -->

## Implementation Details
<!-- Provide technical details about the implementation -->

## Additional Information
<!-- Any additional information that might be helpful for reviewers -->
```

## Best Practices for Pull Requests

### Writing a Good PR Description

1. **Be Specific**: Clearly describe what changes you've made and why
2. **Link Issues**: Always reference related issues
3. **Highlight Key Changes**: Call attention to important changes
4. **Explain Decisions**: Document why you chose a particular approach
5. **Note Limitations**: Mention any known limitations or future work

### PR Size Guidelines

1. **Keep PRs Small**: Aim for less than 500 lines of code changes
2. **Single Purpose**: Each PR should address a single concern
3. **Split Large Changes**: Break large features into smaller, logical PRs
4. **Incremental Approach**: Submit incremental changes when possible

### PR Review Process

1. **Self-Review**: Review your own PR before requesting reviews
2. **Address Feedback**: Respond to all review comments
3. **Update Description**: Keep the PR description updated with changes
4. **Resolve Conflicts**: Promptly resolve any merge conflicts
5. **CI Checks**: Ensure all CI checks pass before merging

### After Submitting a PR

1. **Be Responsive**: Respond to review comments promptly
2. **Update Tests**: Add or update tests as needed
3. **Document Changes**: Update documentation to reflect changes
4. **Squash Commits**: Consider squashing commits before merging
5. **Clean Up**: Delete the branch after merging

## PR Approval Requirements

For a PR to be approved and merged:

1. At least one approval from a core team member
2. All CI checks must pass
3. No unresolved conversations
4. Up-to-date with the base branch
5. Meets the project's coding standards
6. Includes appropriate tests
7. Documentation is updated

## PR Labels

PRs may be labeled to indicate their status:

| Label | Description |
|-------|-------------|
| `needs-review` | Ready for review |
| `work-in-progress` | Not ready for review yet |
| `needs-changes` | Changes requested during review |
| `ready-to-merge` | Approved and ready to merge |
| `do-not-merge` | Should not be merged yet |

## PR Templates Customization

These templates can be customized to fit your project's specific needs. Consider:

1. Adding project-specific checklist items
2. Including links to relevant documentation
3. Adding custom sections for your workflow
4. Adjusting the level of detail required

## Conclusion

Using these pull request templates will help ensure that all contributions to the UME project are well-documented and follow a consistent format, making the review process more efficient and effective.
