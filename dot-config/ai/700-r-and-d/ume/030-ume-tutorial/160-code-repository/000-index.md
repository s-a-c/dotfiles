# Code Repository Index

<link rel="stylesheet" href="../assets/css/styles.css">

This index provides a centralized reference to all code repositories related to the UME tutorial. These repositories contain the complete source code for the examples, exercises, and projects discussed throughout the tutorial.

## Main Repositories

| Repository | Description | URL |
|------------|-------------|-----|
| UME Core | Core implementation of the UME system | [github.com/ume-tutorial/ume-core](https://github.com/ume-tutorial/ume-core) |
| UME Demo | Complete demo application showcasing all features | [github.com/ume-tutorial/ume-demo](https://github.com/ume-tutorial/ume-demo) |
| UME Starter | Starter template for new UME projects | [github.com/ume-tutorial/ume-starter](https://github.com/ume-tutorial/ume-starter) |
| UME Documentation | Source for this documentation | [github.com/ume-tutorial/ume-docs](https://github.com/ume-tutorial/ume-docs) |

## Phase-Specific Repositories

Each implementation phase has its own repository with the code specific to that phase:

| Phase | Repository | Description | URL |
|-------|------------|-------------|-----|
| Foundation | UME Foundation | Basic setup and configuration | [github.com/ume-tutorial/ume-foundation](https://github.com/ume-tutorial/ume-foundation) |
| Core Models | UME Core Models | User models and STI implementation | [github.com/ume-tutorial/ume-core-models](https://github.com/ume-tutorial/ume-core-models) |
| Auth & Profiles | UME Auth | Authentication and profile management | [github.com/ume-tutorial/ume-auth](https://github.com/ume-tutorial/ume-auth) |
| Teams & Permissions | UME Teams | Team and permission implementation | [github.com/ume-tutorial/ume-teams](https://github.com/ume-tutorial/ume-teams) |
| Real-time Features | UME Real-time | WebSocket and real-time features | [github.com/ume-tutorial/ume-realtime](https://github.com/ume-tutorial/ume-realtime) |
| Advanced Features | UME Advanced | Advanced features and optimizations | [github.com/ume-tutorial/ume-advanced](https://github.com/ume-tutorial/ume-advanced) |
| Polishing | UME Polishing | Final polishing and refinements | [github.com/ume-tutorial/ume-polishing](https://github.com/ume-tutorial/ume-polishing) |

## Component Repositories

Individual components of the UME system are available as separate packages:

| Component | Description | URL |
|-----------|-------------|-----|
| UME STI | Single Table Inheritance implementation | [github.com/ume-tutorial/ume-sti](https://github.com/ume-tutorial/ume-sti) |
| UME ULID | ULID implementation for models | [github.com/ume-tutorial/ume-ulid](https://github.com/ume-tutorial/ume-ulid) |
| UME User Tracking | User tracking trait implementation | [github.com/ume-tutorial/ume-user-tracking](https://github.com/ume-tutorial/ume-user-tracking) |
| UME State Machine | State machine implementation | [github.com/ume-tutorial/ume-state-machine](https://github.com/ume-tutorial/ume-state-machine) |
| UME Team Permissions | Team-based permission implementation | [github.com/ume-tutorial/ume-team-permissions](https://github.com/ume-tutorial/ume-team-permissions) |
| UME Real-time | Real-time feature implementation | [github.com/ume-tutorial/ume-realtime-package](https://github.com/ume-tutorial/ume-realtime-package) |

## Example Project Repositories

Complete example projects implementing the UME system:

| Project | Description | URL |
|---------|-------------|-----|
| UME Team Collaboration | Team collaboration platform | [github.com/ume-tutorial/ume-team-collab](https://github.com/ume-tutorial/ume-team-collab) |
| UME Multi-tenant SaaS | Multi-tenant SaaS application | [github.com/ume-tutorial/ume-saas](https://github.com/ume-tutorial/ume-saas) |
| UME E-commerce | E-commerce platform with user roles | [github.com/ume-tutorial/ume-ecommerce](https://github.com/ume-tutorial/ume-ecommerce) |
| UME CMS | Content management system | [github.com/ume-tutorial/ume-cms](https://github.com/ume-tutorial/ume-cms) |

## Exercise Repositories

Repositories containing the exercises from the tutorial:

| Exercise Set | Description | URL |
|--------------|-------------|-----|
| UME Exercises | All exercises from the tutorial | [github.com/ume-tutorial/ume-exercises](https://github.com/ume-tutorial/ume-exercises) |
| UME Exercise Solutions | Solutions to all exercises | [github.com/ume-tutorial/ume-exercise-solutions](https://github.com/ume-tutorial/ume-exercise-solutions) |

## How to Use These Repositories

### Cloning a Repository

To clone a repository, use the following command:

```bash
git clone https://github.com/ume-tutorial/repository-name.git
```

Replace `repository-name` with the name of the repository you want to clone.

### Switching Between Implementation Phases

Each phase repository has branches for different stages of implementation:

```bash
# Clone the repository
git clone https://github.com/ume-tutorial/ume-core-models.git

# List available branches
git branch -a

# Switch to a specific branch
git checkout phase1-step3
```

### Installing Dependencies

After cloning a repository, install the dependencies:

```bash
composer install
npm install
```

### Setting Up the Environment

Copy the example environment file and configure it:

```bash
cp .env.example .env
php artisan key:generate
```

### Running the Application

Start the development server:

```bash
php artisan serve
```

## Branch Information

Each repository follows a consistent branching strategy:

| Branch | Description |
|--------|-------------|
| `main` | Stable, production-ready code |
| `develop` | Development branch with latest features |
| `phase{n}-step{m}` | Specific implementation step in a phase |
| `feature/{name}` | Feature branch for specific features |
| `bugfix/{name}` | Bug fix branch for specific issues |

## Contributing to the Repositories

We welcome contributions to the UME repositories. To contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please read the [Contributing Guidelines](010-contributing-guidelines.md) before submitting a pull request.

## Repository Access

All repositories are publicly accessible on GitHub. Some repositories may require authentication for certain operations.

For access to private repositories or to become a contributor, please contact the UME team at [repositories@ume-tutorial.com](mailto:repositories@ume-tutorial.com).

## Repository Updates

Repositories are regularly updated with new features, bug fixes, and improvements. To stay up-to-date:

```bash
git pull origin main
```

Subscribe to repository notifications on GitHub to receive updates when changes are made.

## Repository Issues and Support

If you encounter issues with any repository, please open an issue on the GitHub repository page. For general support, contact [support@ume-tutorial.com](mailto:support@ume-tutorial.com).
