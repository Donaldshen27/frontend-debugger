# System Architecture

## Overview

The Frontend Debugger uses a modular architecture combining AI, browser automation, and optional workflow orchestration.

## Core Components

### 1. Claude Code CLI (AI Agent)
- Natural language understanding of testing requirements
- Autonomous navigation and interaction
- Issue detection and categorization
- Context management

### 2. Puppeteer MCP (Browser Control)
- Provides browser automation capabilities to Claude
- Runs in Docker for isolation
- Handles screenshots, clicks, form fills
- Manages viewport sizes for responsive testing

### 3. Testing Scripts (Orchestration)
- Shell scripts that configure and launch Claude
- Handle output parsing and formatting
- Manage test sessions and results

### 4. Optional: n8n + Database (Advanced Features)
- Workflow automation
- Progress persistence
- Historical tracking
- Team collaboration

## Data Flow

```
User → Shell Script → Claude CLI → Puppeteer MCP → Target Website
         ↓                ↓
    Console Output   Test Results
         ↓                ↓
    Terminal Display  File System
```

## Testing Modes

### Quick Test
- Minimal setup
- Fast results (~30 seconds)
- Basic pass/fail indicators

### Real-time Debug
- Live progress tracking
- Colorized severity output
- Detailed logging

### Simple Debug
- Comprehensive testing
- Full documentation
- Timestamped results

## Why This Architecture?

1. **Simplicity**: No complex setup required
2. **Flexibility**: Works with any website
3. **Scalability**: Can test single pages or entire applications
4. **Extensibility**: Easy to add new test types
5. **Portability**: Runs on any system with Docker and Node.js