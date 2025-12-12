# TypeScript and AWS CDK Patterns - Infrastructure as Code

This document captures design patterns for building AWS infrastructure using TypeScript and AWS CDK (Cloud Development Kit), including construct design, helper script automation, and DevOps workflows.

## Table of Contents

- [Project Structure](#project-structure)
- [AWS CDK Construct Patterns](#aws-cdk-construct-patterns)
- [TypeScript Coding Conventions](#typescript-coding-conventions)
- [Props and Configuration Patterns](#props-and-configuration-patterns)
- [Helper Script Patterns](#helper-script-patterns)
- [DevOps Automation](#devops-automation)
- [Testing Patterns](#testing-patterns)
- [Best Practices](#best-practices)

## Project Structure

### CDK Project Organization

```
project/
├── package.json              # Dependencies and scripts
├── tsconfig.json            # TypeScript configuration
├── tsup.config.ts          # Build configuration
├── vitest.config.ts        # Test configuration
├── helper.sh               # DevOps automation script
├── pipeline.yml            # CI/CD configuration
├── integ.config.json       # Integration test config
├── src/
│   ├── index.ts            # Main exports
│   ├── commons/            # Shared utilities
│   │   ├── constants.ts    # Constants and enums
│   │   ├── props.ts        # Shared prop interfaces
│   │   ├── utils.ts        # Utility functions
│   │   └── parameterReader.ts  # SSM/Parameter reading
│   └── constructs/         # CDK constructs
│       ├── base.ts         # Base construct class
│       └── *.ts            # Specific constructs
├── test/
│   ├── unit/              # Unit tests
│   └── integ/             # Integration tests
├── assets/                # Static assets
├── dist/                  # Build output
└── coverage/              # Test coverage reports
```

**Key principles:**
- Separate `commons/` for reusable utilities
- Separate `constructs/` for CDK constructs
- Co-locate tests with source
- Use `helper.sh` for all automation

## AWS CDK Construct Patterns

### Base Construct Pattern

Create a base construct that all custom constructs extend:

```typescript
import { Construct } from 'constructs';
import { Stack, StackProps } from 'aws-cdk-lib';

/**
 * Base construct providing common functionality.
 * All custom constructs should extend this to ensure consistency.
 */
export abstract class BaseConstruct extends Construct {
  protected readonly stack: Stack;
  protected readonly props: BaseConstructProps;

  constructor(scope: Construct, id: string, props: BaseConstructProps) {
    super(scope, id);

    this.stack = Stack.of(this);
    this.props = props;

    // Common initialization
    this.validateProps();
    this.applyTags();
  }

  /**
   * Validate props before construct creation.
   * Override in subclasses for specific validation.
   */
  protected validateProps(): void {
    if (!this.props.environment) {
      throw new Error('Environment must be specified');
    }
  }

  /**
   * Apply standard tags to all resources.
   */
  protected applyTags(): void {
    const { environment, projectName, owner } = this.props;

    cdk.Tags.of(this).add('Environment', environment);
    cdk.Tags.of(this).add('Project', projectName);
    cdk.Tags.of(this).add('ManagedBy', 'CDK');
    if (owner) {
      cdk.Tags.of(this).add('Owner', owner);
    }
  }

  /**
   * Get resource name with consistent naming convention.
   */
  protected getResourceName(resourceType: string, suffix?: string): string {
    const parts = [
      this.props.projectName,
      this.props.environment,
      resourceType,
      suffix
    ].filter(Boolean);

    return parts.join('-');
  }
}
```

**Key principles:**
- All constructs extend `BaseConstruct`
- Enforce prop validation in base
- Centralize tagging strategy
- Provide consistent naming utilities
- **Open-Closed**: Add new constructs without modifying base

### Custom Construct Pattern

```typescript
import { BaseConstruct } from './base';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';

export interface ServiceConstructProps extends BaseConstructProps {
  readonly vpc: ec2.IVpc;
  readonly cluster: ecs.ICluster;
  readonly serviceName: string;
  readonly cpu?: number;
  readonly memory?: number;
  readonly desiredCount?: number;
}

/**
 * Custom construct for ECS service with sensible defaults.
 */
export class ServiceConstruct extends BaseConstruct {
  public readonly service: ecs.FargateService;
  public readonly taskDefinition: ecs.FargateTaskDefinition;

  constructor(scope: Construct, id: string, props: ServiceConstructProps) {
    super(scope, id, props);

    this.taskDefinition = this.createTaskDefinition();
    this.service = this.createService();
  }

  private createTaskDefinition(): ecs.FargateTaskDefinition {
    const props = this.props as ServiceConstructProps;

    return new ecs.FargateTaskDefinition(this, 'TaskDef', {
      cpu: props.cpu ?? 256,
      memoryLimitMiB: props.memory ?? 512,
      family: this.getResourceName('task', props.serviceName),
    });
  }

  private createService(): ecs.FargateService {
    const props = this.props as ServiceConstructProps;

    return new ecs.FargateService(this, 'Service', {
      cluster: props.cluster,
      taskDefinition: this.taskDefinition,
      desiredCount: props.desiredCount ?? 2,
      serviceName: this.getResourceName('service', props.serviceName),
    });
  }
}
```

**Key principles:**
- Extend `BaseConstruct` for consistency
- Use typed props interfaces
- Provide sensible defaults
- Expose created resources as public readonly
- Use private methods for resource creation
- Follow naming conventions

## TypeScript Coding Conventions

### Type Safety and Interfaces

```typescript
// Use readonly for immutability
export interface AppConfig {
  readonly environment: string;
  readonly region: string;
  readonly accountId: string;
  readonly tags?: Record<string, string>;
}

// Use enums for fixed values
export enum Environment {
  DEV = 'dev',
  STAGING = 'staging',
  PROD = 'prod',
}

// Use union types for flexibility
export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

// Use generics for reusability
export interface ResourceReader<T> {
  read(path: string): Promise<T>;
  readSync(path: string): T;
}
```

### Constants Pattern

```typescript
/**
 * Application-wide constants.
 * Use const assertions for type safety.
 */
export const CONSTANTS = {
  // Naming
  PREFIX: 'myapp',
  SEPARATOR: '-',

  // Regions
  REGIONS: {
    PRIMARY: 'us-east-1',
    SECONDARY: 'eu-west-1',
  } as const,

  // Limits
  MAX_RETRIES: 3,
  TIMEOUT_SECONDS: 300,

  // Tags
  TAG_KEYS: {
    ENVIRONMENT: 'Environment',
    PROJECT: 'Project',
    MANAGED_BY: 'ManagedBy',
  } as const,
} as const;

// Type derived from constants
export type Region = typeof CONSTANTS.REGIONS[keyof typeof CONSTANTS.REGIONS];
```

**Key principles:**
- Use `as const` for immutable constants
- Group related constants
- Derive types from constants
- Use UPPER_CASE for constants

### Utility Functions

```typescript
/**
 * Utility functions for common operations.
 */
export class Utils {
  /**
   * Parse environment from context or default.
   */
  static getEnvironment(app: cdk.App, defaultEnv: string = 'dev'): string {
    return app.node.tryGetContext('environment') ?? defaultEnv;
  }

  /**
   * Build resource name with consistent format.
   */
  static buildResourceName(
    project: string,
    environment: string,
    resourceType: string,
    suffix?: string
  ): string {
    const parts = [project, environment, resourceType, suffix].filter(Boolean);
    return parts.join(CONSTANTS.SEPARATOR);
  }

  /**
   * Read JSON file with type safety.
   */
  static readJsonFile<T>(filePath: string): T {
    const content = fs.readFileSync(filePath, 'utf-8');
    return JSON.parse(content) as T;
  }

  /**
   * Get SSM parameter value.
   */
  static getParameter(scope: Construct, parameterName: string): string {
    return ssm.StringParameter.valueFromLookup(scope, parameterName);
  }
}
```

## Props and Configuration Patterns

### Hierarchical Props Pattern

```typescript
/**
 * Base props required by all constructs.
 */
export interface BaseConstructProps {
  readonly environment: Environment;
  readonly projectName: string;
  readonly owner?: string;
  readonly tags?: Record<string, string>;
}

/**
 * Network-related props.
 */
export interface NetworkProps extends BaseConstructProps {
  readonly vpcId: string;
  readonly subnetIds: string[];
  readonly securityGroupIds?: string[];
}

/**
 * Service-specific props.
 */
export interface ServiceProps extends NetworkProps {
  readonly serviceName: string;
  readonly containerImage: string;
  readonly cpu?: number;
  readonly memory?: number;
  readonly environment?: Record<string, string>;
}
```

### Configuration Reader Pattern

```typescript
/**
 * Read configuration from SSM Parameter Store.
 */
export class ParameterReader {
  constructor(
    private readonly scope: Construct,
    private readonly basePath: string
  ) {}

  /**
   * Read string parameter.
   */
  getString(key: string): string {
    const parameterName = `${this.basePath}/${key}`;
    return ssm.StringParameter.valueFromLookup(this.scope, parameterName);
  }

  /**
   * Read JSON parameter and parse.
   */
  getJson<T>(key: string): T {
    const value = this.getString(key);
    return JSON.parse(value) as T;
  }

  /**
   * Read multiple parameters.
   */
  getAll(keys: string[]): Record<string, string> {
    return keys.reduce((acc, key) => {
      acc[key] = this.getString(key);
      return acc;
    }, {} as Record<string, string>);
  }
}
```

## Helper Script Patterns

### Structure of helper.sh

The `helper.sh` script provides a consistent interface for all project operations:

```bash
#!/usr/bin/env bash

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="${SCRIPT_DIR}"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Function to display usage
usage() {
    cat <<EOF
Usage: $0 <command> [options]

Commands:
    install         Install dependencies
    build           Build the project
    test            Run tests
    lint            Run linter
    format          Format code
    deploy          Deploy to AWS
    destroy         Destroy AWS resources
    synth           Synthesize CloudFormation
    diff            Show deployment diff
    bootstrap       Bootstrap CDK
    clean           Clean build artifacts

Options:
    -e, --env       Environment (dev|staging|prod)
    -r, --region    AWS region
    -a, --account   AWS account ID
    -h, --help      Show this help message

Examples:
    $0 install
    $0 build
    $0 test
    $0 deploy --env dev
    $0 diff --env staging
EOF
}

# Parse command line arguments
parse_args() {
    COMMAND="${1:-}"
    shift || true

    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--env)
                ENV="$2"
                shift 2
                ;;
            -r|--region)
                REGION="$2"
                shift 2
                ;;
            -a|--account)
                ACCOUNT="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Command functions
cmd_install() {
    log_info "Installing dependencies..."
    npm ci
}

cmd_build() {
    log_info "Building project..."
    npm run build
}

cmd_test() {
    log_info "Running tests..."
    npm test
}

cmd_lint() {
    log_info "Running linter..."
    npm run lint
}

cmd_format() {
    log_info "Formatting code..."
    npm run format
}

cmd_deploy() {
    local env="${ENV:-dev}"
    log_info "Deploying to ${env}..."

    npm run build
    cdk deploy --all \
        --context environment="${env}" \
        --require-approval never
}

cmd_synth() {
    local env="${ENV:-dev}"
    log_info "Synthesizing CloudFormation for ${env}..."

    cdk synth --all \
        --context environment="${env}"
}

cmd_diff() {
    local env="${ENV:-dev}"
    log_info "Showing diff for ${env}..."

    cdk diff --all \
        --context environment="${env}"
}

cmd_destroy() {
    local env="${ENV:-dev}"
    log_warn "Destroying resources in ${env}..."
    read -p "Are you sure? (yes/no): " -r

    if [[ $REPLY == "yes" ]]; then
        cdk destroy --all \
            --context environment="${env}" \
            --force
    else
        log_info "Destruction cancelled"
    fi
}

cmd_bootstrap() {
    local env="${ENV:-dev}"
    local region="${REGION:-us-east-1}"
    local account="${ACCOUNT}"

    log_info "Bootstrapping CDK for ${env} in ${region}..."

    cdk bootstrap "aws://${account}/${region}" \
        --context environment="${env}"
}

cmd_clean() {
    log_info "Cleaning build artifacts..."
    rm -rf dist coverage node_modules/.cache cdk.out
}

# Main function
main() {
    parse_args "$@"

    case "${COMMAND}" in
        install)
            cmd_install
            ;;
        build)
            cmd_build
            ;;
        test)
            cmd_test
            ;;
        lint)
            cmd_lint
            ;;
        format)
            cmd_format
            ;;
        deploy)
            cmd_deploy
            ;;
        synth)
            cmd_synth
            ;;
        diff)
            cmd_diff
            ;;
        destroy)
            cmd_destroy
            ;;
        bootstrap)
            cmd_bootstrap
            ;;
        clean)
            cmd_clean
            ;;
        "")
            log_error "No command specified"
            usage
            exit 1
            ;;
        *)
            log_error "Unknown command: ${COMMAND}"
            usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
```

**Key principles:**
- Use `set -euo pipefail` for safety
- Define readonly variables for paths
- Provide colored output for readability
- Use functions for each command
- Parse arguments consistently
- Include help documentation
- Confirm destructive operations
- Pass context to CDK commands

### Common Helper Script Patterns

#### Environment Management

```bash
# Load environment variables from file
load_env() {
    local env_file="${1:-.env}"

    if [[ -f "${env_file}" ]]; then
        log_info "Loading environment from ${env_file}"
        set -a
        source "${env_file}"
        set +a
    else
        log_warn "Environment file ${env_file} not found"
    fi
}

# Validate required environment variables
check_env() {
    local required_vars=("$@")
    local missing_vars=()

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("${var}")
        fi
    done

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        exit 1
    fi
}
```

#### AWS Profile and Credential Management

```bash
# Set AWS profile
set_aws_profile() {
    local profile="${1}"

    export AWS_PROFILE="${profile}"
    log_info "Using AWS profile: ${profile}"
}

# Assume AWS role
assume_role() {
    local role_arn="${1}"
    local session_name="${2:-cdk-session}"

    log_info "Assuming role: ${role_arn}"

    local credentials
    credentials=$(aws sts assume-role \
        --role-arn "${role_arn}" \
        --role-session-name "${session_name}" \
        --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
        --output text)

    export AWS_ACCESS_KEY_ID=$(echo "${credentials}" | awk '{print $1}')
    export AWS_SECRET_ACCESS_KEY=$(echo "${credentials}" | awk '{print $2}')
    export AWS_SESSION_TOKEN=$(echo "${credentials}" | awk '{print $3}')

    log_info "Role assumed successfully"
}
```

#### Testing and Validation

```bash
# Run unit tests
run_unit_tests() {
    log_info "Running unit tests..."
    npm run test:unit -- --coverage
}

# Run integration tests
run_integration_tests() {
    local env="${1:-dev}"

    log_info "Running integration tests for ${env}..."
    npm run test:integ -- --environment="${env}"
}

# Validate CloudFormation templates
validate_templates() {
    log_info "Validating CloudFormation templates..."

    cdk synth --all > /dev/null

    for template in cdk.out/*.template.json; do
        log_info "Validating ${template}..."
        aws cloudformation validate-template \
            --template-body "file://${template}" \
            > /dev/null
    done

    log_info "All templates are valid"
}
```

#### CI/CD Integration

```bash
# CI/CD pipeline function
ci_pipeline() {
    log_info "Running CI/CD pipeline..."

    # Install dependencies
    cmd_install

    # Lint and format check
    cmd_lint
    npm run format:check

    # Run tests
    cmd_test

    # Build
    cmd_build

    # Security scan
    npm audit

    log_info "CI/CD pipeline completed successfully"
}

# Deploy to environment with approval
deploy_with_approval() {
    local env="${1}"

    log_info "Preparing deployment to ${env}..."

    # Show diff
    cmd_diff

    # Request approval for prod
    if [[ "${env}" == "prod" ]]; then
        read -p "Deploy to PRODUCTION? (yes/no): " -r
        if [[ $REPLY != "yes" ]]; then
            log_info "Deployment cancelled"
            exit 0
        fi
    fi

    # Deploy
    cmd_deploy
}
```

## DevOps Automation

### Local Development Workflow

```bash
# Development setup
dev_setup() {
    log_info "Setting up development environment..."

    # Install dependencies
    cmd_install

    # Install git hooks
    npx husky install

    # Load environment
    load_env .env.dev

    # Bootstrap CDK
    cmd_bootstrap

    log_info "Development environment ready"
}

# Watch mode for development
dev_watch() {
    log_info "Starting watch mode..."
    npm run watch
}

# Local testing
dev_test() {
    log_info "Running local tests..."
    npm run test:watch
}
```

### Deployment Workflows

```bash
# Multi-region deployment
deploy_multi_region() {
    local env="${1}"
    local regions=("${@:2}")

    for region in "${regions[@]}"; do
        log_info "Deploying to ${region}..."
        REGION="${region}" cmd_deploy
    done
}

# Blue-green deployment
deploy_blue_green() {
    local env="${1}"

    log_info "Starting blue-green deployment..."

    # Deploy new version (green)
    cdk deploy --all \
        --context environment="${env}" \
        --context version=green

    # Run smoke tests
    run_smoke_tests "${env}" green

    # Switch traffic
    log_info "Switching traffic to green..."
    # Update load balancer target group weights

    # Keep blue for rollback
    log_info "Blue version kept for rollback"
}
```

## Testing Patterns

### Unit Testing

```typescript
import { describe, it, expect } from 'vitest';
import { App, Stack } from 'aws-cdk-lib';
import { Template } from 'aws-cdk-lib/assertions';
import { ServiceConstruct } from '../src/constructs/service';

describe('ServiceConstruct', () => {
  it('creates service with defaults', () => {
    // Arrange
    const app = new App();
    const stack = new Stack(app, 'TestStack');

    // Act
    new ServiceConstruct(stack, 'TestService', {
      environment: 'dev',
      projectName: 'test',
      vpc: // ... mock VPC
      cluster: // ... mock cluster
      serviceName: 'api',
    });

    // Assert
    const template = Template.fromStack(stack);

    template.resourceCountIs('AWS::ECS::Service', 1);
    template.hasResourceProperties('AWS::ECS::Service', {
      DesiredCount: 2,
    });
  });

  it('validates required props', () => {
    // Arrange
    const app = new App();
    const stack = new Stack(app, 'TestStack');

    // Act & Assert
    expect(() => {
      new ServiceConstruct(stack, 'TestService', {
        // Missing required props
      } as any);
    }).toThrow('Environment must be specified');
  });
});
```

### Integration Testing

```typescript
import { IntegTest } from '@aws-cdk/integ-tests-alpha';
import { App, Stack } from 'aws-cdk-lib';

describe('ServiceConstruct Integration', () => {
  it('deploys and functions correctly', async () => {
    // Arrange
    const app = new App();
    const stack = new Stack(app, 'IntegStack');

    const construct = new ServiceConstruct(stack, 'Service', {
      // ... props
    });

    // Act - Deploy to real AWS
    const integ = new IntegTest(app, 'ServiceIntegTest', {
      testCases: [stack],
    });

    // Assert - Real AWS resources
    const apiCall = integ.assertions.awsApiCall('ECS', 'describeServices', {
      cluster: construct.cluster.clusterName,
      services: [construct.service.serviceName],
    });

    apiCall.expect(ExpectedResult.objectLike({
      services: [
        {
          status: 'ACTIVE',
          runningCount: 2,
        },
      ],
    }));
  });
});
```

## Best Practices

### Infrastructure as Code

1. **Immutable Infrastructure**: Never modify resources in place, always replace
2. **Version Control**: All infrastructure code in Git
3. **Environment Parity**: Use same code for all environments, vary only config
4. **Least Privilege**: Grant minimum necessary permissions
5. **Tagging Strategy**: Consistent tags for cost tracking and organization
6. **State Management**: CDK manages state in CloudFormation

### CDK Specific

1. **Use Constructs**: Compose from L1/L2/L3 constructs, create L3 for patterns
2. **Props Pattern**: Type-safe props with readonly fields
3. **Sensible Defaults**: Provide defaults, allow overrides
4. **Resource Names**: Use `getResourceName()` for consistency
5. **Export Values**: Export ARNs/names for cross-stack references
6. **Context Values**: Use context for environment-specific values
7. **Validation**: Validate props in constructors
8. **Testing**: Unit test constructs, integration test deployed resources

### Helper Script

1. **Single Entry Point**: All operations through `helper.sh`
2. **Idempotent**: Safe to run multiple times
3. **Fail Fast**: Use `set -euo pipefail`
4. **Colored Output**: Visual feedback with colors
5. **Documentation**: Built-in help with `--help`
6. **Environment Aware**: Support multiple environments
7. **CI/CD Ready**: Scriptable for automation
8. **Safety Checks**: Confirm destructive operations

### DevOps Workflow

1. **Local Development**: Use `helper.sh dev_setup` for consistent setup
2. **Testing**: Run `helper.sh test` before commit
3. **CI Pipeline**: Automated lint, test, build on every commit
4. **CD Pipeline**: Automated deploy to dev, manual approval for prod
5. **Rollback Plan**: Keep previous version for quick rollback
6. **Monitoring**: CloudWatch dashboards and alarms
7. **Cost Control**: Budget alerts and resource tagging

## Summary

This pattern guide promotes building scalable AWS infrastructure through:

**TypeScript/CDK**: Type-safe infrastructure, reusable constructs, comprehensive testing

**Helper Scripts**: Consistent automation, CI/CD integration, environment management

**DevOps**: Streamlined workflows, safety checks, multi-environment support

**Key Principle**: Infrastructure as Code with the same quality standards as application code.

Use the `helper.sh` script as the single interface for all project operations, ensuring consistency across local development and CI/CD pipelines.
