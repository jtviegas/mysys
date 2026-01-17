# Bash Helper Script Patterns - DevOps Automation

This document captures patterns for building `helper.sh` bash scripts used for local development and CI/CD automation, focusing on consistent structure, reusable functions, and environment management.

## Table of Contents

- [Script Structure](#script-structure)
- [Common Section Pattern](#common-section-pattern)
- [Environment Management](#environment-management)
- [Function Patterns](#function-patterns)
- [Logging Patterns](#logging-patterns)
- [Error Handling](#error-handling)
- [Usage Documentation](#usage-documentation)
- [CI/CD Integration](#cicd-integration)

## Script Structure

### Standard Helper Script Layout

```bash
#!/usr/bin/env bash

# ===> COMMON SECTION START  ===>
# - Shell options
# - Directory detection
# - Logging functions
# - Constants
# - Environment loading
# - bashutils inclusion
# <=== COMMON SECTION END  <===

# ===> MAIN SECTION START  ===>
# - Project-specific constants
# - Project-specific functions
# - Usage function
# - Main dispatch logic
# <=== MAIN SECTION END  <===
```

**Key principles:**
- Shebang with `env` for portability
- Separate common from project-specific
- Clear section markers
- Consistent structure across projects

## Common Section Pattern

### 1. Shell Options and Directory Detection

```bash
#!/usr/bin/env bash

# Enable nullglob for safer file globbing
shopt -s nullglob

# Detect script directory (works with symlinks)
this_folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
if [ -z "$this_folder" ]; then
  this_folder=$(dirname $(readlink -f $0))
fi
parent_folder=$(dirname "$this_folder")
```

**Key principles:**
- Use `BASH_SOURCE[0]` for script location
- Change to script directory for reliability
- Fallback to `readlink -f` for edge cases
- Store parent folder for relative paths
- Use `shopt -s nullglob` to handle empty globs safely

### 2. Logging Functions

```bash
debug(){
    local __msg="$1"
    echo " [DEBUG] `date` ... $__msg "
}

info(){
    local __msg="$1"
    echo " [INFO]  `date` ->>> $__msg "
}

warn(){
    local __msg="$1"
    echo " [WARN]  `date` *** $__msg "
}

err(){
    local __msg="$1"
    echo " [ERR]   `date` !!! $__msg "
}
```

**Key principles:**
- Four log levels: debug, info, warn, err
- Timestamp with backticks for command substitution
- Visual indicators: `...`, `->>>`, `***`, `!!!`
- Local variables for safety
- Consistent spacing and formatting

### 3. Environment File Constants

```bash
export FILE_VARIABLES=${FILE_VARIABLES:-".variables"}
export FILE_LOCAL_VARIABLES=${FILE_LOCAL_VARIABLES:-".local_variables"}
export FILE_SECRETS=${FILE_SECRETS:-".secrets"}
export NAME="bashutils"
export INCLUDE_FILE=".${NAME}"
export TAR_NAME="${NAME}.tar.bz2"
```

**Key principles:**
- Use `${VAR:-default}` for defaults
- Export for child processes
- Consistent file naming
- Prefix with dot for hidden files

### 4. Environment Loading Pattern

```bash
# Load .variables file
if [ ! -f "$this_folder/$FILE_VARIABLES" ]; then
  warn "we DON'T have a $FILE_VARIABLES variables file - creating it"
  touch "$this_folder/$FILE_VARIABLES"
else
  . "$this_folder/$FILE_VARIABLES"
fi

# Load .local_variables file (local overrides)
if [ ! -f "$this_folder/$FILE_LOCAL_VARIABLES" ]; then
  warn "we DON'T have a $FILE_LOCAL_VARIABLES variables file - creating it"
  touch "$this_folder/$FILE_LOCAL_VARIABLES"
else
  . "$this_folder/$FILE_LOCAL_VARIABLES"
fi

# Load .secrets file (secrets, gitignored)
if [ ! -f "$this_folder/$FILE_SECRETS" ]; then
  warn "we DON'T have a $FILE_SECRETS secrets file - creating it"
  touch "$this_folder/$FILE_SECRETS"
else
  . "$this_folder/$FILE_SECRETS"
fi
```

**Key principles:**
- Check file existence before sourcing
- Create empty file if missing (fail-safe)
- Source with `.` command
- Three-tier config: variables → local → secrets
- Local overrides global
- Secrets last (highest priority)

### 5. External Library Inclusion

```bash
# Include bashutils library
. ${this_folder}/${INCLUDE_FILE}

# Function to update bashutils from GitHub
update_bashutils(){
  echo "[update_bashutils] ..."

  tar_file="${NAME}.tar.bz2"
  _pwd=`pwd`
  cd "$this_folder"

  curl -s https://api.github.com/repos/user/bashutils/releases/latest \
    | grep "browser_download_url.*${NAME}\.tar\.bz2" \
    | cut -d '"' -f 4 | wget -qi -

  tar xjpvf $tar_file
  if [ ! "$?" -eq "0" ]; then
    echo "[update_bashutils] could not untar it"
    cd "$_pwd"
    return 1
  fi
  rm $tar_file

  cd "$_pwd"
  echo "[update_bashutils] ...done."
}
```

**Key principles:**
- Include external utilities
- Provide update mechanism
- Use GitHub releases API
- Download latest version automatically
- Extract and clean up
- Preserve working directory

## Function Patterns

### 6. Consistent Function Structure

```bash
function_name(){
  info "[function_name|in] ($1, $2)"

  # Parameter validation
  [ -z "$1" ] && usage

  # Local variables
  local param1="$1"
  local param2="$2"
  local result=""

  # Save current directory
  _pwd=`pwd`
  cd "$target_folder"

  # Function logic here
  # ...

  result="$?"

  # Restore directory
  cd "$_pwd"

  # Error handling
  [ "$result" -ne "0" ] && err "[function_name|out]  => ${result}" && exit 1

  info "[function_name|out] => ${result}"
}
```

**Key principles:**
- Log entry with parameters: `[function|in] (params)`
- Validate required parameters early
- Use local variables
- Save and restore working directory
- Capture exit codes
- Log exit with result: `[function|out] => result`
- Exit on error with non-zero code

### 7. Build and Test Functions

```bash
lib_deps(){
  info "[lib_deps|in]"
  _pwd=`pwd`
  cd "$this_folder"

  npm ci

  result="$?"
  cd "$_pwd"
  [ "$result" -ne "0" ] && err "[lib_deps|out]  => ${result}" && exit 1
  info "[lib_deps|out] => ${result}"
}

lib_build(){
  info "[lib_build|in]"
  _pwd=`pwd`
  cd "$this_folder"

  npm run build

  result="$?"
  cd "$_pwd"
  [ "$result" -ne "0" ] && err "[lib_build|out]  => ${result}" && exit 1
  info "[lib_build|out] => ${result}"
}

lib_test(){
  info "[lib_test|in]"
  _pwd=`pwd`
  cd "$this_folder"

  npm run coverage

  result="$?"
  cd "$_pwd"
  [ "$result" -ne "0" ] && err "[lib_test|out]  => ${result}" && exit 1
  info "[lib_test|out] => ${result}"
}
```

**Key principles:**
- Consistent naming: `lib_*`, `cdk_*`, `app_*`
- Run from project root
- Capture and check exit codes
- Exit on failure (CI/CD friendly)
- Use `npm ci` for reproducible installs

### 8. Deployment Functions

```bash
lib_publish(){
  info "[lib_publish|in]"
  _pwd=`pwd`
  cd "$this_folder"

  npm publish

  result="$?"
  cd "$_pwd"
  [ "$result" -ne "0" ] && err "[lib_publish|out]  => ${result}" && exit 1
  info "[lib_publish|out] => ${result}"
}

cdk_deploy(){
  info "[cdk_deploy|in] ($1, $2)"

  [ -z "$1" ] && usage
  [ -z "$2" ] && usage

  local stack_name="$1"
  local environment="$2"

  _pwd=`pwd`
  cd "$this_folder"

  ENVIRONMENT="$environment" cdk deploy "$stack_name" --require-approval never

  result="$?"
  cd "$_pwd"
  [ "$result" -ne "0" ] && err "[cdk_deploy|out]  => ${result}" && exit 1
  info "[cdk_deploy|out] => ${result}"
}
```

**Key principles:**
- Validate required parameters
- Pass environment variables
- Use `--require-approval never` for CI/CD
- Parameterize stack names and environments

### 9. Setup and Initialization Functions

```bash
cdk_global_reqs(){
  info "[cdk_global_reqs|in]"

  npm install -g "typescript@${TYPESCRIPT_VERSION}" \
                 "aws-cdk@${CDK_VERSION}" \
                 ts-node \
                 @aws-cdk/integ-runner \
                 @aws-cdk/integ-tests-alpha

  result="$?"
  [ "$result" -ne "0" ] && err "[cdk_global_reqs|out]  => ${result}" && exit 1
  info "[cdk_global_reqs|out] => ${result}"
}

cdk_proj_setup(){
  info "[cdk_proj_setup|in] ($1)"

  [ -d "$1" ] && info "[cdk_proj_setup|out] folder exists: $1" && exit 0

  local folder="$1"
  mkdir -p "$folder"

  _pwd=$(pwd)
  cd "$folder"

  cdk_global_reqs
  cdk init app --language typescript

  result="$?"
  cd "$_pwd"
  [ "$result" -ne "0" ] && err "[cdk_proj_setup|out]  => ${result}" && exit 1
  info "[cdk_proj_setup|out] => ${result}"
}
```

**Key principles:**
- Install global dependencies
- Check if already initialized
- Use version variables from environment
- Bootstrap projects with standard templates

### 10. AWS-Specific Functions

```bash
get_cloudfront_cidr(){
  info "[get_cloudfront_cidr|in] ($1)"

  [ -z "$1" ] && usage
  local output_file="$1"

  # Get CloudFront prefix list ID
  prefix_list_id=$(aws ec2 describe-managed-prefix-lists \
    | jq -r '.PrefixLists | .[] | select(.PrefixListName == "com.amazonaws.global.cloudfront.origin-facing") | .PrefixListId')

  # Get CIDR blocks
  outputs=$(aws ec2 get-managed-prefix-list-entries --prefix-list-id "$prefix_list_id" --output json)
  echo $outputs | jq -r '.Entries' > "$output_file"

  result="$?"
  [ "$result" -ne "0" ] && err "[get_cloudfront_cidr|out]  => ${result}" && exit 1
  info "[get_cloudfront_cidr|out] => ${result}"
}
```

**Key principles:**
- Use AWS CLI with JSON output
- Pipe through `jq` for parsing
- Save results to file
- Check command success

## Logging Patterns

### 11. Structured Logging

```bash
# Log entry with parameters
info "[function_name|in] (param1: $1, param2: $2)"

# Log intermediate steps
info "[function_name] installing dependencies..."
debug "[function_name] using version: ${VERSION}"

# Log warnings
warn "[function_name] file not found, creating: $FILE"

# Log errors before exit
err "[function_name] command failed with code: $result"

# Log exit with result
info "[function_name|out] => ${result}"
```

**Key principles:**
- Use `[function|in]` for entry
- Use `[function|out]` for exit
- Use `[function]` for steps
- Include relevant data in logs
- Log warnings for recoverable issues
- Log errors before exiting

### 12. Debug Mode Support

```bash
# Enable debug mode via environment
DEBUG=${DEBUG:-0}

debug(){
    local __msg="$1"
    [ "$DEBUG" -eq "1" ] && echo " [DEBUG] `date` ... $__msg "
}

# Usage
DEBUG=1 ./helper.sh some_command
```

**Key principles:**
- Optional debug output
- Control via environment variable
- Silent by default
- Detailed when needed

## Error Handling

### 13. Exit Code Pattern

```bash
command_to_run
result="$?"

if [ ! "$result" -eq "0" ]; then
  err "[function_name] command failed with code: $result"
  exit 1
fi

# Or one-liner:
[ "$result" -ne "0" ] && err "[function_name|out] => ${result}" && exit 1
```

**Key principles:**
- Capture exit codes immediately
- Check against zero (success)
- Log error before exiting
- Exit with non-zero for CI/CD
- Use `[ ]` or `[[ ]]` for conditions

### 14. Validation Pattern

```bash
validate_params(){
  # Required parameter
  [ -z "$1" ] && err "missing required parameter" && usage

  # Check file exists
  [ ! -f "$FILE" ] && err "file not found: $FILE" && exit 1

  # Check directory exists
  [ ! -d "$DIR" ] && err "directory not found: $DIR" && exit 1

  # Check command available
  command -v aws >/dev/null 2>&1 || { err "aws cli not installed"; exit 1; }
}
```

**Key principles:**
- Validate early
- Provide clear error messages
- Call usage on missing params
- Exit immediately on validation failure

## Usage Documentation

### 15. Usage Function Pattern

```bash
usage() {
  cat <<EOM
  usage:
  $(basename $0) { option }

      options:

      - commands:         lists handy commands

      - update_bashutils: updates bashutils library from GitHub

      - lib:
        - deps:           install dependencies (npm ci)
        - build:          build library (npm run build)
        - test:           run unit tests (npm run test)
        - coverage:       run tests with coverage
        - publish:        publish to npm registry

      - cdk:
        - global_reqs:    install global CDK dependencies
        - proj_setup:     initialize new CDK project
        - deploy <stack> <env>: deploy stack to environment
        - destroy <stack>: destroy stack

      - aws:
        - get_cloudfront_cidr <file>: get CloudFront CIDR blocks

  examples:
    $(basename $0) lib build
    $(basename $0) lib test
    $(basename $0) cdk deploy MyStack dev
    $(basename $0) aws get_cloudfront_cidr cidr.json

EOM
}
```

**Key principles:**
- Use heredoc (`<<EOM`) for multi-line
- Show script name with `basename $0`
- Organize by category
- Include examples
- Document parameters
- Clear, consistent formatting

### 16. Commands Function

```bash
commands(){
  cat <<EOM
  --- handy commands ---

  # Install dependencies
  npm ci

  # Build
  npm run build

  # Test
  npm run test
  npm run coverage

  # Deploy
  ENVIRONMENT=dev cdk deploy StackName --require-approval never

  # Synth
  ENVIRONMENT=dev cdk synth StackName

  # Diff
  ENVIRONMENT=dev cdk diff StackName

EOM
}
```

**Key principles:**
- Provide copy-paste ready commands
- Include environment variables
- Show common workflows
- Document CI/CD commands

## CI/CD Integration

### 17. Main Dispatch Pattern

```bash
# Main script logic
case $1 in
  commands)
    commands
    ;;
  update_bashutils)
    update_bashutils
    ;;
  lib)
    case $2 in
      deps)
        lib_deps
        ;;
      build)
        lib_build
        ;;
      test)
        lib_test
        ;;
      coverage)
        lib_test
        ;;
      publish)
        lib_publish
        ;;
      *)
        usage
        ;;
    esac
    ;;
  cdk)
    case $2 in
      global_reqs)
        cdk_global_reqs
        ;;
      proj_setup)
        cdk_proj_setup "$3"
        ;;
      deploy)
        cdk_deploy "$3" "$4"
        ;;
      *)
        usage
        ;;
    esac
    ;;
  aws)
    case $2 in
      get_cloudfront_cidr)
        get_cloudfront_cidr "$3"
        ;;
      *)
        usage
        ;;
    esac
    ;;
  *)
    usage
    ;;
esac
```

**Key principles:**
- Nested case statements for subcommands
- Pass remaining arguments to functions
- Default to usage on unknown command
- Hierarchical command structure
- Easy to extend with new commands

### 18. CI/CD Pipeline Integration

```bash
# In CI/CD pipeline (e.g., Azure DevOps, GitHub Actions)

# Setup
./helper.sh cdk global_reqs

# Install dependencies
./helper.sh lib deps

# Build
./helper.sh lib build

# Test
./helper.sh lib test

# Deploy
./helper.sh cdk deploy MyStack ${ENVIRONMENT}
```

**Key principles:**
- Single script for all operations
- Works locally and in CI/CD
- Environment variable driven
- Consistent interface
- Easy to parallelize

## Best Practices Summary

1. **Consistent Structure**: Common section + Main section
2. **Directory Safety**: Save/restore working directory
3. **Environment Tiers**: .variables → .local_variables → .secrets
4. **Structured Logging**: [function|in/out] with timestamps
5. **Error Handling**: Check exit codes, log errors, exit non-zero
6. **Parameter Validation**: Check early, fail fast
7. **Usage Documentation**: Clear help with examples
8. **Nested Commands**: Hierarchical case statements
9. **CI/CD Friendly**: Non-interactive, exit code driven
10. **Reusable Functions**: Consistent naming, clear contracts
11. **External Libraries**: Include and update mechanisms
12. **Local Variables**: Use `local` for function scope
13. **Quoting**: Quote variables to handle spaces
14. **Portable Shebang**: Use `#!/usr/bin/env bash`
15. **Version Control**: Track helper.sh, gitignore secrets

## File Organization

### Standard Files

```
project/
├── helper.sh              # Main automation script
├── .variables             # Project variables (tracked)
├── .local_variables       # Local overrides (tracked)
├── .secrets               # Secrets (gitignored)
├── .bashutils             # External bash library (tracked)
└── .gitignore             # Ignore secrets and local files
```

### .gitignore Pattern

```gitignore
# Environment
.secrets
.env

# Logs
*.log

# Dependencies
node_modules/

# Build
dist/
build/
```

**Key principles:**
- Track helper.sh and .variables
- Gitignore .secrets
- Optional: gitignore .local_variables
- Track .bashutils for offline use
