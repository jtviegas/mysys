# JavaScript Design Patterns - Utility Libraries

This document captures design patterns, structure, and coding conventions for building JavaScript utility libraries with configuration management and clean module exports.

## Project Structure

### Package Organization

```
project/
├── index.js              # Main entry point with exports
├── package.json          # Package metadata and dependencies
├── test/
│   └── test.js          # Tests
└── README.md            # Documentation
```

### Module Pattern

Export utilities and classes as a single object:

```javascript
'use strict';

// Class definitions
class ServerError extends Error {
    constructor(message, status) {
        super(message);
        this.name = "ServerError";
        this.status = status;
    }
}

// Utility object with methods
const commons = {
    method1: (param1, param2) => {
        // implementation
    },
    method2: (param1, param2) => {
        // implementation
    }
};

// Export pattern
module.exports = {};
module.exports.commons = commons;
module.exports.ServerError = ServerError;
```

**Key principles:**
- Use `'use strict';` at the top of each file
- Group related utilities in a single object
- Export multiple items via `module.exports`
- Separate class definitions from utility object

## Core Patterns

### 1. Custom Error Classes

Create domain-specific error classes:

```javascript
class ServerError extends Error {
    constructor(message, status) {
        super(message);
        this.name = "ServerError";
        this.status = status;
    }
}
```

**Key principles:**
- Extend built-in `Error` class
- Call `super(message)` first
- Set custom `name` property
- Add domain-specific properties (e.g., `status`)

### 2. Configuration Management

#### Environment-based Configuration

```javascript
const configByEnvironment = (config, variables, defaults, rangeSuffix, splitVariables) => {
    for(let i in variables){
        let variable = variables[i];
        let defaultValue = defaults[i];

        if (process.env[variable]) {
            let value = null;

            // Handle comma-separated lists
            if(splitVariables && 0 < splitVariables.length &&
               -1 < splitVariables.indexOf(variable)) {
                let list = process.env[variable];
                value = list.split(',');
            } else {
                value = process.env[variable];
            }

            // Validate against allowed range
            let rangeVariable = variable + rangeSuffix;
            if(config[rangeVariable]) {
                let range = config[rangeVariable];
                if(-1 === range.indexOf(value))
                    throw new Error('!!! variable: ' + variable +
                        ' has an invalid value: ' + value + ' !!!');
            }

            config[variable] = value;
        } else {
            config[variable] = defaultValue;
        }
    }

    return config;
};
```

**Key principles:**
- Read from `process.env` first, fallback to defaults
- Support comma-separated lists with `split(',')`
- Validate values against allowed ranges
- Throw descriptive errors with `!!!` markers for visibility

#### Spec-based Configuration

```javascript
const getConfiguration = (spec, config, then) => {
    console.log("[jscommons.getConfiguration|in] spec:", spec, "config:", config);
    let r = {};

    Object.keys(spec).forEach(internalVariable => {
        let externalVariable = spec[internalVariable];

        // Check config first, then environment
        if(config[externalVariable])
            r[internalVariable] = config[externalVariable];
        else if (process.env[externalVariable])
            r[internalVariable] = process.env[externalVariable];

        // Optional callback for post-processing
        if(r[internalVariable] && (typeof then === "function"))
            then(internalVariable, r);
    });

    console.log("[jscommons.getConfiguration|out] =>", r);
    return r;
};
```

**Key principles:**
- Use spec object to map internal names to external names
- Check multiple sources: config object, environment variables
- Support optional callback for post-processing
- Log entry and exit with consistent format

#### Configuration Merging

```javascript
const mergeConfiguration = (config1, config2) => {
    console.log("[jscommons.mergeConfiguration|in] :config1:", config1, "config2:", config2);
    let r = {};
    Object.keys(config1).forEach(key => r[key] = config1[key]);
    Object.keys(config2).forEach(key => r[key] = config2[key]);
    console.log("[jscommons.mergeConfiguration|out] =>", r);
    return r;
};
```

**Key principles:**
- config2 overwrites config1 (later wins)
- Create new object, don't mutate inputs
- Log input and output for debugging

