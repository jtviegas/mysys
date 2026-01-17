# Python Design Patterns - Core Architecture

This document captures core design patterns, structure, and coding conventions for building well-architected Python applications with abstract base classes, ETL frameworks, and data persistence layers.

## Project Structure

### Package Organization

```
src/
└── <namespace>/
    └── <project>/
        ├── commons/         # Utility functions and helpers
        ├── etl/             # ETL frameworks and abstractions
        ├── sink/            # Data persistence abstractions (write-only)
        ├── store/           # Data persistence abstractions (CRUD)
        └── validation/      # Data validation abstractions
```

### Naming Conventions

- **Package structure**: Use nested namespace packages (e.g., `tgedr.dataops`)
- **Module naming**: Use snake_case for module names
- **Class naming**: Use PascalCase for class names
- **Abstract classes**: Name base classes with simple nouns (e.g., `Etl`, `Sink`, `Store`)
- **Implementations**: Name concrete implementations descriptively (e.g., `EtlDatabricks`, `CatalogSink`, `ParquetStore`)

## Core Design Patterns

### 1. Abstract Base Classes with Interfaces

Define both an Interface (using `abc.ABCMeta`) and an abstract base class:

```python
class SinkInterface(metaclass=abc.ABCMeta):
    """Defines the interface for sink operations."""

    @classmethod
    def __subclasshook__(cls, subclass):
        return (
            hasattr(subclass, "put")
            and callable(subclass.put)
            and hasattr(subclass, "delete")
            and callable(subclass.delete)
        ) or NotImplemented


@SinkInterface.register
class Sink(abc.ABC):
    """Abstract class defining methods to manage persistence of data."""

    def __init__(self, config: dict[str, Any] | None = None) -> None:
        self._config = config

    @abc.abstractmethod
    def put(self, context: dict[str, Any] | None = None) -> Any:
        raise NotImplementedError

    @abc.abstractmethod
    def delete(self, context: dict[str, Any] | None = None) -> Any:
        raise NotImplementedError
```

**Key principles:**
- Use `abc.ABCMeta` for interface definitions with `__subclasshook__`
- Register the abstract base class with the interface using `@Interface.register`
- Accept optional `config` dict in constructor
- Store config as `_config` (protected attribute)
- Raise `NotImplementedError` in abstract methods

### 2. Configuration Injection Pattern

Use decorators to inject configuration into methods:

```python
class Etl(ABC):
    def __init__(self, configuration: dict[str, Any] | None = None) -> None:
        self._configuration = configuration

    @staticmethod
    def inject_configuration(f):
        def decorator(self):
            signature = inspect.signature(f)
            missing_params = []
            params = {}

            for param in [p for p in signature.parameters if p != "self"]:
                if signature.parameters[param].default != inspect._empty:
                    params[param] = signature.parameters[param].default
                else:
                    params[param] = None
                    if self._configuration is None or param not in self._configuration:
                        missing_params.append(param)

                if self._configuration is not None and param in self._configuration:
                    params[param] = self._configuration[param]

            if 0 < len(missing_params):
                raise EtlException(
                    f"{type(self).__name__}.{f.__name__}: missing required configuration parameters: {missing_params}"
                )

            return f(self, *[params[argument] for argument in params])

        return decorator

    @inject_configuration
    def extract(self, MY_PARAM) -> None:
        # MY_PARAM is automatically injected from configuration
        pass
```

**Key principles:**
- Configuration passed as dict to constructor
- Use `@inject_configuration` decorator to inject params from config
- Support default parameter values
- Raise custom exception for missing required params
- Use `inspect.signature` to introspect method parameters

### 3. Custom Exception Hierarchy

Define custom exceptions for each module:

```python
class EtlException(Exception):
    """Custom exception for errors raised during ETL operations."""


class SinkException(Exception):
    """Exception raised for errors encountered in sink operations."""


class StoreException(Exception):
    """Base exception for errors raised by store operations."""


class NoStoreException(StoreException):
    """Exception raised when no store is available or configured."""
```

**Key principles:**
- One base exception per module/abstraction
- Inherit from built-in `Exception`
- Create specific exceptions for specific error cases
- Use clear, descriptive docstrings

### 4. Template Method Pattern

Implement workflow orchestration with template methods:

```python
class Etl(ABC):
    @abstractmethod
    def extract(self) -> Any:
        raise NotImplementedError

    @abstractmethod
    def transform(self) -> Any:
        raise NotImplementedError

    @abstractmethod
    def load(self) -> Any:
        raise NotImplementedError

    def validate_extract(self) -> None:
        """Optional extra checks for extract step."""
        pass

    def validate_transform(self) -> None:
        """Optional extra checks for transform step."""
        pass

    def run(self) -> Any:
        """Runs the ETL process."""
        logger.info("[run|in]")

        self.extract()
        self.validate_extract()

        self.transform()
        self.validate_transform()

        result: Any = self.load()

        logger.info(f"[run|out] => {result}")
        return result
```

