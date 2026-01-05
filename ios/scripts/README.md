# Scripts Documentation

This directory contains automation scripts for the Still Moment project.

## File Management

**Note**: Xcode 15+ auto-sync is enabled for all source directories. New Swift files are automatically detected by Xcode - no manual scripts required!

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
./scripts/run-tests.sh                           # Run all tests (unit + UI)
./scripts/run-tests.sh --skip-ui-tests           # Run unit tests only
./scripts/run-tests.sh --device "iPhone 17" # Use specific device
```

**Output**:
- `coverage.json` - JSON format report
- `coverage.txt` - Text format report
- `TestResults.xcresult` - Xcode result bundle

**Checks**:
- Fails if coverage < 80%
- Enforced in CI/CD pipeline

## Troubleshooting

### "Permission denied"
```bash
chmod +x scripts/*.sh
```

### New files not showing in Xcode
With auto-sync enabled, files should appear automatically. If not:
1. Verify folder is a folder reference (blue in Xcode, not yellow)
2. Close and reopen Xcode
3. Clean build folder (⌘+Shift+K)
4. Rebuild (⌘+B)

See CLAUDE.md "File Management" section for details.

## Best Practices

1. **File Management**:
   - Create files normally - auto-sync handles Xcode integration
   - No manual scripts needed for file addition

2. **Verify files are added**:
   - Check Xcode Project Navigator
   - Verify file appears in correct folder
   - Check file is in correct target (Still Moment, Tests, etc.)

## Integration with CI/CD

The CI pipeline automatically verifies:
- Build succeeds
- Tests pass
- Coverage meets threshold ≥80%
