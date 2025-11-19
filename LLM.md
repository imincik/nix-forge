# Nix Forge Recipe Generation Specification for LLMs

## Overview

This specification guides LLMs in generating Nix Forge recipes - declarative configuration files for building software packages and applications.

### Supported Project Types

**IMPORTANT:** Nix Forge currently supports the following types of projects:

1. **Python packages** - Projects with `pyproject.toml` or `setup.py` (use `pythonAppBuilder`)
2. **CMake-based projects** - Projects with `CMakeLists.txt` (use `standardBuilder`)
3. **Autotools-based projects** - Projects with `configure` or `configure.ac` (use `standardBuilder`)
4. **Makefile-based projects** - Projects with standard `Makefile` targets (use `standardBuilder`)


## Recipe File Structure

### Location
- **Packages**: `outputs/packages/<package-name>/recipe.nix`
- **Apps**: `outputs/apps/<app-name>/recipe.nix`

### Basic Template
```nix
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Recipe fields go here
}
```

**Note**: The function parameters are REQUIRED and should always be included, even if not used.

### Accessing Nix Forge Packages

Other packages built by Nix Forge can be referenced in recipes using `pkgs.mypkgs`:

```nix
{
  # Reference another Nix Forge package
  requirements.build = [
    pkgs.mypkgs.gdal  # Access gdal from Nix Forge
  ];
}
```

This follows the same pattern as accessing nixpkgs packages (e.g., `pkgs.sqlite`).

### Important: Git Tracking Required

**CRITICAL**: All new recipe files MUST be added to git before they can be used by the Nix flake system.

After creating a new recipe file, you must run:
```bash
git add outputs/packages/<package-name>/recipe.nix
# or for apps:
git add outputs/apps/<app-name>/recipe.nix
```

The flake uses `import-tree` to automatically discover recipes, but it only sees files tracked by git. Without adding the file to git, the package will not be recognized and `nix build .#<package-name>` will fail with an error like:
```
error: flake does not provide attribute 'packages.x86_64-linux.<package-name>'
```

## Package Recipes

### Required Fields
```nix
{
  name = "package-name";           # String, lowercase with hyphens
  version = "1.0.0";               # String, semantic versioning
  description = "Short description of the package.";

  # Source: EXACTLY ONE of these must be defined
  source.git = "github:owner/repo/commit-or-tag";  # OR
  source.url = "https://...";
  source.hash = "sha256-...";      # Required with url, optional with git

  # Builder: EXACTLY ONE must be enabled
  build.plainBuilder.enable = true;      # OR
  build.standardBuilder.enable = true;   # OR
  build.pythonAppBuilder.enable = true;
}
```

### Optional but Recommended Fields
```nix
{
  homePage = "https://project-website.org";
  mainProgram = "executable-name";  # Main binary name for the package
}
```

## Builder Types

### 1. standardBuilder (Most Common)
**When to use**: Standard autotools/cmake/make-based projects

```nix
{
  build.standardBuilder = {
    enable = true;
    requirements.native = [
      pkgs.cmake
      pkgs.pkg-config
    ];
    requirements.build = [
      pkgs.openssl
      pkgs.zlib
    ];
  };
}
```

**Characteristics**:
- Automatic configure, build, install phases
- Follows standard build conventions
- Use for: C/C++ projects with configure scripts or CMake

### 2. plainBuilder (Custom Build)
**When to use**: Non-standard build processes requiring custom phases

```nix
{
  build.plainBuilder = {
    enable = true;
    requirements.native = [
      pkgs.cmake
    ];
    requirements.build = [
      pkgs.somelib
    ];
    configure = ''
      mkdir build && cd build
      cmake -DCMAKE_INSTALL_PREFIX=$out ..
    '';
    build = ''
      make -j $NIX_BUILD_CORES
    '';
    check = ''
      make test
    '';
    install = ''
      make install
    '';
  };
}
```

**When to use**:
- Custom build steps needed
- Non-standard directory structure
- Special environment setup required

### 3. pythonAppBuilder (Python Applications)
**When to use**: Python applications with pyproject.toml

```nix
{
  build.pythonAppBuilder = {
    enable = true;
    requirements.build-system = [
      pkgs.python3Packages.setuptools
    ];
    requirements.dependencies = [
      pkgs.python3Packages.flask
      pkgs.python3Packages.requests
    ];
  };
}
```