**Key principles:**
- Define abstract methods for required steps
- Provide optional hook methods (e.g., `validate_extract`)
- Implement orchestration in a `run()` method
- Log entry and exit points with consistent format: `[method|in]` and `[method|out]`

### 5. CRUD Store Pattern

Define standard CRUD interface for data stores:

```python
class Store(abc.ABC):
    """Abstract class defining CRUD-like methods."""

    @abc.abstractmethod
    def get(self, key: str, **kwargs) -> Any:
        raise NotImplementedError

    @abc.abstractmethod
    def delete(self, key: str, **kwargs) -> None:
        raise NotImplementedError

    @abc.abstractmethod
    def save(self, df: Any, key: str, **kwargs) -> None:
        raise NotImplementedError

    @abc.abstractmethod
    def update(self, df: Any, key: str, **kwargs) -> None:
        raise NotImplementedError
```

**Key principles:**
- Use `key: str` as primary identifier
- Accept `**kwargs` for implementation-specific parameters
- Separate `save` (create) from `update` operations
- Use `Any` type for data parameter to allow flexibility (DataFrames, dicts, etc.)

### 6. Sink Pattern (Write-Only Store)

Define simpler write-only interface:

```python
class Sink(abc.ABC):
    """Abstract class defining methods ('put' and 'delete')."""

    @abc.abstractmethod
    def put(self, context: dict[str, Any] | None = None) -> Any:
        raise NotImplementedError

    @abc.abstractmethod
    def delete(self, context: dict[str, Any] | None = None) -> Any:
        raise NotImplementedError
```

**Key principles:**
- Use when full CRUD is not needed
- Accept `context` dict instead of separate parameters
- More flexible than Store pattern

## Code Style and Conventions

### Type Hints

- Use modern Python type hints (Python 3.10+ style with `|` for union)
- Use `dict[str, Any]` instead of `Dict[str, Any]`
- Use `list[str]` instead of `List[str]`
- Allow `None` for optional parameters: `dict[str, Any] | None`
- Use `-> None` for methods that don't return values
- Use `-> Any` for methods with flexible return types

### Docstrings

Use Google/NumPy style docstrings:

```python
def method(self, param: str) -> Any:
    """Short description.

    Longer description if needed.

    Args:
        param: Description of parameter.

    Returns:
        Description of return value.

    Raises:
        ExceptionType: When this exception occurs.
    """
```

For class docstrings, list attributes and methods:

```python
class Etl(ABC):
    """Abstract base class for ETL processes.

    Subclasses should implement extract, transform, and load methods.

    Attributes
    ----------
    _configuration : dict[str, Any] or None
        Configuration dictionary for parameter injection.

    Methods
    -------
    extract() -> Any
        Abstract method to extract data.
    transform() -> Any
        Abstract method to transform data.
    load() -> Any
        Abstract method to load data.
    """
```

### Logging

- Use module-level logger: `logger = logging.getLogger(__name__)`
- Set log level: `logger.setLevel(logging.INFO)`
- Silence noisy libraries: `logging.getLogger("py4j").setLevel(logging.ERROR)`
- Log method entry/exit: `logger.info("[method|in]")` and `logger.info(f"[method|out] => {result}")`

### Protected/Private Attributes

- Use single underscore for protected attributes: `self._config`, `self._configuration`
- Use properties for computed attributes:

```python
@property
def _verbose(self) -> bool:
    """Check if verbose mode is enabled."""
    return "verbose" in self._configuration
```

## Testing Patterns

### Test Organization

**File Structure:**
- One test file per class: `tests/test_<class_name>.py`
- Mirror source structure for nested modules: `tests/namespace/project/test_module.py`
- Use `test_` prefix for all test files and test functions
- Use fixtures for reusable test data and instances

**Example:**
```
src/mymodule/storage.py  →  tests/test_storage.py
src/mymodule/etl.py      →  tests/test_etl.py
```

### Pytest Structure (Test Functions Only)

**Use test functions, not test classes:**

