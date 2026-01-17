---
name: coder
description: Code design and implementation skill for well-architected Python, JavaScript, and TypeScript applications following SOLID principles, especially Open-Closed. Use when writing code requiring abstract base classes, ETL frameworks, CRUD stores, configuration injection, enums, dataclasses, data validation, AWS CDK infrastructure, or DevOps automation. Includes helper.sh bash script patterns for local development and CI/CD pipelines. Promotes extensibility through abstraction, type safety, immutability, and production-grade quality standards.
---

# Coder Skill

Design and implement well-structured Python, JavaScript, and TypeScript code following SOLID principles, architectural patterns, and conventions for production-grade applications that are open for extension but closed for modification. Includes AWS infrastructure as code with CDK and DevOps automation patterns.

## When to Use This Skill

Use this skill when:
- Writing Python code requiring abstract base classes, interfaces, or framework patterns
- Implementing ETL (Extract-Transform-Load) workflows or data processing pipelines
- Creating CRUD stores, sinks, or data persistence layers
- Building JavaScript utility libraries with configuration management
- Implementing validation frameworks and data quality checks
- Working with DataFrames and time-series data transformations
- Creating testable, maintainable code with clear architectural boundaries
- Building AWS infrastructure with TypeScript and CDK
- Creating reusable CDK constructs following best practices
- Implementing DevOps automation with bash helper scripts
- Setting up CI/CD pipelines and deployment workflows

## Core Principles

### SOLID Design Principles

**Open-Closed Principle (Primary Focus)**
> Software entities should be open for extension but closed for modification.

This is achieved through:
- **Abstract base classes**: Define contracts that implementations must follow
- **Interfaces**: Specify capabilities without implementation details
- **Configuration injection**: Extend behavior through configuration, not code changes
- **Strategy pattern**: Swap implementations without modifying client code
- **Template methods**: Fixed workflow with customizable steps

**Single Responsibility Principle**
- Each class has one reason to change
- Separate concerns: ETL, Store, Sink, Validation

**Liskov Substitution Principle**
- Implementations must be substitutable for their base types
- Preserve contracts defined by abstract classes

**Interface Segregation Principle**
- Define focused interfaces (Store vs Sink)
- Clients depend only on methods they use

**Dependency Inversion Principle**
- Depend on abstractions, not concrete implementations
- Use dependency injection for testability

### Design Philosophy

1. **Abstraction First**: Define interfaces and abstract base classes before implementations
2. **Configuration Over Code**: Inject behavior through configuration
3. **Immutability**: Use immutable constants and defensive copying
4. **Type Safety**: Leverage modern type hints (Python 3.10+) and strict equality (JavaScript)
5. **Structured Logging**: Consistent entry/exit point logging for observability
6. **Fail Fast**: Validate early with descriptive exceptions
7. **Comprehensive Testing**: Mirror structure, test contracts
8. **Lazy Loading**: Load resources on-demand for efficiency
9. **UTC Only**: All timestamps in UTC epoch seconds

### Code Quality Standards

- Clean, readable code with clear intent
- Modern language features (Python 3.10+, ES6+)
- Consistent naming conventions
- Comprehensive docstrings (Python) or JSDoc (JavaScript)
- Linting and formatting (ruff for Python)
- Pre-commit hooks for quality gates
- High test coverage focusing on contracts

### Documentation Resources

**IMPORTANT**: When working with any library or framework, always use the **context7 MCP server** to access up-to-date, version-specific documentation and code examples. This ensures:
- Current API usage patterns (no deprecated methods)
- Version-specific syntax and features
- Accurate code examples that work with the installed version
- Breaking changes and migration guides between versions

**How to use context7**:
1. Query for official documentation of the specific library version you're using
2. Request code examples for specific use cases
3. Check for version-specific breaking changes or deprecations
4. Verify best practices for the current version

This takes precedence over the pattern examples in this skill when there are conflicts or version differences.

## Language-Specific Patterns

### Python Patterns

**Core architectural patterns**: [python_patterns.md](references/python_patterns.md)
**Advanced implementation patterns**: [advanced_python_patterns.md](references/advanced_python_patterns.md)