**Note**: Use pkgs.python3Packages.* for Python dependencies

## Source Configuration

### Git Sources
**Format**: `forge:owner/repository/revision`

```nix
source = {
  git = "github:torvalds/linux/v6.1";  # Tag
  git = "gitlab:group/project/abc123";  # Commit hash
  hash = "sha256-...";  # Optional but recommended
};
```

**Supported forges**: github, gitlab

### URL Sources
```nix
source = {
  url = "https://releases.example.com/package-1.0.0.tar.gz";
  url = "mirror://gnu/hello/hello-2.12.1.tar.gz";  # Nix mirrors
  hash = "sha256-...";  # REQUIRED
};
```

## Test Configuration

```nix
test = {
  requirements = [ pkgs.curl ];  # Additional test dependencies
  script = ''
    # Test commands
    $out/bin/program --version
    $out/bin/program --help
  '';
};
```

**Best practices**:
- Test main functionality
- Verify version output
- Check help/usage works
- Keep tests fast (< 10 seconds)

## Development Environment

```nix
development = {
  requirements = [ pkgs.gdb pkgs.valgrind ];  # Dev tools
  shellHook = ''
    echo "Development environment ready"
    echo "Source code: clone from ${source.git}"
  '';
};
```

## Advanced: extraDrvAttrs

For expert-level customization:

```nix
build.extraDrvAttrs = {
  preConfigure = ''
    export HOME=$(mktemp -d)
  '';
  postInstall = ''
    wrapProgram $out/bin/program \
      --set SOME_VAR value
  '';
  enableParallelBuilding = true;
};
```

**Common use cases**:
- `preConfigure`: Set environment before configure
- `postInstall`: Wrap binaries, add extra files
- `patches`: Apply source patches
- `configureFlags`: Pass flags to configure script

## Application Recipes

### Structure
```nix
{
  name = "app-name";
  version = "1.0.0";
  description = "Application description.";
  usage = "Usage instructions in markdown...";  # Optional but helpful

  # Choose output types:
  programs = { ... };    # Shell bundle
  containers = { ... };  # Docker containers
  vm = { ... };         # NixOS VM
}
```

### Programs (Shell Bundle)
```nix
programs = {
  requirements = [
    pkgs.mypkgs.my-package  # Reference packages from forge
    pkgs.curl
  ];
};
```

### Containers
```nix
containers = {
  images = [
    {
      name = "api-server";
      requirements = [ pkgs.mypkgs.my-package ];
      config.CMD = [ "my-package" "--serve" ];
    }
  ];
  composeFile = ./compose.yaml;  # Optional
};
```

### Virtual Machine
```nix
vm = {
  enable = true;
  name = "my-vm";
  requirements = [ pkgs.mypkgs.my-package ];
  config = {
    ports = [ "8080:8080" ];
    system = {
      services.postgresql.enable = true;
      systemd.services.my-service = {
        script = "${pkgs.mypkgs.my-package}/bin/my-package";
        wantedBy = [ "multi-user.target" ];
      };
    };
  };
};
```

## LLM Generation Guidelines

### 1. Information Gathering
Before generating a recipe, determine:
- **Software name and version**
- **Programming language/build system**
- **Source location** (GitHub URL, release tarball)
- **Build dependencies** (libraries, tools)
- **Runtime dependencies**
- **Main executable name**

### 2. Builder Selection Logic
```
IF Python project with pyproject.toml:
  → pythonAppBuilder

ELSE IF has configure script OR uses CMake OR standard Makefile:
  → standardBuilder

ELSE IF custom build process:
  → plainBuilder
```

### 3. Dependency Resolution
- **Build tools**: cmake, pkg-config, autoconf → `requirements.native`
- **Libraries**: openssl, zlib, curl → `requirements.build`
- **Python packages**: Use `pkgs.python3Packages.*`
- **Unknown packages**: Use `pkgs.<package-name>`

### 4. Hash Determination
When hash is unknown:
```nix
source.hash = "";  # Leave empty initially
# Nix will error with correct hash, then update recipe
```

