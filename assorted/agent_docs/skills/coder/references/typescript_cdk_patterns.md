# TypeScript and AWS CDK Patterns - Infrastructure as Code

This document captures design patterns for building AWS infrastructure using AWS CDK (Cloud Development Kit) with TypeScript, focusing on reusable constructs, naming conventions, and extensible infrastructure patterns.

## Table of Contents

- [Project Structure](#project-structure)
- [Core CDK Patterns](#core-cdk-patterns)
- [Construct Design Patterns](#construct-design-patterns)
- [Props Interface Patterns](#props-interface-patterns)
- [Naming Convention Utilities](#naming-convention-utilities)
- [Resource Organization](#resource-organization)
- [TypeScript Best Practices](#typescript-best-practices)
- [Testing Infrastructure](#testing-infrastructure)

## Project Structure

### AWS CDK Project Layout

```
cdk-project/
├── package.json           # Dependencies and scripts
├── tsconfig.json          # TypeScript configuration
├── tsup.config.ts         # Build configuration
├── vitest.config.ts       # Test configuration
├── helper.sh              # DevOps automation script
├── .variables             # Environment variables
├── .local_variables       # Local overrides
├── .secrets               # Secrets (gitignored)
├── src/
│   ├── index.ts          # Public API exports
│   ├── commons/          # Shared utilities and types
│   │   ├── props.ts      # Common interfaces
│   │   ├── utils.ts      # Utility functions
│   │   └── constants.ts  # Constants
│   └── constructs/       # CDK constructs
│       ├── base.ts       # Base infrastructure
│       └── *.ts          # Specific constructs
└── test/
    ├── unit/             # Unit tests
    └── infrastructure/   # Integration tests
```

## Core CDK Patterns

### 1. Base Constructs Pattern

Create foundational infrastructure that other constructs depend on:

```typescript
export interface BaseConstructsProps extends CommonStackProps {
  readonly logsBucketOn?: boolean;
}

export interface IBaseConstructs {
  readonly key: Key;
  readonly logGroup: LogGroup;
  readonly role: Role;
  readonly vpc: IVpc;
  readonly logsBucket?: IBucket;
}

export class BaseConstructs extends Construct implements IBaseConstructs {
  readonly key: Key;
  readonly logGroup: LogGroup;
  readonly role: Role;
  readonly vpc: IVpc;
  readonly logsBucket?: IBucket;

  constructor(scope: Construct, id: string, props: BaseConstructsProps) {
    super(scope, id);

    // KMS key for encryption
    this.key = new Key(this, `key`, {
      enableKeyRotation: true,
    });

    // CloudWatch log group
    this.logGroup = new LogGroup(this, `logGroup`, {
      logGroupName: deriveResourceName(props, "base"),
      removalPolicy: RemovalPolicy.DESTROY,
    });

    // Optional logs bucket
    if (props.logsBucketOn === true) {
      this.logsBucket = new Bucket(this, `bucketLogs`, {
        bucketName: deriveResourceName(props, "base", "logs"),
        versioned: false,
        removalPolicy: RemovalPolicy.DESTROY,
        autoDeleteObjects: true,
        lifecycleRules: [{ expiration: Duration.days(7) }],
        objectOwnership: ObjectOwnership.OBJECT_WRITER,
      });
    }

    // IAM role with necessary permissions
    this.role = new Role(this, `role`, {
      assumedBy: new CompositePrincipal(
        new ServicePrincipal("ecs-tasks.amazonaws.com"),
        new ServicePrincipal("lambda.amazonaws.com"),
        new ServicePrincipal("apigateway.amazonaws.com"),
        new AccountPrincipal(props.env.account)
      ),
      roleName: deriveResourceName(props, "base"),
      managedPolicies: [
        ManagedPolicy.fromAwsManagedPolicyName("service-role/AmazonECSTaskExecutionRolePolicy"),
        ManagedPolicy.fromAwsManagedPolicyName("service-role/AWSLambdaVPCAccessExecutionRole"),
        ManagedPolicy.fromAwsManagedPolicyName("service-role/AWSLambdaBasicExecutionRole")
      ]
    });

    // VPC lookup or creation
    if (props.env.vpc === undefined) {
      this.vpc = new Vpc(this, `vpc`, {
        vpcName: deriveResourceName(props, "base"),
        subnetConfiguration: [
          { name: deriveResourceName(props, "base", "private"), subnetType: SubnetType.PRIVATE_WITH_EGRESS },
          { name: deriveResourceName(props, "base", "public"), subnetType: SubnetType.PUBLIC }
        ]
      });
    } else {
      this.vpc = Vpc.fromLookup(this, `vpc`, {
        vpcId: props.env.vpc.id,
        vpcName: props.env.vpc.name
      });
    }
  }
}
```

**Key principles:**
- Define interface for construct outputs (Open-Closed)
- Implement interface with readonly properties
- Expose all created resources for downstream use
- Use consistent naming with utility functions
- Support both creation and lookup patterns
- Use removal policies appropriate for environment
- Implement composite principals for multi-service access

### 2. Dependent Constructs Pattern

Build constructs that depend on base infrastructure:

```typescript
export class ServiceConstruct extends Construct {
  constructor(
    scope: Construct,
    id: string,
    props: ServiceProps,
    baseConstructs: IBaseConstructs
  ) {
    super(scope, id);

    // Use base infrastructure
    const service = new FargateService(this, 'service', {
      cluster: this.createCluster(baseConstructs.vpc),
      taskDefinition: this.createTaskDefinition(baseConstructs.role),
      securityGroups: [this.createSecurityGroup(baseConstructs.vpc)]
    });

    // Use shared KMS key
    const bucket = new Bucket(this, 'bucket', {
      encryptionKey: baseConstructs.key
    });
  }
}
```

**Key principles:**
- Accept base constructs as constructor parameter
- Depend on interfaces, not concrete implementations
- Reuse shared infrastructure (VPC, roles, keys)
- Maintain separation of concerns

## Construct Design Patterns

### 3. Props Inheritance Pattern

Use interface inheritance for props:

```typescript
// Base props for all stacks
export interface CommonStackProps extends StackProps {
  readonly env: SysEnv;
  readonly organisation: string;
  readonly department: string;
  readonly solution: string;
}

// Extended props for specific constructs
export interface ServiceConstructProps extends CommonStackProps {
  readonly domain: string;
  readonly docker: DockerImageSpec;
  readonly tags?: { [key: string]: string };
}

// Specialized props
export interface LoadBalancedServiceProps extends ServiceConstructProps {
  readonly healthCheck?: HealthCheck;
  readonly desiredCount?: number;
}
```

**Key principles:**
- Extend base props with specific requirements
- Use `readonly` for all properties
- Nest complex types in sub-interfaces
- Provide optional properties with `?`
- Document each property with TSDoc

### 4. Interface Segregation for Constructs

Define focused interfaces:

```typescript
// Focused interface for domain resources
export interface DomainProperties {
  readonly hostedZone: IHostedZone;
  readonly certificate?: ICertificate;
}

// Focused interface for API Gateway settings
export interface ApiGwUsagePlanProperties {
  quota?: {
    limit: number,
    period: Period
  },
  throttle?: {
    rateLimit: number,
    burstLimit: number
  }
}

// Focused interface for Docker images
export interface DockerImageSpec {
  readonly apiImage?: DockerImageAsset;
  readonly imageUri?: string;
  readonly dockerfileDir?: string;
  readonly port?: number;
  readonly healthCheck?: HealthCheck;
}
```

**Key principles:**
- Small, focused interfaces
- Single responsibility per interface
- Optional properties for flexibility
- Compose interfaces rather than extending

## Props Interface Patterns

### 5. Environment Configuration Pattern

Structure environment-specific configuration:

```typescript
export interface SysEnv {
  readonly name: string;              // dev, staging, prod
  readonly region: string;            // AWS region
  readonly account: string;           // AWS account ID
  readonly domain?: {
    name: string;
    private: boolean;
    hostedZoneId?: string;
  };
  readonly certificationAuthorityArn?: string;
  readonly vpc?: {
    readonly id: string;
    readonly name: string;
  };
}

// Usage
const environment: SysEnv = {
  name: 'dev',
  region: 'us-east-1',
  account: '123456789012',
  domain: {
    name: 'example.com',
    private: false,
    hostedZoneId: 'Z1234567890ABC'
  }
};
```

**Key principles:**
- Centralize environment configuration
- Support resource lookup (VPC, hosted zones)
- Optional resources for flexibility
- Nested objects for related config

### 6. Context-Based Configuration

Load configuration from CDK context:

```typescript
const app = new cdk.App();
const environment = (app.node.tryGetContext("environment"))[
  process.env.ENVIRONMENT || 'dev'
];

const props: ServiceProps = {
  organisation: "org",
  department: "dept",
  solution: "app",
  env: environment,
  tags: {
    organisation: "org",
    department: "dept",
    solution: "app",
    environment: environment.name,
  }
};
```

**Key principles:**
- Use `app.node.tryGetContext()` for configuration
- Support environment variable overrides
- Consistent tagging strategy
- Derive properties from context

## Naming Convention Utilities

### 7. Consistent Resource Naming

Implement naming utilities for consistency:

```typescript
// Remove non-text characters
export function removeNonTextChars(str: string): string {
  return str.replace(/[^a-zA-Z0-9\s]/g, '');
}

// Capitalize first letter
export function capitalizeFirstLetter(str: string): string {
  return str.charAt(0).toUpperCase() + str.slice(1);
}

// Derive stack affix (PascalCase)
export const deriveAffix = (props: CommonStackProps): string => {
  const region = capitalizeFirstLetter(removeNonTextChars(props.env.region));
  const solution = capitalizeFirstLetter(props.solution);
  return `${solution}${region}`;
}

// Derive resource affix (kebab-case)
export const deriveResourceAffix = (props: CommonStackProps): string => {
  const region = removeNonTextChars(props.env.region);
  return `${props.solution}-${region}`;
}

// Derive full resource name
export const deriveResourceName = (
  props: CommonStackProps,
  name: string,
  surname: string = ""
): string => {
  const affix = deriveResourceAffix(props);
  return `${affix}-${name}${surname ? "-" + surname : ""}`;
}

// Example: "myapp-useast1-base-logs"
```

**Key principles:**
- Consistent naming across all resources
- Include solution, region, and resource type
- Support hierarchical naming with surnames
- Sanitize input strings
- Use kebab-case for AWS resources
- Use PascalCase for CloudFormation exports

### 8. Parameter and Secret Naming

Generate SSM parameter and secret names:

```typescript
export const toParameter = (props: CommonStackProps, ...name: string[]): string => {
  const region = removeNonTextChars(props.env.region);
  let result: string = `/${props.solution}/${region}`;
  for (const n of name) {
    result += `/${removeNonTextChars(n)}`;
  }
  return result;
}

export const toSecretKey = (props: CommonStackProps, ...name: string[]): string => {
  return toParameter(props, ...name);
}

// Usage
const dbPasswordParam = toParameter(props, "database", "password");
// Result: "/myapp/useast1/database/password"

const apiKeySecret = toSecretKey(props, "api", "key");
// Result: "/myapp/useast1/api/key"
```

**Key principles:**
- Hierarchical path structure
- Include solution and region
- Support variable depth
- Consistent format for parameters and secrets

### 9. Output Key Naming

Generate CloudFormation output keys:

```typescript
export const toOutputKey = (props: CommonStackProps, ...name: string[]): string => {
  const region = capitalizeFirstLetter(removeNonTextChars(props.env.region));
  const solution = capitalizeFirstLetter(props.solution);
  let result: string = `${solution}${region}`;
  for (const n of name) {
    result += capitalizeFirstLetter(n);
  }
  return result;
}

// Usage
const vpcIdOutput = toOutputKey(props, "vpc", "id");
// Result: "MyappUseast1VpcId"
```

**Key principles:**
- PascalCase for export names
- Readable across stack references
- Include solution and region prefix

## Resource Organization

### 10. Resource Grouping Pattern

Group related resources in constructs:

```typescript
export class NetworkingConstruct extends Construct {
  readonly vpc: IVpc;
  readonly securityGroups: { [key: string]: SecurityGroup };
  readonly endpoints: { [key: string]: InterfaceVpcEndpoint };

  constructor(scope: Construct, id: string, props: NetworkingProps) {
    super(scope, id);

    this.vpc = this.createVpc(props);
    this.securityGroups = {
      application: this.createAppSecurityGroup(this.vpc),
      database: this.createDbSecurityGroup(this.vpc)
    };
    this.endpoints = this.createVpcEndpoints(this.vpc, props);
  }

  private createVpc(props: NetworkingProps): IVpc {
    // VPC creation logic
  }

  private createAppSecurityGroup(vpc: IVpc): SecurityGroup {
    // Security group creation
  }
}
```

**Key principles:**
- Group by functional domain (networking, compute, storage)
- Expose related resources as maps/objects
- Use private methods for resource creation
- Return all created resources for downstream use

### 11. Conditional Resource Creation

Create resources based on props:

```typescript
export class OptionalResourcesConstruct extends Construct {
  readonly logsBucket?: IBucket;
  readonly monitoring?: Monitoring;

  constructor(scope: Construct, id: string, props: OptionalResourcesProps) {
    super(scope, id);

    // Conditional bucket creation
    if (props.logsBucketOn === true) {
      this.logsBucket = new Bucket(this, 'logsBucket', {
        bucketName: deriveResourceName(props, "logs"),
        // ... bucket config
      });
    }

    // Conditional monitoring
    if (props.monitoring?.enabled) {
      this.monitoring = new Monitoring(this, 'monitoring', {
        alarmEmail: props.monitoring.email,
        logGroup: this.logGroup
      });
    }
  }
}
```

**Key principles:**
- Use optional props for conditional resources
- Use `?:` for optional properties in interface
- Check boolean flags or object presence
- Expose conditional resources as optional properties

## TypeScript Best Practices

### 12. Type Safety Patterns

Leverage TypeScript's type system:

```typescript
// Use const assertions for immutable data
export const AWS_REGIONS = {
  US_EAST_1: 'us-east-1',
  EU_WEST_1: 'eu-west-1'
} as const;

// Use branded types for type safety
type ResourceId = string & { readonly __brand: 'ResourceId' };
type AccountId = string & { readonly __brand: 'AccountId' };

// Use discriminated unions for variants
type DeploymentConfig =
  | { type: 'blue-green'; canaryPercentage: number }
  | { type: 'rolling'; maxBatchSize: number }
  | { type: 'all-at-once' };

// Use utility types
type RequiredProps = Required<ServiceProps>;
type PartialProps = Partial<ServiceProps>;
type PickedProps = Pick<ServiceProps, 'env' | 'solution'>;
```

**Key principles:**
- Use `readonly` for immutability
- Leverage const assertions
- Use branded types for domain types
- Use discriminated unions for variants
- Use utility types to transform types

### 13. Generic Construct Pattern

Create reusable generic constructs:

```typescript
export interface GenericServiceProps<T> extends CommonStackProps {
  readonly config: T;
  readonly baseConstructs: IBaseConstructs;
}

export class GenericService<TConfig> extends Construct {
  constructor(
    scope: Construct,
    id: string,
    props: GenericServiceProps<TConfig>
  ) {
    super(scope, id);
    // Use props.config with type safety
  }
}

// Usage
interface MyServiceConfig {
  port: number;
  replicas: number;
}

new GenericService<MyServiceConfig>(this, 'service', {
  config: { port: 8080, replicas: 3 },
  baseConstructs: baseConstructs,
  // ... other props
});
```

**Key principles:**
- Use generics for flexible, type-safe constructs
- Constrain generics with extends when needed
- Provide clear type parameters in usage

## Testing Infrastructure

### 14. Integration Testing Pattern

Use CDK integ-runner for integration tests:

```typescript
// test/infrastructure/integ.base-constructs.ts
import { App, Stack } from 'aws-cdk-lib';
import { IntegTest } from '@aws-cdk/integ-tests-alpha';
import { BaseConstructs } from '../../src/constructs/base';

const app = new App();
const stack = new Stack(app, 'TestStack');

const baseConstructs = new BaseConstructs(stack, 'Base', {
  env: {
    name: 'test',
    region: 'us-east-1',
    account: '123456789012'
  },
  organisation: 'test-org',
  department: 'test-dept',
  solution: 'test-solution'
});

new IntegTest(app, 'BaseConstructsTest', {
  testCases: [stack],
});
```

**Key principles:**
- Test actual deployments with integ-runner
- Use snapshot tests for assertions
- Test resource creation and configuration
- Validate cross-stack references

### 15. Unit Testing Pattern

Use Vitest for unit tests:

```typescript
import { describe, it, expect } from 'vitest';
import { deriveResourceName, toParameter } from '../src/commons/utils';

describe('Naming Utilities', () => {
  const props = {
    env: { name: 'dev', region: 'us-east-1', account: '123' },
    organisation: 'org',
    department: 'dept',
    solution: 'app'
  };

  it('should derive resource name correctly', () => {
    const name = deriveResourceName(props, 'bucket', 'logs');
    expect(name).toBe('app-useast1-bucket-logs');
  });

  it('should create parameter path', () => {
    const param = toParameter(props, 'db', 'password');
    expect(param).toBe('/app/useast1/db/password');
  });
});
```

**Key principles:**
- Test utility functions in isolation
- Test naming conventions thoroughly
- Test edge cases and error conditions
- Use descriptive test names

## Best Practices Summary

1. **Use Base Constructs** for shared infrastructure (VPC, roles, keys)
2. **Depend on Interfaces** not concrete implementations (Open-Closed)
3. **Extend Props** through interface inheritance
4. **Consistent Naming** using utility functions
5. **Type Safety** with TypeScript features (readonly, const, generics)
6. **Conditional Creation** based on props
7. **Environment Config** centralized in SysEnv interface
8. **Context-Based Config** from CDK context
9. **Hierarchical Naming** for parameters and secrets
10. **Integration Tests** with integ-runner for actual deployments
11. **Unit Tests** for utilities and logic
12. **Expose Resources** via readonly properties for reuse
13. **Segregate Interfaces** for focused, composable types
14. **Generic Constructs** for flexibility and reusability
15. **Consistent Tagging** across all resources

## Package Configuration

### package.json Structure

```json
{
  "name": "infrastructure-library",
  "version": "1.0.0",
  "main": "dist/index.js",
  "module": "dist/index.mjs",
  "types": "dist/index.d.ts",
  "files": ["dist"],
  "scripts": {
    "build": "tsup",
    "dev": "tsup --watch",
    "test": "vitest run",
    "test:watch": "vitest",
    "coverage": "vitest run --coverage"
  },
  "devDependencies": {
    "@aws-cdk/integ-runner": "^2.171.0-alpha.0",
    "@aws-cdk/integ-tests-alpha": "^2.171.0-alpha.0",
    "@vitest/coverage-v8": "^2.1.4",
    "aws-cdk": "^2.171.0",
    "tsup": "^8.3.5",
    "typescript": "^5.6.3",
    "vitest": "^2.1.4"
  },
  "dependencies": {
    "aws-cdk-lib": "^2.171.0",
    "constructs": "^10.0.0"
  }
}
```

### TypeScript Configuration

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "declaration": true,
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "test"]
}
```

**Key principles:**
- Strict TypeScript settings
- Declaration files for library distribution
- ES2020 target for modern features
- Separate build output directory