**Quick reference:**
- **Abstract classes**: `abc.ABC` with `@abc.abstractmethod`
- **Interfaces**: `abc.ABCMeta` with `__subclasshook__`
- **Configuration**: Inject via decorator using `inspect.signature`
- **Type hints**: Python 3.10+ style with `|` for unions
- **Logging**: `[method|in]` and `[method|out]` format
- **Testing**: pytest with fixtures and `assert_frame_equal()`
- **Enums**: Fixed value sets with `from_string()`, `from_value()`
- **Constants**: Frozen dataclasses with singleton instances
- **Properties**: Lazy loading with `@property`
- **Timestamps**: UTC epoch seconds (int)

**Key abstractions:**
- `Etl`: Template method for extract-transform-load workflows
- `Store`: CRUD interface (get, save, update, delete)
- `Sink`: Write-only interface (put, delete)
- `DataValidation`: Abstract validation interface

### JavaScript Patterns

**Complete patterns**: [javascript_patterns.md](references/javascript_patterns.md)

**Quick reference:**
- **Module pattern**: Export utilities and classes
- **Strict mode**: Always `'use strict';`
- **Configuration**: Multi-source (env, config, spec)
- **Logging**: `[namespace.method|in/out]` format
- **Variables**: `const` and `let`, never `var`
- **Equality**: Strict (`===`, `!==`)
- **Error classes**: Custom with status codes

### TypeScript and AWS CDK Patterns

**Infrastructure as Code patterns**: [typescript_cdk_patterns.md](references/typescript_cdk_patterns.md)
**DevOps automation patterns**: [bash_helper_patterns.md](references/bash_helper_patterns.md)

**Quick reference:**
- **Base constructs**: Create foundational infrastructure (VPC, roles, keys)
- **Props interfaces**: Use `readonly` with interface inheritance
- **Type safety**: Leverage TypeScript generics and utility types
- **Naming utilities**: Consistent resource naming with `deriveResourceName()`
- **Dependency injection**: Pass base constructs to dependent constructs
- **Conditional creation**: Create resources based on props
- **Integration testing**: Use `@aws-cdk/integ-runner` for real deployments
- **Helper script**: Single `helper.sh` for all DevOps operations

**Key abstractions:**
- `BaseConstructs`: Foundation (VPC, IAM, KMS, logging)
- `IBaseConstructs`: Interface for base resources (Open-Closed)
- `CommonStackProps`: Base props with environment config
- `SysEnv`: Environment-specific configuration
- `helper.sh`: Bash automation for local dev and CI/CD

**Helper script pattern:**
```bash
# Common section (reusable across projects)
- Shell options and directory detection
- Logging functions (debug, info, warn, err)
- Environment loading (.variables, .local_variables, .secrets)
- External library inclusion

# Main section (project-specific)
- Build functions (deps, build, test, coverage)
- Deployment functions (deploy, destroy, synth, diff)
- AWS utility functions
- Usage documentation

# Typical commands
./helper.sh lib deps      # npm ci
./helper.sh lib build     # npm run build
./helper.sh lib test      # npm run test
./helper.sh cdk deploy StackName dev
```

## Implementation Workflow

### 1. Define Abstractions (Open-Closed Foundation)

**Python:**
```python
# 1. Define custom exception
class ModuleException(Exception):
    """Domain-specific exception."""

# 2. Define interface with subclass hook
class StorageInterface(metaclass=abc.ABCMeta):
    @classmethod
    def __subclasshook__(cls, subclass):
        return (
            hasattr(subclass, "get") and callable(subclass.get) and
            hasattr(subclass, "save") and callable(subclass.save)
        ) or NotImplemented

# 3. Define abstract base class (extensibility contract)
@StorageInterface.register
class Storage(abc.ABC):
    """Abstract storage defining extensible contract."""

    def __init__(self, config: dict[str, Any] | None = None) -> None:
        self._config = config

    @abc.abstractmethod
    def get(self, key: str) -> Any:
        """Retrieve data - implementation specific."""
        raise NotImplementedError

    @abc.abstractmethod
    def save(self, data: Any, key: str) -> None:
        """Persist data - implementation specific."""
        raise NotImplementedError
```

**JavaScript:**
```javascript
'use strict';

// 1. Custom error for domain
class StorageError extends Error {
    constructor(message, code) {
        super(message);
        this.name = "StorageError";
        this.code = code;
    }
}

// 2. Utilities with consistent interface
const storageUtils = {
    getConfig: (spec, sources) => {
        console.log("[storageUtils.getConfig|in] spec:", spec);
        const result = {};
        // Multi-source configuration resolution
        console.log("[storageUtils.getConfig|out] =>", result);
        return result;
    }
};

module.exports = { storageUtils, StorageError };
```