### 5. Validation Checklist
- [ ] Exactly one builder enabled
- [ ] Source has git XOR url (not both)
- [ ] Hash present for URL sources
- [ ] name is lowercase-with-hyphens
- [ ] mainProgram matches actual executable
- [ ] Test script tests main functionality
- [ ] No hardcoded /nix/store paths

## Common Patterns

### Pattern 1: Simple GitHub Project
```nix
{
  config,
  lib,
  pkgs,
  mypkgs,
  ...
}:

{
  name = "ripgrep";
  version = "14.0.0";
  description = "Fast line-oriented search tool.";
  homePage = "https://github.com/BurntSushi/ripgrep";
  mainProgram = "rg";

  source = {
    git = "github:BurntSushi/ripgrep/14.0.0";
    hash = "sha256-...";
  };

  build.standardBuilder = {
    enable = true;
    requirements.native = [
      pkgs.rustc
      pkgs.cargo
    ];
    requirements.build = [ ];
  };

  test.script = ''
    rg --version | grep "14.0.0"
  '';
}
```

### Pattern 2: C Project with Dependencies
```nix
{
  config,
  lib,
  pkgs,
  mypkgs,
  ...
}:

{
  name = "nginx";
  version = "1.24.0";
  description = "HTTP and reverse proxy server.";
  homePage = "https://nginx.org";
  mainProgram = "nginx";

  source = {
    url = "https://nginx.org/download/nginx-1.24.0.tar.gz";
    hash = "sha256-...";
  };

  build.standardBuilder = {
    enable = true;
    requirements.native = [
      pkgs.which
    ];
    requirements.build = [
      pkgs.openssl
      pkgs.pcre
      pkgs.zlib
    ];
  };

  test.script = ''
    nginx -v 2>&1 | grep "1.24.0"
  '';
}
```

### Pattern 3: Python Application
```nix
{
  config,
  lib,
  pkgs,
  mypkgs,
  ...
}:

{
  name = "mypy";
  version = "1.7.0";
  description = "Static type checker for Python.";
  homePage = "https://mypy-lang.org";
  mainProgram = "mypy";

  source = {
    git = "github:python/mypy/v1.7.0";
    hash = "sha256-...";
  };

  build.pythonAppBuilder = {
    enable = true;
    requirements.build-system = [
      pkgs.python3Packages.setuptools
    ];
    requirements.dependencies = [
      pkgs.python3Packages.typing-extensions
      pkgs.python3Packages.mypy-extensions
    ];
  };

  test.script = ''
    mypy --version | grep "1.7.0"
  '';
}
```

## Error Handling

### Common Issues and Solutions

**Issue**: "source.git or source.url must be defined"
- **Solution**: Ensure exactly one source method is specified

**Issue**: "Only one builder can be enabled"
- **Solution**: Set only one `build.*.enable = true`

**Issue**: Hash mismatch
- **Solution**: Update hash with value from error message

**Issue**: Missing dependency
- **Solution**: Add to requirements.native or requirements.build

## Naming Conventions

- **Package names**: lowercase-with-hyphens (e.g., `my-package`)
- **Versions**: Semantic versioning (e.g., `1.2.3`, `2024-01-15`)
- **File paths**: Use `./` for relative paths (e.g., `./compose.yaml`)
- **Programs**: Binary name, not display name (e.g., `rg` not `ripgrep`)

## Summary for LLMs

When generating a Nix Forge recipe:
1. **Identify** the software and gather information
2. **Choose** appropriate builder based on build system
3. **Define** source (git or url with hash)
4. **List** all dependencies in correct categories
5. **Write** meaningful test script
6. **Validate** against checklist
7. **Format** consistently with examples

The goal is a **declarative, reproducible, and testable** package definition that abstracts Nix complexity while maintaining flexibility.

---

# Repository Analysis Process for Creating Recipes

This section provides a systematic process for analyzing third-party software repositories and creating Nix Forge recipes.

## Step-by-Step Repository Analysis

### Step 1: Identify Build System

Check for these files in the repository (in order of priority):

1. **Python Projects**
   - `pyproject.toml` → Use `pythonAppBuilder`
   - `setup.py` → Use `pythonAppBuilder`

2. **CMake Projects**
   - `CMakeLists.txt` → Use `standardBuilder`

3. **Autotools Projects**
   - `configure.ac` or `configure` → Use `standardBuilder`

