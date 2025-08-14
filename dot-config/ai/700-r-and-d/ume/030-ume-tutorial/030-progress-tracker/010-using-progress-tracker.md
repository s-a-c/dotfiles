# Using the Progress Tracker

<link rel="stylesheet" href="../assets/css/styles.css">

The Progress Tracker is designed to help you keep track of your progress through the UME tutorial. This page explains how to use it effectively.

## Marking Items as Complete

As you complete each step in the tutorial, you can mark it as done by changing the `[ ]` to `[✅]` in the progress tracker file. This provides a visual indication of your progress and helps you pick up where you left off.

```markdown
<li><span class="done">[✅]</span> <strong>0.1:</strong> Create Laravel 12 Project</li>
```

## Progress States

The progress tracker uses three states:

1. **Done** `[✅]` - Steps you have completed
2. **Pending** `[❌]` - Steps that are blocked or have issues
3. **Next** `[ ]` - Steps that are yet to be completed

## Tracking Dependencies

The progress tracker is organized hierarchically, with phases containing multiple steps. This helps you understand the dependencies between steps:

- You should complete all steps in a phase before moving to the next phase
- Within a phase, steps should be completed in order
- If a step is blocked, you can mark it as pending and come back to it later

## Customizing the Tracker

You can customize the progress tracker to suit your needs:

- Add notes to steps for personal reference
- Add additional sub-steps for complex tasks
- Adjust the order of steps if you prefer a different approach

## Sharing Your Progress

The progress tracker can be useful for sharing your progress with others:

- Include it in your project documentation
- Share it with team members or mentors
- Use it to track progress across multiple sessions

## Example Usage

Here's an example of how to use the progress tracker:

1. Start at the beginning of Phase 0
2. Complete each step in order
3. Mark each step as done as you complete it
4. If you encounter issues, mark the step as pending and add a note
5. Continue to the next phase when all steps in the current phase are complete

```markdown
<ul class="progress-tracker">
<li><span class="done">[✅]</span> <strong>Phase 0: Laying the Foundation</strong>
    <ul>
    <li><span class="done">[✅]</span> <strong>0.1:</strong> Create Laravel 12 Project</li>
    <li><span class="done">[✅]</span> <strong>0.2:</strong> Configure Environment</li>
    <li><span class="pending">[❌]</span> <strong>0.3:</strong> Install FilamentPHP (Issue with PHP version)</li>
    <li><span class="next">[ ]</span> <strong>0.4:</strong> Install Core Backend Packages</li>
    </ul>
</li>
</ul>
```

## Next Steps

Now that you understand how to use the progress tracker, you can start tracking your progress through the tutorial. Return to the [Progress Tracker](./000-index.md) to begin.
