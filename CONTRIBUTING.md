# Contributing to BrightCloud Container Registry Platform

We love your input! We want to make contributing to the BrightCloud Container Registry Platform as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Becoming a maintainer

## We Develop with GitHub

We use GitHub to host code, to track issues and feature requests, as well as accept pull requests.

## We Use [GitHub Flow](https://guides.github.com/introduction/flow/index.html)

All code changes happen through pull requests. Pull requests are the best way to propose changes to the codebase. We actively welcome your pull requests:

1. Fork the repo and create your branch from `main`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes.
5. Make sure your code lints.
6. Issue that pull request!

## Any contributions you make will be under the MIT Software License

In short, when you submit code changes, your submissions are understood to be under the same [MIT License](LICENSE) that covers the project. Feel free to contact the maintainers if that's a concern.

## Report bugs using GitHub's [issues](https://github.com/DigitalInnovation/brightcloud-container-registry/issues)

We use GitHub issues to track public bugs. Report a bug by [opening a new issue](https://github.com/DigitalInnovation/brightcloud-container-registry/issues/new); it's that easy!

## Write bug reports with detail, background, and sample code

**Great Bug Reports** tend to have:

- A quick summary and/or background
- Steps to reproduce
  - Be specific!
  - Give sample code if you can
- What you expected would happen
- What actually happens
- Notes (possibly including why you think this might be happening, or stuff you tried that didn't work)

## Development Process

### Prerequisites

- Node.js 20+
- Terraform 1.6+
- Go 1.21+ (for testing)
- Azure CLI
- Docker

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/DigitalInnovation/brightcloud-container-registry.git
   cd brightcloud-container-registry
   ```

2. Install dependencies:
   ```bash
   # For GitHub Actions
   cd acr-image-promotion-action
   npm install
   
   # For Terraform tests
   cd ../terraform-azurerm-acr-platform/test
   go mod download
   ```

3. Set up pre-commit hooks:
   ```bash
   pre-commit install
   ```

### Code Style

#### TypeScript/JavaScript

- We use ESLint and Prettier for TypeScript/JavaScript code
- Run `npm run lint` to check for issues
- Run `npm run format` to auto-format code

#### Terraform

- We use terraform fmt for formatting
- Run `terraform fmt -recursive` in the terraform directory
- We use tflint for additional linting

#### Documentation

- Use proper Markdown formatting
- Include code examples where appropriate
- Update README files when adding new features

### Testing

#### Terraform

```bash
cd terraform-azurerm-acr-platform/test
make test
```

#### GitHub Actions

```bash
cd acr-image-promotion-action
npm test
```

### Commit Messages

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation only changes
- `style:` Changes that don't affect code meaning
- `refactor:` Code change that neither fixes a bug nor adds a feature
- `perf:` Performance improvement
- `test:` Adding missing tests
- `chore:` Changes to build process or auxiliary tools

Examples:
```
feat(terraform): add support for custom retention policies
fix(action): correct image validation regex
docs: update installation instructions
```

## Pull Request Process

1. Update the README.md with details of changes to the interface, if applicable
2. Update the documentation with any new environment variables, exposed ports, useful file locations, and container parameters
3. Increase version numbers in any examples files and the README.md to the new version that this Pull Request would represent
4. Ensure all tests pass and code coverage is maintained
5. Request review from maintainers
6. You may merge the Pull Request once you have the sign-off of two other developers

## Code Review Process

All submissions require review. We use GitHub pull request reviews to discuss and review code changes. During review, we look for:

- **Correctness**: Does the code do what it's supposed to?
- **Testing**: Are there appropriate tests?
- **Security**: Are there any security concerns?
- **Performance**: Are there any performance concerns?
- **Documentation**: Is the code well-documented?
- **Style**: Does the code follow our style guidelines?

## Security Vulnerabilities

If you discover a security vulnerability, please email security@brightcloud.example.com instead of using the issue tracker. See our [Security Policy](SECURITY.md) for more details.

## Community

- Join our [discussions](https://github.com/DigitalInnovation/brightcloud-container-registry/discussions)
- Read our [Code of Conduct](CODE_OF_CONDUCT.md)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.