4. **Makefile Projects**
   - `Makefile` with standard targets (all, install, clean) → Use `standardBuilder`

### Step 2: Check Repository Structure

**Critical checks:**

- [ ] **Is the build file in the root directory?** (most common case)
  - If YES: No special configuration needed
  - If NO: Determine the subdirectory

- [ ] **Is the code in a subdirectory?**
  - Example: `geodiff/geodiff/CMakeLists.txt` (build file is in `geodiff/` subdirectory)
  - Solution: Set `build.extraDrvAttrs.sourceRoot = "source/<subdir>";`

- [ ] **Is this a monorepo with multiple projects?**
  - Identify the correct subdirectory for the package you want to build

### Step 3: Check for Git Submodules

**IMPORTANT:** The current `source.git` implementation does NOT fetch git submodules.

Check for submodules:
```bash
# Look for .gitmodules file in the repository
# Check repository structure for empty/missing subdirectories
```

**If git submodules exist:**
- Note that dependencies may be missing
- Consider that the build might fail due to missing submodule content
- May need to provide vendored dependencies separately via `nativeBuildInputs`

### Step 4: Identify Dependencies

**Where to look:**

1. **CMake projects** (`CMakeLists.txt`):
   - `find_package(<PackageName>)` → Required dependency
   - `pkg_check_modules(<VAR> <package>)` → pkg-config dependency
   - Look for library names and map to nixpkgs

2. **Python projects** (`pyproject.toml`, `setup.py`, `requirements.txt`):
   - `[project.dependencies]` section in pyproject.toml
   - `install_requires` in setup.py
   - Map to `pkgs.python3Packages.<name>`

3. **Autotools projects** (`configure.ac`):
   - `PKG_CHECK_MODULES([VAR], [package])` → pkg-config dependency
   - `AC_CHECK_LIB([library], [function])` → Library dependency

4. **README.md, INSTALL.md, or documentation**:
   - Often lists required dependencies for building

5. **CI Configuration** (`.github/workflows/`, `.gitlab-ci.yml`):
   - Shows what gets installed before building
   - Reveals build and test dependencies

**Dependency categories:**

- **Build tools** (cmake, pkg-config, autoconf, meson, ninja) → `requirements.native`
- **Libraries** (sqlite, gdal, openssl, zlib, postgresql) → `requirements.build`
- **Python packages** → `pkgs.python3Packages.<name>` in dependencies

### Step 5: Check for External/Vendored Dependencies

**Warning signs of problematic external downloads:**

- `external/` or `third_party/` directories (may be git submodules)
- `ExternalProject_Add()` in CMakeLists.txt (downloads during build - **PROBLEM!**)
- `FetchContent` in CMake (downloads during build - **PROBLEM!**)
- Download scripts in build files

**If external downloads occur during build:**

Nix builds in a sandbox without network access. You must:

1. **Option 1:** Disable with CMake/build flags
   ```nix
   build.extraDrvAttrs = {
     cmakeFlags = [ "-DUSE_EXTERNAL_LIBS=OFF" ];
   };
   ```

2. **Option 2:** Provide dependencies via nativeBuildInputs
   ```nix
   requirements.native = [ pkgs.somelib ];
   ```

3. **Option 3:** Patch build files to remove download steps
   ```nix
   build.extraDrvAttrs = {
     postPatch = ''
       substituteInPlace CMakeLists.txt \
         --replace-fail "ExternalProject_Add" "# ExternalProject_Add"
     '';
   };
   ```

### Step 6: Find the Main Executable

**Where to look:**

- `bin/` directory in source code
- CMake: `add_executable(<name> ...)` in CMakeLists.txt
- Python: `[project.scripts]` in pyproject.toml or `entry_points` in setup.py
- README.md usage examples (e.g., `$ geodiff --help`)

**Set in recipe:**
```nix
mainProgram = "executable-name";  # Just the binary name, not the path
```

### Step 7: Identify Latest Version

- Check GitHub releases page for latest stable release
- Prefer released versions over git commit hashes
- Use version tags (e.g., `v1.2.3` or `1.2.3`)

### Step 8: Identify Tests

**Where to look:**

- `test/` or `tests/` directory
- CMake: `enable_testing()`, `add_test()`, or `BUILD_TESTING` option
- Python: `pytest`, `unittest`, test files matching `test_*.py`
- CI configuration shows test commands