### 3. Variable Handling Patterns

#### List Variables

```javascript
const handleListVariables = (variable, obj) => {
    console.log("[jscommons.handleListVariables|in] variable:", variable, "obj:", obj);

    if(variable.endsWith("_LIST")) {
        let idx = variable.lastIndexOf("_LIST");
        let new_variable = variable.substring(0, idx);

        if(!obj[new_variable]) {
            let val = obj[variable];
            obj[new_variable] = val.split(',');
        }
    }

    console.log("[jscommons.handleListVariables|out] =>", obj);
    return obj;
};
```

**Key principles:**
- Convert `VAR_LIST` to array at `VAR`
- Use convention: `_LIST` suffix indicates comma-separated value
- Only create if doesn't exist
- Mutate and return object

#### Nested Test Variables

```javascript
const handleTestVariables = (variable, obj) => {
    console.log("[jscommons.handleTestVariables|in] variable:", variable, "obj:", obj);

    let idx = variable.lastIndexOf('_TEST');
    if(-1 < idx && variable.length > (idx+5)) {
        let parent_variable = variable.substring(0, idx+5);

        if(!obj[parent_variable])
            obj[parent_variable] = {};

        let new_variable = variable.substring(idx+6);
        if(!obj[parent_variable][new_variable])
            obj[parent_variable][new_variable] = obj[variable];
    }

    console.log("[jscommons.handleTestVariables|out] =>", obj);
    return obj;
};
```

**Key principles:**
- Convert `VAR_TEST_SUBVAR` to nested object `{VAR_TEST: {SUBVAR: value}}`
- Use convention: `_TEST` followed by more chars creates nesting
- Create parent object if needed
- Preserve original flat variable

### 4. Naming Convention Patterns

#### Table/Resource Naming

Support versioned naming conventions:

```javascript
const getTableNameV1 = (tenant, entity, environment, entities, environments) => {
    if(-1 === entities.indexOf(entity))
        throw new Error('table not enabled: ' + entity);

    let result = `${tenant}_${entity}`;

    if (null !== environment) {
        if(-1 === environments.indexOf(environment))
            throw new Error('environment not enabled: ' + environment);
        result += '_' + environment;
    }

    return result;
};

const getTableNameV2 = (appname, entity, environment, environments) => {
    let result = `${appname}_${entity}`;

    if (null !== environment) {
        if(-1 === environments.indexOf(environment))
            throw new Error('environment not enabled: ' + environment);
        result += '_' + environment;
    }

    return result;
};

const getTableNameV3 = (appname, entity, environment) => {
    return `${appname}_${entity}_${environment}`;
};

const getTableNameV4 = (appname, entity, environment) => {
    return `${appname}-${environment}-${entity}`;
};
```

**Key principles:**
- Version naming convention functions (V1, V2, V3, V4)
- Support both underscore and hyphen delimiters
- Validate inputs against allowed lists when provided
- Allow optional environment parameter

### 5. Logging Patterns

#### Winston Configuration

```javascript
const winston = require('winston');

const getDefaultWinstonConfig = () => {
    return {
        level: 'debug',
        format: winston.format.combine(
            winston.format.splat(),
            winston.format.timestamp(),
            winston.format.printf(info => {
                return `${info.timestamp} ${info.level}: ${info.message}`;
            })
        ),
        transports: [new winston.transports.Console()]
    };
};
```

**Key principles:**
- Default to `debug` level
- Include timestamp in every log
- Use consistent format: `timestamp level: message`
- Log to console by default

#### Method Logging

```javascript
const method = (param1, param2) => {
    console.log("[jscommons.method|in] param1:", param1, "param2:", param2);

    // method implementation
    let result = doSomething();

    console.log("[jscommons.method|out] =>", result);
    return result;
};
```

**Key principles:**
- Log entry: `[namespace.method|in] param1: value1, param2: value2`
- Log exit: `[namespace.method|out] => returnValue`
- Always log inputs and outputs
- Use consistent format across all methods

## Code Style and Conventions

