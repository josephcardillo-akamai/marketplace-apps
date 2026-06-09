# Setup Cloud Manager Development Environment

Automated setup for Linode Cloud Manager development environment with marketplace app testing capabilities.

## Usage

```bash
/setup-cloud-manager-dev [options]
```

## Options

- `--oauth-id <id>` - Your Linode OAuth Client ID
- `--skip-oauth` - Skip OAuth app creation prompts
- `--minimal` - Install minimal dependencies only
- `--fork-url <url>` - Use specific fork URL instead of prompting
- `--workspace <path>` - Set workspace directory (default: ~/cloud-manager-dev)

## What This Command Does

1. **System Requirements Check**
   - Verifies Node.js version compatibility
   - Checks for required tools (git, curl)
   - Validates system resources (RAM, disk space)

2. **Repository Setup**
   - Guides through forking the manager repository
   - Clones your fork locally
   - Sets up upstream remote
   - Creates development branch

3. **Environment Configuration**
   - Installs Volta (Node.js version manager)
   - Installs Node.js 20.17 LTS
   - Installs pnpm v10
   - Configures environment variables

4. **OAuth Application Setup**
   - Provides step-by-step OAuth app creation guide
   - Validates OAuth configuration
   - Sets up .env file with credentials

5. **Development Dependencies**
   - Runs pnpm bootstrap
   - Verifies all packages build successfully
   - Sets up development tools and extensions

6. **Testing & Validation**
   - Starts development server
   - Runs basic health checks
   - Validates API connectivity
   - Provides troubleshooting guidance

## Examples

```bash
# Complete automated setup
/setup-cloud-manager-dev --oauth-id abc123def456

# Interactive setup with prompts
/setup-cloud-manager-dev

# Minimal setup for CI/testing
/setup-cloud-manager-dev --minimal --skip-oauth

# Custom workspace location
/setup-cloud-manager-dev --workspace ~/projects/linode-dev
```

## Prerequisites

- macOS, Linux, or WSL2 on Windows
- 8GB+ RAM (16GB recommended)
- 10GB+ free disk space
- Stable internet connection
- Linode account for OAuth app creation

## Troubleshooting

If the setup fails, the command will:
- Provide specific error messages
- Suggest common fixes
- Create a troubleshooting log
- Offer manual setup alternatives

## Post-Setup

After successful setup, you'll have:
- Complete Cloud Manager development environment
- Running dev server at http://localhost:3000
- All dependencies installed and configured
- Ready for marketplace app development

The command will provide next steps for:
- Creating your first marketplace app
- Understanding the codebase structure
- Setting up additional development tools
- Joining the development workflow