# Button & CSS Testing System

A comprehensive testing system for validating button interactions and CSS states using Claude Code CLI with Puppeteer MCP.

## Overview

This system automatically tests all buttons and interactive elements on a website, validating their CSS properties across different states (default, hover, active, focus, disabled) and viewport sizes. It generates real-time progress updates and a detailed markdown report.

## Features

- **Automatic Button Discovery**: Finds all clickable elements including `<button>`, `<a>`, `<input>`, and elements with `role="button"`
- **CSS State Validation**: Tests hover, active, focus, and disabled states
- **Responsive Testing**: Validates buttons at multiple viewport sizes
- **Real-time Monitoring**: Live progress updates and statistics
- **Detailed Reporting**: Comprehensive markdown report with screenshots
- **Issue Categorization**: Critical, High, Medium, and Low severity issues

## Usage

### Basic Usage

```bash
cd frontend-debugger/scripts/testing
./test-buttons-css.sh https://example.com
```

### Advanced Options

```bash
# Custom output directory
./test-buttons-css.sh https://example.com --output-dir /path/to/results

# Custom viewport sizes
./test-buttons-css.sh https://example.com --viewport 320,768,1440

# Disable real-time monitoring
./test-buttons-css.sh https://example.com --no-monitor
```

### Live Dashboard

In a separate terminal, watch the testing progress in real-time:

```bash
cd frontend-debugger/scripts/utilities
./show-live-log.sh /path/to/output/directory
```

## Output Structure

```
results/
└── test-example-com-20240130-143022/
    ├── tested-buttons-and-pages.md    # Main test report
    ├── prompt.md                      # Claude prompt used
    ├── logs/
    │   ├── claude-output.log         # Full Claude output
    │   └── monitor.log               # Monitor script logs
    └── screenshots/
        ├── button-default-1.png      # Button screenshots
        ├── button-hover-1.png
        └── ...
```

## Report Sections

The generated report includes:

1. **Summary**: Total buttons found, issues discovered, and statistics
2. **Buttons Tested**: Detailed information for each button including:
   - Selector path
   - States tested
   - CSS properties captured
   - Screenshots taken
   - Issues found
3. **All Issues**: Categorized list of all CSS issues
4. **CSS Coverage**: Properties and viewports tested
5. **Recommendations**: Prioritized fix suggestions

## Issue Severity Levels

- **🔴 CRITICAL**: No visual feedback on interaction, broken functionality
- **🟠 HIGH**: Poor contrast, missing focus indicators, accessibility failures
- **🟡 MEDIUM**: Inconsistent styling, jarring transitions
- **🔵 LOW**: Minor visual glitches

## Testing Markers

The system uses these markers to track progress:

- `[PAGE_LOADED]`: Page successfully loaded
- `[BUTTON_FOUND]`: Button discovered
- `[CSS_STATE]`: Testing specific state
- `[CSS_PROPERTY]`: Capturing CSS value
- `[CSS_ISSUE]`: Issue detected
- `[SCREENSHOT]`: Screenshot saved
- `[TEST_COMPLETE]`: Button testing finished
- `[ALL_TESTS_COMPLETE]`: All testing done

## Prerequisites

- Claude Code CLI installed and configured
- Puppeteer MCP server configured
- Node.js for the monitoring script
- Basic Unix utilities (bash, grep, sed)

## Troubleshooting

### Claude not finding buttons
- Ensure the page is fully loaded
- Check if buttons are dynamically loaded
- Verify selectors are correct

### Monitor script not updating
- Check file permissions
- Ensure Node.js is installed
- Verify output directory path

### Screenshots not saving
- Check disk space
- Verify output directory permissions
- Ensure Puppeteer has proper access

## Example Test Command

Test a website with custom settings:

```bash
./test-buttons-css.sh https://mysite.com \
  --output-dir ~/Desktop/button-tests \
  --viewport 375,768,1920
```

Then in another terminal:

```bash
./show-live-log.sh ~/Desktop/button-tests
```

## Integration with CI/CD

The test script returns appropriate exit codes:
- 0: All tests passed
- 1: Tests failed or errors occurred

This makes it suitable for integration into CI/CD pipelines.