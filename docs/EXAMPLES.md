# Usage Examples

## Basic Testing

### Test a Simple Website
```bash
./scripts/testing/quick-test.sh https://example.com
```

### Test with Real-time Feedback
```bash
./scripts/testing/frontend-debug-realtime.sh https://myapp.com
```

### Comprehensive Test with Logs
```bash
./scripts/testing/frontend-debug-simple.sh https://complex-app.com
```

## Advanced Usage

### Test Multiple Pages
```bash
# Create a test list
cat > sites.txt << EOF
https://site1.com
https://site2.com
https://site3.com
EOF

# Test all sites
while read -r url; do
  echo "Testing: $url"
  ./scripts/testing/quick-test.sh "$url" > "results-$(basename $url).log"
done < sites.txt
```

### Custom Test Profile
```bash
# Create custom instructions
cat > claude/CLAUDE-mobile.md << 'EOF'
Focus on mobile testing:
- Test at 375px width only
- Check touch interactions
- Verify mobile menu functionality
- Test form inputs on mobile keyboard
EOF

# Run with custom profile
CLAUDE_CONFIG=claude/CLAUDE-mobile.md ./scripts/testing/quick-test.sh https://myapp.com
```

### CI/CD Integration

#### GitHub Actions
```yaml
name: Frontend Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm install -g @anthropic-ai/claude-code
      - run: ./scripts/testing/quick-test.sh ${{ secrets.STAGING_URL }}
```

#### GitLab CI
```yaml
frontend-test:
  image: node:18
  before_script:
    - npm install -g @anthropic-ai/claude-code
  script:
    - ./scripts/testing/quick-test.sh $STAGING_URL
```

### Parse Results Programmatically
```bash
# Extract all errors from a test
./scripts/testing/quick-test.sh https://myapp.com | grep "\[ERROR\]" > errors.log

# Count issues by severity
./scripts/testing/frontend-debug-realtime.sh https://myapp.com | \
  grep -E "\[ISSUE: (CRITICAL|HIGH|MEDIUM|LOW)\]" | \
  awk -F'[\\[\\]]' '{print $2}' | sort | uniq -c
```

### Scheduled Testing
```bash
# Add to crontab for daily testing
0 2 * * * /path/to/frontend-debugger/scripts/testing/quick-test.sh https://myapp.com >> /var/log/frontend-tests.log 2>&1
```

## Real-World Scenarios

### E-commerce Site Testing
```bash
# Test critical purchase flow
./scripts/testing/frontend-debug-realtime.sh https://shop.example.com
# Focus on: Add to cart, checkout, payment forms
```

### SaaS Application Testing
```bash
# Test user dashboard
./scripts/testing/frontend-debug-simple.sh https://app.example.com/dashboard
# Focus on: Data loading, interactive charts, user actions
```

### Marketing Website Testing
```bash
# Quick check all pages
for page in home about products contact; do
  ./scripts/testing/quick-test.sh "https://company.com/$page"
done
```