### 2. Implement Concrete Classes (Extension Points)

Extend abstractions without modifying base:
- Inherit from abstract base class
- Implement all required methods
- Inject configuration for behavior customization
- Add structured logging
- Handle errors with domain exceptions

### 3. Write Contract-Based Tests

Test the contract, not implementation:
- Test abstract interface requirements
- Test valid/invalid configuration scenarios
- Test error handling and edge cases
- Use fixtures for test data
- Mock external dependencies

### 4. Configure for Quality

**Python (pyproject.toml):**
- Poetry for dependencies
- Ruff for linting/formatting
- Pytest with coverage
- Pre-commit hooks

**JavaScript (package.json):**
- Test scripts (Mocha/Chai)
- Coverage (Istanbul)
- Linting configuration

## Pattern Selection Guide

### ETL Pattern (Template Method)
Use when you have multi-step workflows requiring:
- Fixed execution order (extract → validate → transform → validate → load)
- Optional validation hooks between steps
- Configuration injection for each step
- **Open-Closed**: Add new ETL implementations without modifying base

### Store Pattern (CRUD Interface)
Use when you need:
- Full CRUD operations across different backends
- Consistent interface for all storage types
- **Open-Closed**: Add new storage backends without modifying clients

### Sink Pattern (Write-Only)
Use when you need:
- Only write and delete operations
- Output destinations for pipelines
- **Open-Closed**: Add new sink types without modifying producers

### Utility Pattern (Functional)
Use when you have:
- Stateless helper functions
- Configuration-based behavior
- **Open-Closed**: Add utilities without modifying existing ones

## Architecture Example

### Python ETL with Open-Closed Design

```python
# Base defines contract (closed for modification)
class EtlBase(abc.ABC):
    """Template method pattern - workflow fixed, steps extensible."""

    def __init__(self, configuration: dict[str, Any] | None = None) -> None:
        self._configuration = configuration
        self._data: dict[str, Any] = {}
        self._result: dict[str, Any] = {}

    @abc.abstractmethod
    def extract(self) -> None:
        """Extract step - open for extension."""
        raise NotImplementedError

    @abc.abstractmethod
    def transform(self) -> None:
        """Transform step - open for extension."""
        raise NotImplementedError

    @abc.abstractmethod
    def load(self) -> Any:
        """Load step - open for extension."""
        raise NotImplementedError

    def validate_extract(self) -> None:
        """Optional validation hook."""
        pass

    def validate_transform(self) -> None:
        """Optional validation hook."""
        pass

    def run(self) -> Any:
        """Fixed workflow - closed for modification."""
        logger.info("[run|in]")
        self.extract()
        self.validate_extract()
        self.transform()
        self.validate_transform()
        result = self.load()
        logger.info(f"[run|out] => {result}")
        return result

# Extension without base modification
class DataTransformationEtl(EtlBase):
    """Concrete ETL - extends without modifying base."""

    def __init__(self, configuration: dict[str, Any] | None = None) -> None:
        super().__init__(configuration)
        self._store = DataStore()

    @EtlBase.inject_configuration
    def extract(self, input_url: str) -> None:
        logger.info(f"[extract|in] {input_url}")
        self._data["source"] = self._store.get(input_url)
        logger.info("[extract|out]")

    def transform(self) -> None:
        logger.info("[transform|in]")
        # Add processing timestamp
        self._result["data"] = self._data["source"]
        self._result["data"]["processing_time"] = int(datetime.now(tz=UTC).timestamp())
        logger.info("[transform|out]")

    @EtlBase.inject_configuration
    def load(self, output_url: str) -> dict[str, str]:
        logger.info(f"[load|in] {output_url}")
        self._store.save(self._result["data"], output_url)
        logger.info(f"[load|out] saved to {output_url}")
        return {"output_url": output_url}
```

## Reference Documentation

Consult detailed patterns and examples:

- **[python_patterns.md](references/python_patterns.md)**: Core architectural patterns
  - Abstract base classes and interfaces
  - Configuration injection decorators
  - ETL framework with template methods
  - Store and Sink patterns
  - Exception hierarchies
  - Type hints and docstrings
  - Project configuration

