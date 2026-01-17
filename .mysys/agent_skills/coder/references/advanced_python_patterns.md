# Advanced Python Patterns - Production Implementation

This document extends the base Python patterns with advanced techniques for real-world production applications, focusing on ETL implementations, enums, dataclasses, properties, data validation, and domain-specific patterns.

## Table of Contents

- [Enum Patterns](#enum-patterns)
- [Dataclass for Constants](#dataclass-for-constants)
- [Property Patterns for Lazy Loading](#property-patterns-for-lazy-loading)
- [ETL Implementation Patterns](#etl-implementation-patterns)
- [Data Validation Integration](#data-validation-integration)
- [DataFrame Transformation Patterns](#dataframe-transformation-patterns)
- [Timestamp and Date Handling](#timestamp-and-date-handling)
- [Testing Patterns](#testing-patterns)

## Enum Patterns

### String-Based Enums with Conversion Methods

Use enums to represent fixed sets of values with conversion utilities:

```python
from enum import Enum

class AeFilter(Enum):
    """Enumeration for AE filter types."""

    CT = 0.0
    PM = 1.0
    ND = 2.0

    def to_string(self) -> str:
        """Returns the string representation of the enum member."""
        return self.name

    @classmethod
    def from_string(cls, value: str) -> "AeFilter":
        """Returns the enum member corresponding to the given string.

        Parameters
        ----------
        value : str
            The string representation of the enum member.

        Returns
        -------
        AeFilter
            The corresponding AeFilter enum member.

        Raises
        ------
        ValueError
            If the provided value does not correspond to any enum member.
        """
        if hasattr(cls, value.upper()):
            return getattr(cls, value.upper())
        raise ValueError(f"'{value}' is not a valid {cls.__name__}")
```

**Key principles:**
- Use numeric or string values for enum members
- Implement `to_string()` for serialization
- Implement `from_string()` classmethod for deserialization
- Raise `ValueError` for invalid values
- Use `hasattr` and `getattr` for dynamic enum lookup

### Value-Based Enum Lookup

```python
from enum import Enum

class Period(Enum):
    """Enumeration of supported time periods."""

    D = "calendar day"
    W = "calendar week"
    M = "calendar month"
    Q = "calendar quarter"
    Y = "calendar year"

    @staticmethod
    def from_value(value: str) -> "Period":
        """Return the Period enum member matching the given value."""
        entries = [p for p in list(Period) if p.value == value]
        if len(entries) == 0:
            raise ValueError(f"Invalid period: {value}")
        return entries[0]
```

**Key principles:**
- Use descriptive string values
- Implement `from_value()` staticmethod to find by value
- Filter the enum list to find matches
- Raise `ValueError` when not found

## Dataclass for Constants

Use frozen dataclasses to define immutable constants:

```python
from dataclasses import dataclass

@dataclass(frozen=True)
class __Constants:
    TABLE_AE: str = "AE_OVERVIEW"
    TABLE_NNMQ: str = "NNMQ_CURRENT_V"
    TABLE_LISTEDNESS: str = "listedness"
    FIELD_AE_TYPE: str = "SIG_DET_APP_CASE_TYPE"
    FIELD_CREATE_DATE: str = "Create Date"
    FIELD_ACTUAL_TIME: str = "actual_time"
    FIELD_PROCESSING_TIME: str = "processing_time"

# Create a singleton instance
CONSTANTS = __Constants()
```

**Key principles:**
- Use `frozen=True` to make immutable
- Name the class with double underscore prefix (private)
- Create a public singleton instance
- Group related constants together
- Use UPPER_CASE for constant names
- Use descriptive names (e.g., `TABLE_*`, `FIELD_*`)

**Usage:**
```python
from ssds_qsd_jobs.utils.constants import CONSTANTS

df = df[df[CONSTANTS.FIELD_AE_TYPE] == filter_value]
```

## Property Patterns for Lazy Loading

Use properties to implement lazy loading of configuration:

```python
class InputDataIngestion(EtlDatabricks):
    def __init__(self, configuration: dict[str, Any] | None = None) -> None:
        super().__init__(configuration=configuration)
        if "table_config_url" not in self._configuration:
            raise ValueError(
                "configuration must contain 'table_config_url' key"
            )
        self.__table_config: dict[str, Any] = None

    @property
    def _table_config(self) -> dict[str, Any]:
        """Lazy load table configuration from file."""
        if self.__table_config is None:
            url = self._configuration.get("table_config_url")
            with Path(url).open() as file:
                self.__table_config = json.load(file)
        return self.__table_config
```

**Key principles:**
- Use private attribute with double underscore (`__table_config`)
- Use property with single underscore (`_table_config`)
- Check if None before loading (lazy initialization)
- Load from file/external source on first access
- Return cached value on subsequent accesses
- Validate required config keys in constructor

## ETL Implementation Patterns

### Real-World ETL Implementation

```python
from dataops.etl.etl_databricks import EtlDatabricks
from dataops.store.parquet_store import ParquetStore
from typing import Any
from datetime import datetime, UTC
import pandas as pd
import json
from pathlib import Path

class Transformation(EtlDatabricks):
    """ETL implementation for data transformation."""

    def __init__(self, configuration: dict[str, Any] | None = None) -> None:
        super().__init__(configuration=configuration)
        self._data: dict[str, pd.DataFrame] = {}
        self._run_configuration: dict[str, Any] = {}
        self._result: dict[str, pd.DataFrame] = {}
        self._store: ParquetStore = ParquetStore()

    @EtlDatabricks.inject_configuration
    def extract(self, ae_data_url: str, nnmq_data_url: str, run_config_url: str) -> None:
        """Extract data from source tables."""
        logger.info(f"[extract|in] ({ae_data_url}, {nnmq_data_url}, {run_config_url})")

        # Load dataframes
        df_ae = self._store.get(ae_data_url)
        df_ae[CONSTANTS.FIELD_CREATE_DATE] = pd.to_datetime(
            df_ae[CONSTANTS.FIELD_ACTUAL_TIME], unit="s", utc=True
        )
        self._data["ae"] = df_ae
        self._data["nnmq"] = self._store.get(nnmq_data_url)

        # Load configuration
        with Path(run_config_url).open() as file:
            self._run_configuration = json.load(file)

        logger.info("[extract|out]")

    @EtlDatabricks.inject_configuration
    def transform(self, run_config_url: str, database_config_url: str) -> None:
        """Transform data into features."""
        logger.info(f"[transform|in] ({run_config_url}, {database_config_url})")

        # Perform transformation logic
        df_nnmq = self._data["nnmq"] if self._run_configuration.get("use_nnmq", False) else None

        # Add processing timestamp
        processing_time: int = int(datetime.now(tz=UTC).timestamp())
        self._result["features"][CONSTANTS.FIELD_PROCESSING_TIME] = processing_time

        logger.info("[transform|out]")

    @EtlDatabricks.inject_configuration
    def load(self, output_data_url: str) -> Any:
        """Load transformed data to destination."""
        logger.info(f"[load|in] ({output_data_url})")
        result = {}

        # Build output filename
        period: str = self._run_configuration.get("period").replace(" ", "_")
        name: str = self._run_configuration.get("name")
        file_name = f"features_{name}_{period}.parquet"
        output_url = str(Path(output_data_url, file_name))

        # Save result
        self._store.save(self._result["features"], output_url)
        logger.info(f"[load] saved features to {output_url} with shape {self._result['features'].shape}")
        result["features_url"] = output_url

        logger.info(f"[load|out] => {result}")
        return result
```

**Key principles:**
- Store intermediate data in `_data` dict
- Store results in `_result` dict
- Store configuration in `_run_configuration`
- Create store instance in constructor: `self._store = ParquetStore()`
- Use descriptive keys for data dict (e.g., "ae", "nnmq", "features")
- Load JSON config with `Path` and `json.load()`
- Add processing timestamps to results
- Return dict with URLs/paths to saved data
- Log data shapes when saving
- Use f-strings for dynamic filenames

### Custom Validation in ETL

Override `validate_extract` to add custom validation:

```python
@EtlDatabricks.inject_configuration
def validate_extract(self, input_data_url: str) -> None:
    """Validate the extracted data."""
    logger.info(f"[validate_extract|in] ({input_data_url})")
    validation: DataValidation = DataValidation.get_impl("pandas")

    for table_name, config in self._table_config.items():
        if "expectations" not in config:
            raise DataValidationException(
                f"no quality expectations found on table {table_name}"
            )

        # Validate with Great Expectations
        table_expectations = config["expectations"]
        df: pd.DataFrame = self._data[table_name]
        validation_outcome = validation.validate(df=df, expectations=table_expectations)

        if validation_outcome["success"] is not True:
            exc_msg = validation_outcome["results"]
            raise DataValidationException(
                f"expectations validation failed for {table_name}: {exc_msg}"
            )

        logger.info(f"expectations validation succeeded for table {table_name}")

    logger.info("[validate_extract|out]")
```

**Key principles:**
- Use `DataValidation.get_impl("pandas")` to get validator
- Loop through tables/data to validate
- Load expectations from configuration
- Call `validation.validate(df, expectations)`
- Check `validation_outcome["success"]`
- Raise `DataValidationException` on failure
- Log success for each validated table

## Data Validation Integration

### Great Expectations Integration

```python
from dataops.validation.abs import DataValidation, DataValidationException

# Get validation implementation
validation: DataValidation = DataValidation.get_impl("pandas")

# Define expectations (usually loaded from config)
expectations = {
    "expect_column_to_exist": ["column1", "column2"],
    "expect_column_values_to_not_be_null": ["column1"]
}

# Validate dataframe
validation_outcome = validation.validate(df=df, expectations=expectations)

if validation_outcome["success"] is not True:
    raise DataValidationException(f"Validation failed: {validation_outcome['results']}")
```

**Key principles:**
- Get validator using factory pattern: `DataValidation.get_impl("pandas")`
- Pass expectations as dict
- Check `["success"]` key in outcome
- Raise domain-specific exception on failure
- Include validation results in exception message

### Transfer Validation

Custom validation for file transfers:

```python
class QsdInputTransferValidation:
    """Validate file transfers (size, rows, columns)."""

    def __init__(self, data_url: str, metadata_url: str) -> None:
        self.data_url = data_url
        self.metadata_url = metadata_url

    def validate_data_size(self) -> bool:
        """Validate file size matches metadata."""
        # Implementation
        return True

    def validate_data_rows(self) -> bool:
        """Validate row count matches metadata."""
        # Implementation
        return True

    def validate_data_cols(self) -> bool:
        """Validate column count matches metadata."""
        # Implementation
        return True
```

**Usage:**
```python
qsd_transfer_validation = QsdInputTransferValidation(
    data_url=f"{input_data_url}/{table_name}.parquet",
    metadata_url=f"{input_data_url}/{table_name}_metadata.csv",
)

if not qsd_transfer_validation.validate_data_size():
    raise DataValidationException(f"size validation failed for {table_name}")

if not qsd_transfer_validation.validate_data_rows():
    raise DataValidationException(f"rows validation failed for {table_name}")
```

## DataFrame Transformation Patterns

### Period Alignment

Ensure complete periods by filtering incomplete data:

```python
import calendar
from datetime import datetime, UTC

def __align_period_days(self) -> pd.DataFrame:
    """Align the data to ensure complete periods."""
    logger.info("[__align_period_days|in]")

    df_ae = self._data[CONSTANTS.TABLE_AE].copy()
    df_ae[CONSTANTS.FIELD_CREATE_DATE] = pd.to_datetime(
        df_ae[CONSTANTS.FIELD_CREATE_DATE], errors="coerce", utc=True
    )
    logger.info(f"[__align_period_days] df_ae initial shape: {df_ae.shape}")

    max_create_date = df_ae[CONSTANTS.FIELD_CREATE_DATE].max()
    max_create_date_month_days = calendar.monthrange(
        max_create_date.year, max_create_date.month
    )[1]

    logger.info(f"[__align_period_days] data last day: {max_create_date.day}")
    logger.info(f"[__align_period_days] month last day: {max_create_date_month_days}")

    if max_create_date.day < max_create_date_month_days:
        logger.warning(
            f"data for the last month is incomplete (last day: {max_create_date}), "
            "aligning on previous month"
        )
        df_ae = df_ae[
            df_ae[CONSTANTS.FIELD_CREATE_DATE]
            < datetime(max_create_date.year, max_create_date.month, 1, tzinfo=UTC)
        ]

    logger.info(f"[__align_period_days|out] df_ae final shape: {df_ae.shape}")
    return df_ae
```

**Key principles:**
- Always work on a copy: `df.copy()`
- Use `pd.to_datetime()` with `errors="coerce"` for robustness
- Use `calendar.monthrange()` to get days in month
- Log shapes before and after transformation
- Use `logger.warning()` for data quality issues
- Filter data to ensure completeness

### Period Resolution with Enums

```python
from enum import Enum
import pandas as pd

def resolver(df: pd.DataFrame, datetime_col: str, period: Period, output_col: str = "period") -> pd.DataFrame:
    """Add a period column to a DataFrame."""
    if period == Period.D:
        df[output_col] = df[datetime_col].apply(lambda x: x.strftime("%Y%m%d")).astype(int)
    elif period == Period.W:
        df[output_col] = df[datetime_col].apply(lambda x: x.strftime("%Y%W")).astype(int)
    elif period == Period.M:
        df[output_col] = df[datetime_col].apply(lambda x: x.strftime("%Y%m")).astype(int)
    elif period == Period.Q:
        df[output_col] = (df[datetime_col].dt.year * 10 + df[datetime_col].dt.quarter).astype(int)
    elif period == Period.Y:
        df[output_col] = df[datetime_col].apply(lambda x: x.strftime("%Y")).astype(int)
    else:
        raise ValueError(f"Invalid period: {period}")

    return df
```

**Key principles:**
- Use enum to define supported periods
- Format periods as integers (e.g., 20250107 for 2025-01-07)
- Use `strftime()` for date formatting
- Use `.dt` accessor for pandas datetime operations
- Always cast to `int` for consistency
- Raise `ValueError` for unsupported periods

### Data Replacement Patterns

Utility class for data replacements:

```python
class PNAIngredientReplacement:
    """Utility for product/ingredient replacements."""

    @staticmethod
    def replace_pna_values(df: pd.DataFrame, column_name: str = "default_col") -> pd.DataFrame:
        """Replace product name abbreviation values."""
        # Implementation
        return df

    @staticmethod
    def replace_ingredient_by_product(
        df: pd.DataFrame,
        product_col: str = "product",
        ingredient_col: str = "ingredient"
    ) -> pd.DataFrame:
        """Replace ingredient based on product."""
        # Implementation
        return df
```

**Key principles:**
- Use static methods for stateless transformations
- Accept DataFrame and return DataFrame
- Use descriptive method names
- Provide default parameter values
- Allow column name customization

## Timestamp and Date Handling

### UTC Timestamps

Always use UTC for timestamps:

```python
from datetime import datetime, UTC

# Create UTC timestamp
processing_time: int = int(datetime.now(tz=UTC).timestamp())
df[CONSTANTS.FIELD_PROCESSING_TIME] = processing_time

# Convert to datetime
df[CONSTANTS.FIELD_CREATE_DATE] = pd.to_datetime(
    df[CONSTANTS.FIELD_ACTUAL_TIME], unit="s", utc=True
)

# Create UTC datetime
cutoff_date = datetime(max_date.year, max_date.month, 1, tzinfo=UTC)
```

**Key principles:**
- Always use `tz=UTC` or `tzinfo=UTC`
- Store timestamps as integer seconds since epoch
- Use `pd.to_datetime()` with `unit="s", utc=True` for conversion
- Explicitly specify timezone in datetime constructors

### Epoch Conversion

```python
# Datetime to epoch
df[CONSTANTS.FIELD_ACTUAL_TIME] = df[CONSTANTS.FIELD_CREATE_DATE].astype(int) // 10**9

# Epoch to datetime
df[CONSTANTS.FIELD_CREATE_DATE] = pd.to_datetime(
    df[CONSTANTS.FIELD_ACTUAL_TIME], unit="s", utc=True
)
```

**Key principles:**
- Use `astype(int) // 10**9` to convert datetime64 to epoch seconds
- Use `pd.to_datetime(value, unit="s", utc=True)` for reverse
- Always specify `utc=True` for timezone awareness

## Testing Patterns

### Test File Structure

**One test file per class:**
- Class: `src/mymodule/input_data_ingestion.py` → Test: `tests/test_input_data_ingestion.py`
- Class: `src/mymodule/data_processor.py` → Test: `tests/test_data_processor.py`

**Use test functions only (no test classes):**
```python
# tests/test_input_data_ingestion.py
import pytest
from mymodule.input_data_ingestion import InputDataIngestion

@pytest.fixture
def ingestion_instance(data_url, table_config_url):
    """Fixture providing InputDataIngestion instance."""
    return InputDataIngestion(configuration={
        "input_data_url": data_url,
        "table_config_url": table_config_url
    })

def test_extract_populates_data(ingestion_instance):
    """Test extract method populates internal data."""
    ingestion_instance.extract()
    assert len(ingestion_instance._data) > 0

def test_transform_creates_result(ingestion_instance):
    """Test transform method creates result data."""
    ingestion_instance.extract()
    ingestion_instance.transform()
    assert len(ingestion_instance._result) > 0
```

### Fixture-Based Testing

```python
import pytest
import pandas as pd

@pytest.fixture
def data_url(resources_folder) -> str:
    """Return path to test data."""
    return f"{resources_folder}/input_data"

@pytest.fixture
def table_config_url(resources_folder) -> str:
    """Return path to table configuration."""
    return f"{resources_folder}/input_data/tables.json"

@pytest.fixture
def expected_data_url(resources_folder) -> str:
    """Return path to expected output."""
    return f"{resources_folder}/expected/output"
```

**Key principles:**
- One test file per class being tested
- Use test functions only (not test classes)
- Use fixtures for test data paths and instances
- Chain fixtures (e.g., `resources_folder` → `data_url`)
- Use descriptive fixture names
- Return simple types (strings, not DataFrames) or configured instances

### DataFrame Comparison Testing

```python
from pandas.testing import assert_frame_equal

def test_extract(data_url, table_config_url, expected_data_url):
    configuration: dict[str, Any] = {
        "input_data_url": data_url,
        "output_data_url": "dummy",
        "table_config_url": table_config_url
    }

    ingestion = InputDataIngestion(configuration=configuration)
    ingestion.extract()

    expected_data = get_tables(expected_data_url, tables)

    for table in tables:
        assert_frame_equal(
            ingestion._data[table],
            expected_data[table],
            check_categorical=False,
            check_dtype=False,
        )
```

**Key principles:**
- Use `pandas.testing.assert_frame_equal()` for DataFrame comparison
- Set `check_categorical=False` to ignore categorical types
- Set `check_dtype=False` to ignore dtype differences
- Loop through multiple tables/datasets
- Access protected attributes in tests with `._data`

### Mocking Timestamps

```python
from datetime import datetime, UTC
from unittest.mock import MagicMock

def test_transform(monkeypatch, mocker):
    # Mock timestamp for deterministic tests
    mock_datetime = MagicMock()
    mock_datetime.now.return_value = datetime(2025, 1, 1, tzinfo=UTC)
    monkeypatch.setattr("module_name.datetime", mock_datetime)

    # Test code that uses datetime.now()
    processing_time: int = int(datetime.now(tz=UTC).timestamp())
    assert processing_time == 1735689600  # Known value for 2025-01-01 UTC
```

**Key principles:**
- Mock `datetime.now()` for deterministic timestamps
- Use `monkeypatch.setattr()` to replace datetime
- Verify with known timestamp values
- Ensure mocked datetime returns UTC-aware values

### Helper Functions for Testing

```python
def get_tables(url: str, tables: list[str]) -> dict[str, pd.DataFrame]:
    """Load multiple tables from a directory."""
    result = {}
    for table in tables:
        result[table] = pd.read_parquet(f"{url}/{table}.parquet", engine="pyarrow")
    return result
```

**Key principles:**
- Create helper functions for common test operations
- Return data in usable format (dict of DataFrames)
- Use type hints for clarity
- Keep helpers simple and reusable

## Configuration Management Patterns

### JSON Configuration Loading

```python
import json
from pathlib import Path

# Load configuration
with Path(run_config_url).open() as file:
    self._run_configuration = json.load(file)

# Access configuration
period: str = self._run_configuration.get("period")
use_feature: bool = self._run_configuration.get("use_feature", False)
col_name: str = self._run_configuration["col_product"]  # Required key
```

**Key principles:**
- Use `Path` for cross-platform compatibility
- Use context manager (`with`) for file handling
- Store config in instance variable
- Use `.get()` with defaults for optional keys
- Use direct access `[]` for required keys (will raise KeyError if missing)

### Multi-File Configuration

```python
def extract(self, ae_data_url: str, run_config_url: str, database_config_url: str) -> None:
    """Extract data using multiple configuration files."""
    # Load data
    self._data["ae"] = self._store.get(ae_data_url)

    # Load multiple configs
    with Path(run_config_url).open() as file:
        self._run_configuration = json.load(file)

    with Path(database_config_url).open() as file:
        self._database_configuration = json.load(file)
```

**Key principles:**
- Separate concerns with multiple config files
- Use descriptive names (run_config, database_config)
- Store each config in separate instance variable
- Pass all config URLs as injected parameters

## Best Practices Summary

1. **Use enums** for fixed value sets with conversion methods (`from_string`, `from_value`)
2. **Use frozen dataclasses** for immutable constants with singleton instances
3. **Use properties** for lazy loading of configuration and resources
4. **Store intermediate data** in dict attributes (`_data`, `_result`, `_run_configuration`)
5. **Add processing timestamps** using UTC epoch seconds
6. **Log data shapes** when loading and saving DataFrames
7. **Use Great Expectations** for data validation via abstraction layer
8. **Align periods** to ensure complete time windows
9. **Always use UTC** for all timestamps and dates
10. **Test with fixtures** and `assert_frame_equal()` for DataFrames
11. **Mock timestamps** in tests for deterministic behavior
12. **Load JSON configs** with `Path` and context managers
13. **Return result dicts** from load methods with URLs/paths to saved data
14. **Use static methods** for stateless data transformations
15. **Validate early** in `validate_extract()` before transformation
