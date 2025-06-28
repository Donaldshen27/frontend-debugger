# Workflow Connection Guide

## Main Webhook Flow (Left to Right):
```
[Start Debug Request] 
    ↓
[Create Git Checkpoint]
    ↓
[Launch Claude Monitor]
    ↓
[Respond to Webhook]
```

## Callback Webhook Flow:
```
[Claude Callback] → splits into 3 parallel checks:
    ├→ [Check Event Type] → (if true) → [Update Page Status]
    ├→ [Check If Complete] → (if true) → [Get Session Summary] → [Send Completion Email]
    └→ [Check For Errors] → (if true) → [Send Error Alert]
```

## How to Connect in n8n UI:

1. **Hover over a node** - you'll see small connection points appear
2. **Drag from the output point** (right side) of one node
3. **Drop on the input point** (left side) of the next node

## Connection Details:

### Start Debug Request → Create Git Checkpoint
- From: Main output (right side)
- To: Main input (left side)

### Create Git Checkpoint → Launch Claude Monitor
- From: Main output
- To: Main input

### Launch Claude Monitor → Respond to Webhook
- From: Main output
- To: Main input

### Claude Callback (has 3 outputs):
- Output 1 → Check Event Type
- Output 2 → Check If Complete
- Output 3 → Check For Errors

### IF nodes have 2 outputs:
- True (green) output → connects to action nodes
- False (red) output → usually left unconnected

## For Testing Without Email/Push:
- Disable "Send Completion Email" node
- Disable "Send Error Alert" node
- Leave the rest connected as shown