- **[advanced_python_patterns.md](references/advanced_python_patterns.md)**: Production patterns
  - Enums with conversion methods
  - Frozen dataclasses for constants
  - Lazy loading with properties
  - Data validation integration
  - DataFrame transformations
  - UTC timestamp handling
  - Advanced testing with fixtures

- **[javascript_patterns.md](references/javascript_patterns.md)**: Utility patterns
  - Module exports
  - Multi-source configuration
  - Variable handling
  - Logging frameworks
  - Error classes
  - Testing strategies

- **[typescript_aws_cdk_patterns.md](references/typescript_aws_cdk_patterns.md)**: Infrastructure as Code patterns
  - AWS CDK construct design with `BaseConstruct`
  - TypeScript type safety and interfaces
  - Props patterns with sensible defaults
  - Helper script (`helper.sh`) for DevOps automation
  - Local development workflows
  - CI/CD pipeline integration
  - Multi-environment deployment patterns
  - Unit and integration testing for infrastructure
  - Resource naming and tagging strategies

## Quality Checklist

### Python
- [ ] Abstract base class with clear contract
- [ ] Interface with `__subclasshook__`
- [ ] Domain-specific exceptions
- [ ] Type hints throughout (Python 3.10+)
- [ ] Configuration injection
- [ ] Structured logging (`[method|in/out]`)
- [ ] Comprehensive docstrings
- [ ] pyproject.toml configured
- [ ] Pre-commit hooks
- [ ] Enums for fixed values
- [ ] Frozen dataclasses for constants
- [ ] UTC epoch timestamps
- [ ] **Pytest Structure**:
  - [ ] One test file per class (`test_<class_name>.py`)
  - [ ] Test functions only (no test classes)
  - [ ] Fixtures for reusable test data
  - [ ] Test both success and failure paths
  - [ ] Mock external dependencies
- [ ] **Open-Closed**: Can extend without modifying base

### JavaScript
- [ ] `'use strict';` at top
- [ ] Clean module exports
- [ ] Custom error classes
- [ ] Multi-source configuration
- [ ] Structured logging
- [ ] Template literals
- [ ] Strict equality (`===`)
- [ ] Tests with Mocha/Chai
- [ ] **Open-Closed**: Can extend without modifying existing code

### TypeScript/CDK
- [ ] BaseConstruct extended for all custom constructs
- [ ] Props use readonly interfaces with inheritance
- [ ] Sensible defaults provided via `??` operator
- [ ] Resource naming via `getResourceName()`
- [ ] Centralized tagging strategy via base class
- [ ] Type safety with generics and utility types
- [ ] Unit tests with CDK Template assertions
- [ ] Integration tests with `@aws-cdk/integ-runner`
- [ ] helper.sh script for all operations
- [ ] Environment-specific configuration via context
- [ ] **Open-Closed**: Can extend constructs without modifying base

## Best Practices

### Extensibility Through Abstraction (Open-Closed)
- Define interfaces before implementations
- Use dependency injection for flexibility
- Inject configuration for behavior changes
- Create extension points (hooks, callbacks)
- Never modify existing abstractions - extend them

### Logging for Observability
- **Python**: `logger.info("[method|in]")` and `logger.info(f"[method|out] => {result}")`
- **JavaScript**: `console.log("[namespace.method|in] param:", param)`
- Provides: Flow tracking, debugging, profiling, audit trail

### Configuration Management
- **Python**: Dict to constructor, inject via `@inject_configuration`
- **JavaScript**: Multi-source (env, config, spec)
- Validate early, fail fast with descriptive errors

### Testing Philosophy
- Test contracts, not implementations
- Test substitutability (Liskov)
- Test both success and failure paths
- Use fixtures for reusable test data
- Mock external dependencies and timestamps
- Aim for high coverage on abstractions

### Data Handling
- Work on copies (immutability)
- UTC for all timestamps (epoch seconds)
- Validate early in pipeline
- Log shapes before/after transforms
- Use enums for fixed values
- Align time periods for completeness

## Summary

This skill promotes building extensible, maintainable code through:

**Python**: Abstract base classes, configuration injection, ETL frameworks, stores, sinks, enums, dataclasses, properties, data validation, DataFrame transformations

**JavaScript**: Module pattern, configuration management, utility libraries, error handling

**Key Principle**: Design for extension, not modification. Use abstraction to achieve the Open-Closed principle.

Consult the `references/` directory for detailed patterns and production examples.