**For recipe test.script:**

- **Minimum:** `--version` and `--help` flags
- **Better:** Simple import test (Python), basic functional test
- **Keep fast:** Tests should complete in < 10 seconds

## Common Build Issues and Solutions

### Issue 1: "CMakeLists.txt not found"

**Error message:**
```
CMake Error: The source directory does not appear to contain CMakeLists.txt
```

**Diagnosis:** Build files are in a subdirectory, not the root.

**Solution:**
```nix
build.extraDrvAttrs = {
  sourceRoot = "source/<subdirectory>";
};
```

**Example:**
```nix
build.extraDrvAttrs = {
  sourceRoot = "source/geodiff";  # For geodiff/geodiff/CMakeLists.txt
};
```

### Issue 2: "Cannot download during build"

**Error message:**
```
CMake Error at CMakeLists.txt:104 (INCLUDE):
  INCLUDE could not find requested file:
    /build/source/build/external/libgpkg-.../UseTLS.cmake
```

**Diagnosis:**
- CMake tries to download dependencies with `ExternalProject_Add()` or `FetchContent`
- Git submodules not fetched
- Build downloads external resources

**Solutions:**

1. **Disable downloads via CMake flags:**
   ```nix
   build.extraDrvAttrs = {
     cmakeFlags = [ "-DUSE_SYSTEM_LIBS=ON" "-DENABLE_EXTERNAL_DOWNLOAD=OFF" ];
   };
   ```

2. **Provide missing dependencies:**
   ```nix
   requirements.build = [ pkgs.libgpkg ];  # If available in nixpkgs
   ```

3. **Patch CMakeLists.txt:**
   ```nix
   build.extraDrvAttrs = {
     postPatch = ''
       substituteInPlace CMakeLists.txt \
         --replace-fail "include(ExternalProject)" ""
     '';
   };
   ```

### Issue 3: "Python dependency version mismatch"

**Error message:**
```
ERROR Missing dependencies:
  cython~=3.0.2
```

**Diagnosis:** Python package requires specific version, but nixpkgs has different version.

**Solution:** Relax version constraint by patching pyproject.toml:
```nix
build.extraDrvAttrs = {
  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail "cython~=3.0.2" "cython"
  '';
};
```

### Issue 4: "Missing Python runtime dependencies"

**Error message:**
```
Checking runtime dependencies for package.whl
  - attrs not installed
  - click not installed
```

**Diagnosis:** Python package has runtime dependencies not listed in recipe.

**Solution:** Add missing packages to dependencies:
```nix
build.pythonAppBuilder = {
  requirements = {
    dependencies = [
      pkgs.python3Packages.attrs
      pkgs.python3Packages.click
      # ... other dependencies
    ];
  };
};
```

### Issue 5: "Tests enabled but fail or unwanted"

**Diagnosis:** Build system enables tests by default, but they fail or slow down build.

**Solutions:**

For CMake:
```nix
build.extraDrvAttrs = {
  cmakeFlags = [ "-DENABLE_TESTS=OFF" "-DBUILD_TESTING=OFF" ];
};
```

For Meson:
```nix
build.extraDrvAttrs = {
  mesonFlags = [ "-Dtests=false" ];
};
```

For Autotools:
```nix
build.extraDrvAttrs = {
  configureFlags = [ "--disable-tests" ];
};
```

## Builder Selection Decision Tree

```
START: What type of project is this?

├─ Has pyproject.toml or setup.py?
│  └─ YES → Use pythonAppBuilder
│     ├─ build-system: setuptools, cython, etc.
│     └─ dependencies: runtime Python packages
│
├─ Has CMakeLists.txt?
│  └─ YES → Use standardBuilder
│     ├─ native: cmake, pkg-config
│     └─ build: libraries (sqlite, gdal, etc.)
│
├─ Has configure or configure.ac?
│  └─ YES → Use standardBuilder (Autotools)
│     ├─ native: autoconf, automake, libtool, pkg-config
│     └─ build: libraries
│
├─ Has Makefile with standard targets?
│  └─ YES → Use standardBuilder
│     ├─ Check for: all, install, clean targets
│     ├─ native: make, pkg-config
│     └─ build: libraries
│
└─ Custom/non-standard build?
   └─ Use plainBuilder
      └─ Define custom configure/build/install phases
```

