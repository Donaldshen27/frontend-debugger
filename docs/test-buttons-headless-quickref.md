# test-buttons-headless.sh

**Purpose**: Automated CSS validation for buttons/clickable elements using Claude + Puppeteer MCP

**Usage**: 
```bash
./test-buttons-headless.sh <url>
```

**Input**: Website URL to test

**Output**: 
- `OK` - All buttons have proper CSS states
- `FAIL: <reason>` - CSS issues found (missing hover/focus states, etc.)

**Exit codes**: 
- 0 = PASS
- 1 = FAIL

**Example**:
```bash
./test-buttons-headless.sh https://example.com
# Output: FAIL: Missing hover feedback on main navigation links
```

**Files created**: `results/button-test-[timestamp]/result.txt`