### Function Definitions

Use arrow functions for utility methods:

```javascript
const commons = {
    method1: (param1, param2, param3) => {
        // implementation
    },

    method2: (param1, param2) => {
        // implementation
    }
};
```

### Variable Declarations

- Use `const` for objects/arrays that won't be reassigned
- Use `let` for variables that will be reassigned
- Don't use `var`

### String Construction

Use template literals for string interpolation:

```javascript
// Good
let result = `${tenant}_${entity}_${environment}`;

// Avoid
let result = tenant + '_' + entity + '_' + environment;
```

### Comparisons

Be explicit with comparisons:

```javascript
// Check for -1 (not found)
if(-1 === array.indexOf(item))

// Check for existence
if(null !== value)

// Check for length
if(0 < array.length)
```

**Key principles:**
- Use `===` and `!==` (strict equality)
- Put constant on the left (Yoda conditions) to prevent assignment bugs
- Be explicit rather than relying on truthy/falsy

### Error Messages

Use exclamation marks for critical errors:

```javascript
throw new Error('!!! variable: ' + variable + ' has an invalid value: ' + value + ' !!!');
```

### Loops

Use `for...in` for object iteration:

```javascript
for(let i in variables) {
    let variable = variables[i];
    // process variable
}
```

Use `forEach` for clarity with arrays:

```javascript
Object.keys(spec).forEach(internalVariable => {
    // process internalVariable
});
```

## Package Configuration (package.json)

### Structure

```json
{
  "name": "@namespace/package",
  "version": "0.0.1",
  "description": "Brief description",
  "main": "index.js",
  "scripts": {
    "test": "./helper.sh test",
    "publicate": "./helper.sh publish"
  },
  "repository": {
    "type": "git",
    "url": "git+https://github.com/user/repo.git"
  },
  "keywords": ["javascript", "node"],
  "author": "Author Name <email@example.com>",
  "license": "Unlicense",
  "dependencies": {
    "winston": "^3.2.1"
  },
  "devDependencies": {
    "chai": "^4.2.0",
    "mocha": "^6.1.4",
    "istanbul": "^0.4.5",
    "coveralls": "^3.0.5"
  }
}
```

**Key principles:**
- Use scoped package names: `@namespace/package`
- Include repository information
- Use helper scripts for common tasks
- Include test coverage tools

## Testing Patterns

### Test Structure

```javascript
const { expect } = require('chai');
const { commons } = require('../index');

describe('commons', () => {
    describe('method1', () => {
        it('should handle normal case', () => {
            const result = commons.method1('input1', 'input2');
            expect(result).to.equal('expected');
        });

        it('should throw error for invalid input', () => {
            expect(() => {
                commons.method1('invalid');
            }).to.throw('error message');
        });
    });
});
```

**Key principles:**
- Use Mocha for test framework
- Use Chai for assertions
- Group tests with `describe`
- Use descriptive `it` descriptions
- Test both success and error cases

## Best Practices Summary

1. **Use strict mode** (`'use strict';`) in all files
2. **Export cleanly** via `module.exports` object
3. **Log consistently** with `[namespace.method|in/out]` format
4. **Handle configuration** from multiple sources (env, config object)
5. **Support list variables** with comma-separated values
6. **Version naming conventions** (V1, V2, V3, V4)
7. **Validate inputs** and throw descriptive errors
8. **Use template literals** for string construction
9. **Use strict equality** (`===` not `==`)
10. **Test thoroughly** with Mocha and Chai

## Common Utility Patterns

### Constants

Define common constants in the utility object:

```javascript
const commons = {
    navigationPositionMap: { 'first': 0, 'last': -1 },
    defaultPageSize: 12,

    // ... methods
};
```

### Callback Support

Accept optional callback functions for extensibility:

```javascript
const getConfiguration = (spec, config, then) => {
    // ... implementation

    if(result[key] && (typeof then === "function"))
        then(key, result);

    return result;
};
```

**Key principles:**
- Check if callback is actually a function: `typeof then === "function"`
- Make callbacks optional
- Pass relevant context to callback
