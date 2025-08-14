# Welcome

<link rel="stylesheet" href="../assets/css/styles.css">

## Hello and Welcome!

If you're reading this, you're likely a developer with some basic PHP knowledge, ready to dive deeper into building web applications with the latest version of one of the most popular PHP frameworks: **Laravel 12**. This tutorial is designed specifically for you – the **lone novice developer** embarking on adding a significant set of features to a web application.

Our goal is ambitious but achievable: we'll take a set of requirements for enhancing user management features (we'll call this **User Model Enhancements** or **UME**) and build it step-by-step using modern Laravel practices.

<div class="highlight-box">
A core focus of this tutorial is implementing <strong>Single Table Inheritance (STI)</strong> for the User model from the outset. This allows us to elegantly manage different user types (like <span class="primary-text">Admin</span>, <span class="secondary-text">Manager</span>, <span class="accent-text">Practitioner</span>, and regular <span class="info-text">User</span>) within a single <code>users</code> table, leveraging the powerful <span class="primary-text">tightenco/parental</span> package.
</div>

Beyond STI, we'll build detailed user profiles, avatars, teams, roles & permissions within those teams, security features like Two-Factor Authentication (2FA), and even real-time features like online presence indicators and basic chat!

## Key Features of This Tutorial

* Targets **Laravel 12**.
* Implements **Single Table Inheritance** for the `User` model using `tightenco/parental` as a foundational element.
* Uses **Livewire/Volt** with Single File Components (SFCs) as the **primary** user-facing frontend stack.
* Integrates **Flux UI** components for a polished, professional user interface.
* Includes dedicated sections showing alternative implementations for **FilamentPHP** (for admin interfaces), **Inertia.js with React**, and **Inertia.js with Vue** where UI is involved.
* Utilizes **Tailwind CSS v4** (the default for Laravel 12 starter kits).
* Starts with a minimal Laravel 12 installation and adds **Laravel Breeze** for basic auth scaffolding.
* Adds **inline citations** with links to official documentation for package installations and configurations.
* Includes a **Citation Appendix**.

## What Makes This Tutorial Different?

This tutorial is designed with several key principles in mind:

1. **Bite-sized, incremental steps** - Each implementation step is designed to be manageable and results in a working application with a complete test suite.

2. **Multiple UI approaches** - We provide implementations for Livewire/Volt with Flux UI (primary), FilamentPHP (admin), and alternative paths for Inertia.js with React or Vue.

3. **Comprehensive testing** - Each feature includes unit, feature, and browser tests to ensure functionality and demonstrate best practices.

4. **Real-world architecture** - We use architectural patterns and practices that scale well for larger applications, not just simplified examples.

5. **Detailed explanations** - We don't just show you the code, we explain the "why" behind each decision.

Let's continue to explore what we'll be building in this tutorial.
