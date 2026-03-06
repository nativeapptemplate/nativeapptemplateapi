# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Rails 8.0 API application that serves as the backend for NativeAppTemplate iOS/Android mobile applications. It's a multi-tenant SaaS application with token-based authentication, role-based authorization, and RESTful API endpoints. Ruby 4.0.1, PostgreSQL, Redis, Sidekiq.

## Development Commands

### Initial Setup
```bash
bin/setup  # Installs all dependencies, prepares database, builds assets
```

### Running the Application
```bash
bin/dev  # Starts Rails server, CSS watcher, JS bundler, and Sidekiq workers
```

### Testing
```bash
bin/rails test                  # Run all tests
bin/rails test test/path/to/test.rb  # Run specific test file
bin/rails test test/path/to/test.rb:42  # Run specific test line
```

### Linting & Security
```bash
bin/rubocop                     # Ruby code linting
bundle exec erb_lint --lint-all # ERB template linting
bin/brakeman                    # Security vulnerability scanning
```

### Database Operations
```bash
bin/rails db:create db:migrate  # Create and migrate database
bin/rails db:seed_fu           # Load seed data (uses seed-fu gem)
bin/rails db:reset             # Drop, create, migrate, and seed
```

### Console & Debugging
```bash
bin/rails console              # Rails console
bin/rails dbconsole           # Database console
```

## Architecture & Key Concepts

### API Structure
- All API endpoints are under `/api/v1/` namespace
- Token-based authentication using `devise_token_auth`
- Separate namespaces for different user types (e.g., `/api/v1/shopkeeper/`)
- JSON API specification for responses using `jsonapi-serializer`
- CORS enabled for cross-origin requests

### Authentication & Authorization
- **Authentication**: Devise Token Auth with headers-based token management
- **Authorization**: Pundit policies for resource-level permissions
- **Multi-tenancy**: acts_as_tenant for complete data isolation between accounts
- **RBAC**: Role and Permission models for fine-grained access control

### Key Models & Relationships
- `Account` - Top-level tenant/organization
- `Shopkeeper` - Main user type (belongs to Account)
- `Shop` - Core business entity (belongs to Account)
- `ItemTag` - Belongs to Shop with unique name constraint
- `Role` & `Permission` - Authorization system
- State machines implemented with AASM gem

### Background Processing
- Sidekiq for background jobs with Redis backend
- Queue priorities: critical (10), mailers (5), default (2), low (1)
- Monitor at `/madmin/sidekiq` in development

### Testing Strategy
- Minitest for all tests (models, controllers, integration, policies)
- WebMock for stubbing external HTTP requests
- Parallel test execution supported (10 workers by default)
- Comprehensive test coverage across all layers:
  - **Model tests**: test/models/ - Validations, associations, callbacks, state machines
  - **Policy tests**: test/policies/ - Authorization rules for all user roles
  - **Controller tests**: test/controllers/ - API endpoints, authentication, authorization
  - **Integration tests**: test/integration/ - End-to-end user flows
- Test helpers:
  - `json_response` for parsing JSON API responses
  - `create_new_auth_token` for generating auth headers (Devise Token Auth)
  - Fixtures in test/fixtures/ and seed data in db/fixtures/test/
- Run tests: `bin/rails test` (205 tests, 402 assertions)

### Development Server Configuration
- Server binds to specific IP: `192.168.1.21:3000` (not localhost)
- Mailbin for email testing at `/mailbin`
- Admin interface at `/madmin`
- Hot reload for CSS/JS changes via yarn watchers

### Important Conventions
- Use `seed-fu` for database seeding (not standard Rails seeds)
- API responses follow JSON API specification
- All API controllers inherit from `Api::V1::BaseController`
- Tenant isolation handled automatically via `AccountMiddleware`
- Image processing with Active Storage and `image_processing` gem

### Deployment
- Configured for Render.com deployment
- Build script: `bin/render-build.sh`
- Web server: `bin/render-start.sh`
- Background workers: `bin/render-start-sidekiq.sh`

## Code Quality Checks Before Committing

**IMPORTANT**: Always run these checks and fix all errors before committing code:

### 1. Lint Errors (RuboCop)
```bash
bin/rubocop
```
- Fix all RuboCop offenses before committing
- Run `bin/rubocop -a` to auto-correct safe offenses
- Review and manually fix remaining issues

### 2. Security Scan (Brakeman)
```bash
bin/brakeman
```
- Fix all security vulnerabilities before committing
- Review warnings and address potential security issues
- Never commit code with security vulnerabilities

### 3. Run Tests
```bash
bin/rails test
```
- Ensure all tests pass before committing
- Add tests for new features or bug fixes

### Pre-Commit Checklist
- [ ] `bin/rubocop` - No lint errors
- [ ] `bin/brakeman` - No security issues
- [ ] `bin/rails test` - All tests passing
- [ ] Code reviewed for quality and security

## Common Development Tasks

### Creating New API Endpoints
1. Add route in `config/routes.rb` under appropriate namespace
2. Create controller inheriting from `Api::V1::BaseController`
3. Add Pundit policy in `app/policies/` with authorization rules
4. Create serializer in `app/serializers/`
5. Write controller tests in `test/controllers/` testing all actions and edge cases

### Writing Tests
- **Model tests**: Test validations, associations, callbacks, scopes, and business logic
- **Policy tests**: Test authorization for all roles (admin, managers, members, guest)
- **Controller tests**: Test CRUD operations, authentication requirements, authorization checks
- Use `ActsAsTenant.with_tenant(@account)` when testing multi-tenant models
- Fixtures are loaded automatically from test/fixtures/*.yml
- Test data seeds loaded from db/fixtures/test/*.rb in setup hook

### Working with Multi-tenancy
- All models should include `acts_as_tenant :account`
- Current account accessible via `current_account` in controllers
- Tenant switching handled by `AccountMiddleware`

### Adding Background Jobs
1. Create job class in `app/jobs/`
2. Specify queue with `queue_as :default` (or :critical, :low, etc.)
3. Call with `MyJob.perform_later(args)`