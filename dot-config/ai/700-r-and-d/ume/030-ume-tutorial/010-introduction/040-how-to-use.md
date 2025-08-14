# How to Use This Tutorial

<link rel="stylesheet" href="../assets/css/styles.css">

This document is structured as a curriculum. To get the most out of it, follow these guidelines:

## Follow the Steps Sequentially

Each phase builds upon the previous one, so it's important to follow the steps in order. Within each phase, the steps are designed to be completed sequentially.

## UI Implementation Paths

- **Primary Path:** The main instructions assume you are building the user-facing UI with **Livewire/Volt and Flux UI**.
- **Admin Interface:** We use **FilamentPHP** for building administrative interfaces.
- **Alternative UI Sections:** Where frontend implementation differs significantly, specific sections are provided for:
  - **Inertia/React:** For user-facing UI using React.
  - **Inertia/Vue:** For user-facing UI using Vue.

You can focus on the Livewire/Flux UI path and refer to the others, or attempt to implement one of the alternative stacks if you prefer.

## Read Carefully

Pay attention to the explanations – they provide context and reasoning behind the code. Understanding the "why" is just as important as the "how."

## Code Along

Type the commands and code yourself rather than just copy-pasting (though full code is provided). This builds muscle memory and helps you internalize the concepts.

## Verify Each Step

Use the "Verification" sections to ensure things are working as expected before moving on. These sections provide specific tests and expected outcomes.

## Consult the Glossary & Appendix

If you encounter an unfamiliar term, check the Glossary in the Appendix. The Appendix also contains links to official documentation cited throughout the tutorial.

## Experiment

Don't be afraid to tinker! Try changing things slightly (after committing your working code with Git!) to see what happens. That's a great way to learn.

## Take Your Time

Learning takes time. If you get stuck, reread the relevant section, check the verification steps, or consult the official Laravel documentation (linked in the Appendix).

## Implementation Structure

Each implementation step follows this structure:

1. **Goal**: What you'll accomplish in this step
2. **Prerequisites**: What needs to be in place before starting
3. **Implementation**: Step-by-step instructions
4. **Verification**: How to test that the step was completed successfully
5. **Troubleshooting**: Common issues and solutions
6. **Next Steps**: What to do after completing this step

## Testing Strategy

Each feature includes:

1. **Unit Tests**: Testing individual components in isolation
2. **Feature Tests**: Testing how components work together
3. **Browser Tests**: Testing the user interface and interactions

## Git Workflow

We recommend committing your code after completing each major milestone. This allows you to revert to a working state if something goes wrong.

```bash
git add .
git commit -m "Completed Phase X, Milestone Y: Brief description"
```

## Getting Help

If you get stuck:

1. Check the troubleshooting section for the current step
2. Review the verification steps to ensure previous steps were completed correctly
3. Consult the official documentation for the relevant packages
4. Search for similar issues on Stack Overflow or Laravel forums

Now that you understand how to use this tutorial, let's move on to setting up your development environment in the [Prerequisites](../020-prerequisites/000-index.md) section.
