# Scripts Documentation

This directory contains automation scripts for the MediTimer project.

## File Synchronization

### `sync-xcode-files.sh`
**Purpose**: Automatically adds new Swift files to the Xcode project.

**Usage**:
```bash
./scripts/sync-xcode-files.sh
```

**When to use**:
- After creating new `.swift` files in `MediTimer/`, `MediTimerTests/`, or `MediTimerUITests/`
- After pulling changes that include new files
- When Xcode doesn't recognize newly added files

**What it does**:
1. Scans for new Swift files not yet in the Xcode project
2. Calls `auto-add-files.rb` to add them to appropriate targets
3. Updates `project.pbxproj` automatically

### `auto-add-files.rb`
**Purpose**: Ruby script that modifies the Xcode project file using the xcodeproj gem.

**Usage**:
```bash
ruby scripts/auto-add-files.rb
```

**Requirements**:
- Ruby (pre-installed on macOS)
- xcodeproj gem: `gem install xcodeproj`

**What it does**:
- Recursively scans source directories
- Adds `.swift` files to appropriate targets (MediTimer, MediTimerTests, MediTimerUITests)
- Creates group structure matching the file system
- Skips files that already exist in the project

## Development Environment

### `setup-hooks.sh`
**Purpose**: One-time setup script for development tools and Git hooks.

**Usage**:
```bash
./scripts/setup-hooks.sh
```

**Installs**:
- SwiftLint (code quality)
- SwiftFormat (code formatting)
- pre-commit (Git hooks)
- detect-secrets (secret scanning)

**Run once**: After cloning the repository.

## Testing & Quality

### `run-tests.sh`
**Purpose**: Runs tests and generates code coverage report.

**Usage**:
```bash
./scripts/run-tests.sh                          # Run all tests (unit + UI)
./scripts/run-tests.sh --skip-ui-tests          # Run unit tests only
./scripts/run-tests.sh --device "iPhone 16 Pro" # Use specific device
```

**Output**:
- `coverage.json` - JSON format report
- `coverage.txt` - Text format report
- `TestResults.xcresult` - Xcode result bundle

**Checks**:
- Fails if coverage < 80%
- Enforced in CI/CD pipeline

### `test-report.sh`
**Purpose**: Display coverage report from last test run (without re-running tests).

**Usage**:
```bash
./scripts/test-report.sh
```

**Output**: Terminal-based coverage report with timestamp and threshold check

## Git Hooks

### `.git/hooks/post-checkout`
**Purpose**: Automatically syncs files after git checkout/pull.

**Trigger**: Runs automatically after:
- `git checkout <branch>`
- `git pull`
- `git merge`

**What it does**:
- Calls `sync-xcode-files.sh`
- Ensures Xcode project stays in sync with file system

## Utilities (Legacy)

These scripts are kept for reference but may not be actively used:

- `add_files_to_xcode.rb` - Original file addition script (basis for `auto-add-files.rb`)
- `disable_file_sync.rb` - Disables file synchronization
- `enable_background_audio.rb` - Configures background audio capability
- `fix_duplicate_files.rb` - Removes duplicate file references
- `fix_file_paths.rb` - Fixes incorrect file paths in project
- `make-public.sh` - Adds public modifiers (was for SPM experiment)

## Troubleshooting

### "xcodeproj gem not installed"
```bash
gem install xcodeproj
```

### "Permission denied"
```bash
chmod +x scripts/*.sh
```

### New files still not showing in Xcode
1. Run `./scripts/sync-xcode-files.sh`
2. Close and reopen Xcode
3. Clean build folder (⌘+Shift+K)
4. Rebuild (⌘+B)

### Script reports files added but Xcode doesn't show them
- The script modifies `project.pbxproj`
- Xcode must reload the project file
- Close and reopen Xcode to see changes

## Best Practices

1. **Always sync after adding files**:
   ```bash
   # Create new file
   touch MediTimer/Domain/Models/NewModel.swift

   # Sync with Xcode
   ./scripts/sync-xcode-files.sh
   ```

2. **Verify files are added**:
   - Check Xcode Project Navigator
   - Verify file appears in correct group
   - Check file is in correct target (MediTimer, Tests, etc.)

3. **Commit project.pbxproj changes**:
   - After running sync script, `project.pbxproj` will be modified
   - Commit these changes with your new files

## Integration with CI/CD

The CI pipeline automatically verifies:
- All Swift files are in the Xcode project
- Build succeeds
- Tests pass
- Coverage meets threshold

If the pipeline fails due to missing files, run `sync-xcode-files.sh` locally and commit the changes.