```python
import pytest
from mymodule.storage import Storage, StorageException


@pytest.fixture
def storage_config():
    """Fixture providing valid storage configuration."""
    return {"path": "/tmp/data", "format": "parquet"}


@pytest.fixture
def storage_instance(storage_config):
    """Fixture providing configured Storage instance."""
    return Storage(storage_config)


def test_initialization_with_valid_config(storage_config):
    """Test Storage initializes correctly with valid configuration."""
    storage = Storage(storage_config)
    assert storage is not None
    assert storage._config == storage_config


def test_initialization_with_empty_config():
    """Test Storage initializes with empty configuration."""
    storage = Storage({})
    assert storage is not None
    assert storage._config == {}


def test_get_method_success(storage_instance):
    """Test get method retrieves data successfully."""
    result = storage_instance.get("key1")
    assert result is not None


def test_get_method_with_missing_key(storage_instance):
    """Test get method raises exception for missing key."""
    with pytest.raises(StorageException) as excinfo:
        storage_instance.get("nonexistent_key")
    assert "key not found" in str(excinfo.value)


def test_save_method_success(storage_instance):
    """Test save method persists data successfully."""
    data = {"field": "value"}
    storage_instance.save(data, "key1")
    result = storage_instance.get("key1")
    assert result == data


def test_save_method_with_invalid_data(storage_instance):
    """Test save method raises exception for invalid data."""
    with pytest.raises(StorageException):
        storage_instance.save(None, "key1")
```

### Testing Abstract Classes

Create concrete test implementations:

```python
import pytest
from mymodule.base import EtlBase, EtlException


class TestEtlImpl(EtlBase):
    """Concrete implementation for testing abstract EtlBase."""

    def extract(self) -> None:
        self._data["source"] = {"test": "data"}

    def transform(self) -> None:
        self._result["output"] = self._data["source"]

    def load(self) -> dict[str, str]:
        return {"status": "success"}


@pytest.fixture
def etl_instance():
    """Fixture providing test ETL instance."""
    return TestEtlImpl({"input": "test_input"})


def test_etl_run_workflow(etl_instance):
    """Test ETL run method executes full workflow."""
    result = etl_instance.run()
    assert result == {"status": "success"}


def test_etl_extract_populates_data(etl_instance):
    """Test extract method populates internal data."""
    etl_instance.extract()
    assert "source" in etl_instance._data
    assert etl_instance._data["source"] == {"test": "data"}
```

### Test Patterns

**Core Principles:**
- Test contracts, not implementations
- Test both success and failure paths
- Use descriptive test names (what is being tested)
- Mock external dependencies (files, databases, APIs)
- Use fixtures for reusable test data
- Test edge cases (empty input, None, boundary values)

**Naming Convention:**
```python
def test_<method_name>_<scenario>():
    """Test <what is being tested>."""
```

**Example Test Coverage for a Class:**
- Initialization (valid config, empty config, invalid config)
- Each public method (success path, failure path, edge cases)
- Configuration injection
- Exception handling
- Orchestration methods (if applicable)

## Project Configuration (pyproject.toml)

### Poetry Structure

```toml
[project]
name = "namespace-project"
version = "0.0.1"
description = "Brief description"
authors = [{name = "Name", email = "email@example.com"}]
readme = "README.md"
requires-python = ">=3.11"

[tool.poetry]
package-mode = true
packages = [{include = "namespace", from = "src"}]

[tool.poetry.dependencies]
# Dependencies here

[tool.poetry.group.dev.dependencies]
pytest = "~=7.4.3"
pytest-cov = "~=4.1.0"
pytest-mock = "~=3.14.0"
ruff = "^0.9.10"
pre-commit = "^4.2.0"

[build-system]
requires = ["poetry-core>=2.0.0,<3.0.0"]
build-backend = "poetry.core.masonry.api"
```

### Ruff Configuration

```toml
[tool.ruff]
line-length = 120
indent-width = 4

[tool.ruff.lint]
select = ["ALL"]
ignore = ["D203", "S101", "D104", "INP001", "D213", "COM812", "I001"]
fixable = ["ALL"]

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
```

### Coverage Configuration

```toml
[tool.coverage.run]
source = ["src/"]
include = ["src/*"]
omit = ["*/tests/*", "*/test_*", "*/__pycache__/*"]

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "raise NotImplementedError",
    "if __name__ == .__main__.:",
]
show_missing = true
```

## Pre-commit Hooks

Use `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.9.10
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]
      - id: ruff-format
```

## Best Practices Summary

1. **Use abstract base classes** with clear interfaces
2. **Inject configuration** via decorators or constructor
3. **Define custom exceptions** for each module
4. **Implement template methods** for workflow orchestration
5. **Use modern type hints** (Python 3.10+ style)
6. **Write comprehensive docstrings** in Google/NumPy style
7. **Log consistently** with `[method|in]` and `[method|out]` format
8. **Test thoroughly** with pytest, including edge cases
9. **Use ruff** for linting and formatting
10. **Configure pre-commit hooks** for quality checks