## Common Dependencies Mapping

### C/C++ Libraries

| If build system looks for | Nix package to add |
|---------------------------|-------------------|
| SQLite, sqlite3, sqlite | `pkgs.sqlite` |
| GDAL, gdal | `pkgs.gdal` |
| PostgreSQL, libpq, pq | `pkgs.postgresql` |
| OpenSSL, ssl | `pkgs.openssl` |
| CURL, curl, libcurl | `pkgs.curl` |
| zlib, z | `pkgs.zlib` |
| Boost, boost | `pkgs.boost` |
| GEOS, geos | `pkgs.geos` |
| PROJ, proj | `pkgs.proj` |
| libxml2, xml2 | `pkgs.libxml2` |
| expat | `pkgs.expat` |

### Python Packages

| If pyproject.toml/requirements has | Nix package to add |
|-----------------------------------|-------------------|
| click | `pkgs.python3Packages.click` |
| requests | `pkgs.python3Packages.requests` |
| numpy | `pkgs.python3Packages.numpy` |
| attrs | `pkgs.python3Packages.attrs` |
| certifi | `pkgs.python3Packages.certifi` |
| setuptools | `pkgs.python3Packages.setuptools` |
| cython | `pkgs.python3Packages.cython` |
| wheel | `pkgs.python3Packages.wheel` |
| pytest | `pkgs.python3Packages.pytest` (test only) |

### Build Tools (always in requirements.native)

- `pkgs.cmake` - CMake build system
- `pkgs.pkg-config` - Finding library dependencies
- `pkgs.meson` - Meson build system
- `pkgs.ninja` - Ninja build tool
- `pkgs.autoconf` - Autotools
- `pkgs.automake` - Autotools
- `pkgs.libtool` - Autotools

## Recommended LLM Workflow

When asked to create a Nix Forge recipe from a git repository, follow this workflow:

### Phase 1: Research & Analysis

**Use the Task/Plan agent to gather information:**

1. Fetch and read repository README.md
2. Identify build system (check for CMakeLists.txt, pyproject.toml, etc.)
3. Check repository structure (is build file in root or subdirectory?)
4. Identify latest stable version from GitHub releases
5. List dependencies from build files and documentation
6. Find main executable/program name
7. Check for tests

**Output from this phase:** Comprehensive summary with all required information.

### Phase 2: Create Initial Recipe

1. Create package directory: `mkdir -p outputs/packages/<name>`
2. Write `recipe.nix` with:
   - Basic metadata (name, version, description, homePage, mainProgram)
   - Appropriate builder (pythonAppBuilder or standardBuilder)
   - `source.hash = ""` (leave empty initially)
   - Initial dependencies based on research
   - Basic test script (at minimum: `--help` and `--version`)

### Phase 3: Add to Git (CRITICAL!)

```bash
git add outputs/packages/<name>/recipe.nix
```

**Without this step, the package will not be recognized by the flake!**

### Phase 4: Iterative Build & Fix

1. **First build attempt:**
   ```bash
   nix build .#<package> -L
   ```

2. **Get correct hash:**
   - Build will fail with hash mismatch
   - Update `source.hash` with the correct value from error message

3. **Rebuild and fix errors iteratively:**
   ```bash
   nix build .#<package> -L
   ```

   Common fixes needed:
   - Add missing dependencies to `requirements.native` or `requirements.build`
   - Set `sourceRoot` if CMakeLists.txt not in root
   - Patch build files to remove external downloads
   - Relax Python version constraints
   - Disable unwanted tests

4. **Repeat until build succeeds**

### Phase 5: Test & Verify

1. Run package tests:
   ```bash
   nix build .#<package>.test -L
   ```

2. Verify tests pass

3. Manual verification (optional):
   ```bash
   ./result/bin/<program> --version
   ./result/bin/<program> --help
   ```

## Annotated Example: Complex Project (geodiff)

This example demonstrates a complex CMake project with subdirectory structure:

```nix
{ config, lib, pkgs, mypkgs, ... }:

{
  name = "geodiff";
  version = "2.0.4";
  description = "Library for handling diffs for geospatial data (GeoPackage and PostGIS).";
  homePage = "https://merginmaps.com";
  mainProgram = "geodiff";

  source = {
    git = "github:MerginMaps/geodiff/2.0.4";
    hash = "sha256-STWoSnBDl3K3F9SeXGvTy8TzZSAP6rZh3ebfMqdT/w0=";
    # Note: Current implementation does not fetch git submodules
  };

  build.standardBuilder = {
    enable = true;
    requirements = {
      # Build tools needed during compilation
      native = [
        pkgs.cmake        # CMake build system
        pkgs.pkg-config   # For finding SQLite
      ];
      # Libraries needed at runtime
      build = [
        pkgs.sqlite       # Required dependency
      ];
    };
  };

  build.extraDrvAttrs = {
    # CMakeLists.txt is in geodiff/geodiff/, not the root directory
    # Repository structure: geodiff/geodiff/CMakeLists.txt
    sourceRoot = "source/geodiff";

    # Optional: Override CMake configuration flags
    # cmakeFlags = [ "-DWITH_POSTGRESQL=OFF" ];

    # Optional: Disable tests if they fail or are slow
    # cmakeFlags = [ "-DENABLE_TESTS=OFF" ];
  };

  test.script = ''
    # Minimum viable tests
    geodiff --help
    geodiff --version
  '';
}
```

**Key points in this example:**

1. **sourceRoot**: Required because CMakeLists.txt is in `geodiff/` subdirectory
2. **cmake and pkg-config**: In `native` because they're build-time tools
3. **sqlite**: In `build` because it's a runtime dependency
4. **Test script**: Simple verification that the binary works

## Annotated Example: Python Project (fiona)

This example demonstrates a Python project with complex dependencies:

```nix
{ config, lib, pkgs, mypkgs, ... }:

{
  name = "fiona";
  version = "1.10.1";
  description = "Python library for reading and writing vector geospatial data files.";
  homePage = "https://fiona.readthedocs.io";
  mainProgram = "fio";

  source = {
    git = "github:Toblerity/Fiona/1.10.1";
    hash = "sha256-5NN6PBh+6HS9OCc9eC2TcBvkcwtI4DV8qXnz4tlaMXc=";
  };

  build.pythonAppBuilder = {
    enable = true;
    requirements = {
      # Python build system packages
      build-system = [
        pkgs.python3Packages.setuptools
        pkgs.python3Packages.cython
        pkgs.gdal  # GDAL also needed at build time for gdal-config
      ];
      # Python runtime dependencies
      dependencies = [
        pkgs.python3Packages.attrs
        pkgs.python3Packages.certifi
        pkgs.python3Packages.click
        pkgs.python3Packages.click-plugins
        pkgs.python3Packages.cligj
        pkgs.python3Packages.cython
        pkgs.gdal  # GDAL needed at runtime
      ];
    };
  };

  build.extraDrvAttrs = {
    # Relax Cython version constraint from ~=3.0.2 to accept any version
    postPatch = ''
      substituteInPlace pyproject.toml \
        --replace-fail "cython~=3.0.2" cython
    '';
  };

  test.script = ''
    # Test both Python import and CLI tool
    python -c "import fiona; print(fiona.__version__)"
    fio --version
  '';
}
```

**Key points in this example:**

1. **pythonAppBuilder**: Used for Python projects
2. **GDAL in both build-system and dependencies**: Needed at build time (for `gdal-config`) and runtime
3. **postPatch**: Relaxes strict version constraint that would otherwise fail
4. **Test script**: Tests both the Python module import and CLI tool

## Quick Reference Checklist

Before creating a recipe, gather this information:

- [ ] Project name (lowercase-with-hyphens)
- [ ] Latest stable version
- [ ] Build system type (Python/CMake/Autotools/Makefile)
- [ ] Main executable name
- [ ] Homepage URL
- [ ] Build dependencies (libraries, tools)
- [ ] Runtime dependencies
- [ ] Repository structure (root or subdirectory?)
- [ ] Git submodules present? (if yes, note limitations)
- [ ] Test commands available?

During recipe creation:

- [ ] Choose correct builder (pythonAppBuilder or standardBuilder)
- [ ] Leave source.hash empty initially
- [ ] Add recipe to git BEFORE building
- [ ] Build to get correct hash
- [ ] Fix errors iteratively
- [ ] Verify tests pass
