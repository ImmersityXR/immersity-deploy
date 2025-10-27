# Immersity Stress Testing Suite

Comprehensive stress testing and system monitoring tool for the Immersity VR deployment.

## Overview

This unified testing tool provides everything you need to evaluate system performance under load, monitor VM resources (CPU, memory, GPU), and validate the system can handle multiple concurrent users navigating Unity WebGL 3D models.

---

## Folder Structure

```
immersity-deploy/stress-test/
├── run-test.sh                  # Unified testing script (4 modes)
├── README.md                    # This file (complete documentation)
└── stress-test-logs/            # Generated during test runs
    ├── user_*_*.log             # Per-user session logs
    ├── webgl_test_*_*.log       # WebGL loading logs
    ├── relay_test_*_*.log       # Relay server API logs
    ├── system_monitor_*.log     # System resource logs
    ├── system_stats_*.csv       # Resource data (CSV)
    ├── stress_test_report_*.txt # Stress test summary
    └── system_report_*.txt      # System resource summary
```

**Note:** The `stress-test-logs/` directory is created automatically when tests run.

---

## Single Unified Script: `run-test.sh`

One script with four modes to cover all testing needs.

### Modes

#### 1. **automated** - Automated Stress Test
Simulates multiple concurrent users accessing the Unity WebGL application using curl.

**What it tests:**
- WebGL page loading times
- Unity asset file downloads (`.js`, `.wasm`, `.data`)
- Relay server API endpoints
- Concurrent user load handling
- Session capture functionality

**Usage:**
```bash
./run-test.sh automated                           # 5 users for 2 minutes
./run-test.sh automated --users 10                # 10 concurrent users
./run-test.sh automated --users 10 --duration 300 # 10 users for 5 minutes
```

**Best for:** Quick performance testing without real users.

---

#### 2. **monitor** - System Resource Monitor
Monitors VM resources in real-time (passive monitoring).

**What it monitors:**
- CPU usage percentage and load average
- Memory usage (MB and percentage)
- GPU utilization (if NVIDIA GPU available)
- Disk I/O and network traffic
- Docker container resource usage

**Usage:**
```bash
./run-test.sh monitor                        # Monitor for 2 minutes
./run-test.sh monitor --duration 600         # Monitor for 10 minutes
./run-test.sh monitor --interval 10          # Measure every 10 seconds
```

**What it does NOT do:**
- Does not provide URLs to users
- Does not coordinate user testing
- Does not wait for you
- Just monitors - you do whatever you want

**Best for:** 
- Monitoring while users test freely (no coordination needed)
- Baseline system measurements
- General performance observation
- Running alongside your own manual tests

---

#### 3. **manual** - Manual User Testing
Provides URLs for real users and monitors system resources (coordinated testing).

**What it does:**
1. Displays specific URLs for each user (with unique session/client IDs)
2. **Waits for you to press Enter** (users get ready)
3. Starts monitoring when you say "GO"
4. Monitors system resources while users navigate
5. **Waits for you to press Enter again** (users finished)
6. Stops monitoring and generates reports

**Usage:**
```bash
./run-test.sh manual                         # Manual testing with 5 users
./run-test.sh manual --users 10              # Manual testing with 10 users
```

**Best for:** 
- Controlled experiments with exact timing
- Specific user assignments (each gets unique URL)
- Synchronized start/stop (everyone together)
- Precise measurement windows
- Correlating with capture files (known session IDs)

---

#### 4. **complete** - Full Test Suite
Combines automated testing, manual user testing, and system monitoring.

**What it does:**
1. Runs automated stress test
2. Provides URLs for manual user testing
3. Monitors system resources throughout
4. Generates comprehensive combined report

**Usage:**
```bash
./run-test.sh complete                       # Run everything
./run-test.sh complete --users 10            # Complete test with 10 users
```

**Best for:** Comprehensive testing with both automated and manual phases.

---

## Mode Comparison: monitor vs manual

Understanding the difference between these two modes is important:

### Mode 2: monitor (Passive/Freestyle)

**Scenario:**
```bash
# Terminal: Start monitoring
./run-test.sh monitor --duration 1800  # 30 minutes

# Then email your team:
"Hey everyone, test the VR app anytime in the next 30 minutes.
 Use any URL, session ID, client ID you want!"

# Users join whenever, test freely, no coordination
```

**Characteristics:**
- ✅ Just watches system resources
- ✅ No user coordination required
- ✅ Users can test anytime during the monitoring period
- ✅ Good for baseline measurements
- ✅ Can run in background: `nohup ./run-test.sh monitor --duration 3600 &`
- ❌ No specific URLs provided
- ❌ No synchronized start/stop
- ❌ Unknown session IDs

**Use When:**
- You want general system performance data
- Users can test whenever convenient
- No need to coordinate timing
- Measuring idle/baseline performance
- Running other manual tests

---

### Mode 3: manual (Coordinated/Controlled)

**Scenario:**
```bash
# Terminal: Start script
./run-test.sh manual --users 5

# Script displays:
# User 1: https://...?session=manual001&client=1
# User 2: https://...?session=manual002&client=2
# ...
# Press Enter when all users are ready...

# You gather 5 users:
"Everyone open your URL but wait!"

# Press Enter → Monitoring starts
"OK everyone, start navigating NOW!"

# Users test for 5 minutes
"OK everyone, STOP!"

# Press Enter → Monitoring stops
```

**Characteristics:**
- ✅ Provides specific URLs for each user
- ✅ Unique session IDs (manual001, manual002, etc.)
- ✅ Waits for your confirmation to start
- ✅ Waits for your confirmation to stop
- ✅ Synchronized testing window
- ✅ Can correlate with capture files
- ✅ Precise measurement period
- ❌ Requires coordination
- ❌ Users must be available at same time

**Use When:**
- You need exact user count
- You want specific session IDs
- Doing formal performance testing
- Need synchronized start/stop
- Want to analyze capture files later
- Running controlled experiments

---

### Visual Comparison

**Mode 2: monitor**
```
Script:  [Start monitoring] ────────────────────────► [Stop after duration]
You:     Start script ──→ (do whatever you want) ──→ Check results
Users:   (join anytime, use any URLs, no coordination)
```

**Mode 3: manual**
```
Script:  [Wait] → [Start monitoring] → [Wait] → [Stop]
You:     Start → Press Enter (GO) ──→ Press Enter (STOP) → Check results
Users:   Get URLs → Wait for GO → Navigate together → Stop together
```

---

### Real-World Examples

**Example 1: Baseline Measurement (mode 2)**
```bash
# Just see what normal system usage looks like
./run-test.sh monitor --duration 600
# Let it run for 10 minutes with no users
# Check CPU/Memory when system is idle
```

**Example 2: Freestyle Testing (mode 2)**
```bash
# Start monitoring for 1 hour
./run-test.sh monitor --duration 3600

# Email 20 people: "Test anytime in the next hour!"
# People join randomly, test when convenient
# You get general performance data
```

**Example 3: Controlled Load Test (mode 3)**
```bash
# Coordinate with exactly 10 users
./run-test.sh manual --users 10

# Give each person their specific URL
# Everyone starts at the same time
# Everyone stops at the same time
# You get precise data for exactly 10 concurrent users
```

**Example 4: Gradual Load Testing (mode 2)**
```bash
# Start monitoring for 30 minutes
./run-test.sh monitor --duration 1800

# Minute 0-10: Have 3 users test
# Minute 10-20: Add 5 more users (8 total)
# Minute 20-30: Add 7 more users (15 total)
# See how system responds to gradual load increase
```

---

## Quick Start

### Step 1: Make Script Executable (Ubuntu VM)
```bash
cd ~/immersity-deploy/stress-test
chmod +x run-test.sh
```

### Step 2: Choose Your Test Mode

#### Option A: Quick Automated Test
```bash
./run-test.sh automated --users 5
```

#### Option B: Monitor System Resources
```bash
./run-test.sh monitor --duration 300
```

#### Option C: Manual User Testing
```bash
./run-test.sh manual --users 5
```

#### Option D: Complete Test Suite
```bash
./run-test.sh complete
```

### Step 3: View Results
```bash
ls -la stress-test-logs/
cat stress-test-logs/*_report_*.txt
```

---

## Testing Scenarios

### Scenario 1: Quick Load Test (2 minutes)
Test basic system response with minimal load.

```bash
./run-test.sh automated --users 3 --duration 120
```

**Expected results:**
- WebGL page loads in < 3 seconds
- Unity files load in < 2 seconds each
- All API endpoints respond in < 1 second
- CPU usage < 50%

---

### Scenario 2: Standard Load Test (5 minutes)
Test typical production load with moderate users.

```bash
./run-test.sh complete --users 5 --duration 300
```

**Expected results:**
- Consistent response times throughout
- CPU usage < 70%
- Memory usage < 60%
- No failed requests

---

### Scenario 3: Heavy Load Test (10 minutes)
Test maximum capacity with many concurrent users.

```bash
./run-test.sh complete --users 10 --duration 600
```

**Expected results:**
- Response times may increase but stay < 5 seconds
- CPU usage may reach 80-90%
- System remains stable
- All sessions complete successfully

---

### Scenario 4: Manual User Testing
Test with real users navigating the 3D model.

```bash
./run-test.sh manual --users 5
```

**When prompted, have users access these URLs:**
```
User 1: http://somaek.ncsa.illinois.edu/v0.5.7/index.html?session=manual001&client=1
User 2: http://somaek.ncsa.illinois.edu/v0.5.7/index.html?session=manual002&client=2
User 3: http://somaek.ncsa.illinois.edu/v0.5.7/index.html?session=manual003&client=3
User 4: http://somaek.ncsa.illinois.edu/v0.5.7/index.html?session=manual004&client=4
User 5: http://somaek.ncsa.illinois.edu/v0.5.7/index.html?session=manual005&client=5
```

**User Instructions:**
1. Open the assigned URL in a web browser
2. Wait for Unity WebGL to fully load
3. Navigate around the 3D model
4. Interact with available features
5. Try complex movements and interactions
6. Continue for 5-10 minutes
7. Report any issues or lag

---

## Output and Logs

All test results are saved in `./stress-test-logs/` with timestamps.

### Log Files

**Per-test logs:**
- `user_[ID]_[TIMESTAMP].log` - Individual user session logs
- `webgl_test_[ID]_[TIMESTAMP].log` - WebGL loading and interaction logs
- `relay_test_[ID]_[TIMESTAMP].log` - Relay server API test logs

**System monitoring:**
- `system_monitor_[TIMESTAMP].log` - Detailed resource monitoring log
- `system_stats_[TIMESTAMP].csv` - CSV data for graphing and analysis

**Summary reports:**
- `stress_test_report_[TIMESTAMP].txt` - Stress test summary
- `system_report_[TIMESTAMP].txt` - System resource summary
- `combined_report_[TIMESTAMP].txt` - Complete test suite summary

### Sample Report

```
=== Immersity Stress Test Report ===
Timestamp: 20241027_143022
Base URL: http://somaek.ncsa.illinois.edu
Concurrent Users: 5
Test Duration: 120s

=== Test Results ===
WebGL Page Loads: 5 successful
Unity Files Loaded: 20 successful
Relay Health Checks: 5 successful
Start Recording Tests: 5 successful
End Recording Tests: 5 successful

=== Average Response Times ===
WebGL Page Load: 2.1s
Unity Files Load: 1.5s
Relay Health Check: 0.3s
Start Recording: 0.5s
End Recording: 0.4s

=== System Resource Summary ===
Average CPU Usage: 52.3%
Peak CPU Usage: 89.1%
Average Load: 1.8
Peak Load: 3.2
Average Memory Usage: 3.2GB (40%)
Peak Memory Usage: 4.1GB (51%)

=== Recommendations ===
[OK] System handled load well
[OK] Response times within acceptable range
WARNING: Peak CPU usage high - consider scaling for more users
```

---

## Interpreting Results

### Response Times

| Metric | Good | Acceptable | Poor |
|--------|------|------------|------|
| WebGL Page Load | < 2s | 2-5s | > 5s |
| Unity Files | < 2s | 2-4s | > 4s |
| API Endpoints | < 0.5s | 0.5-2s | > 2s |

### System Resources

| Resource | Good | Moderate | High |
|----------|------|----------|------|
| CPU Usage | < 50% | 50-80% | > 80% |
| Memory | < 50% | 50-75% | > 75% |
| Load Average | < CPU cores | 1-2x cores | > 2x cores |

### When to Scale Up

Consider upgrading VM resources if:
- Average CPU usage > 70%
- Peak CPU usage consistently > 90%
- Load average > 2x CPU core count
- Memory usage > 75%
- Response times consistently > 5 seconds
- Any requests fail during moderate load

---

## Troubleshooting

### Issue: "WebGL application is not accessible"
**Solution:**
- Verify services are running: `docker ps`
- Check if build server is running: `curl http://somaek.ncsa.illinois.edu`
- Ensure correct URL in script (update `BASE_URL` variable)

### Issue: "Relay server is not responding"
**Solution:**
- Check relay server: `curl http://somaek.ncsa.illinois.edu/sync/health`
- Verify docker-compose is up: `cd ~/immersity-deploy && docker-compose ps`
- Check logs: `docker logs immersity-relay`

### Issue: High CPU usage
**Possible causes:**
- Too many concurrent users for VM capacity
- Unity WebGL files not being cached properly
- Relay server processing bottleneck

**Solutions:**
- Scale up VM resources (more CPU cores)
- Reduce concurrent user count
- Enable nginx caching for static files

### Issue: Memory exhaustion
**Possible causes:**
- Too many concurrent sessions
- Memory leak in application
- Insufficient VM memory allocation

**Solutions:**
- Monitor memory over time: `free -h`
- Check for memory leaks: Review relay server logs
- Increase VM memory allocation

### Issue: Slow response times
**Possible causes:**
- Network latency
- Disk I/O bottleneck
- Database connection issues

**Solutions:**
- Check network: `ping somaek.ncsa.illinois.edu`
- Monitor disk I/O: `iostat -x 1`
- Review relay server logs for database queries

---

## Advanced Configuration

### Custom Test Duration
```bash
# Test for 30 minutes
./stress-test.sh --users 5 --duration 1800
```

### Custom Monitoring Interval
```bash
# Sample every 15 seconds
./system-monitor.sh --interval 15 --duration 600
```

### Test Different URL
```bash
# Test localhost instead
./stress-test.sh --url http://localhost:80
```

### Background Monitoring
```bash
# Run monitoring in background
nohup ./system-monitor.sh --duration 3600 > monitor.out 2>&1 &
```

---

## Requirements

### System Requirements
- Bash shell (Linux/Ubuntu)
- `curl` command-line tool
- `docker` and `docker-compose`
- `top`, `free`, `iostat` utilities

### Optional Requirements
- NVIDIA GPU with `nvidia-smi` (for GPU monitoring)
- `bc` calculator (for advanced calculations)

### Install Dependencies (Ubuntu)
```bash
sudo apt update
sudo apt install -y curl sysstat bc
```

---

## Best Practices

### 1. Run During Off-Peak Hours
- Schedule tests when production traffic is low
- Avoid testing during critical business hours

### 2. Start Small, Scale Up
- Begin with 3-5 users
- Gradually increase to 10, 20, 50 users
- Document performance at each level

### 3. Monitor Throughout
- Always run system monitoring alongside stress tests
- Watch for resource exhaustion warnings
- Stop tests if system becomes unstable

### 4. Document Baselines
- Record initial performance metrics
- Compare results after configuration changes
- Track performance over time

### 5. Verify Captures
- After each test, verify capture files were created
- Check capture files contain data (not empty arrays)
- Review capture file sizes and content

---

## Integration with CI/CD

You can integrate these tests into automated pipelines:

```bash
#!/bin/bash
# ci-stress-test.sh

# Run stress test
./stress-test.sh --users 5 --duration 120

# Parse results
FAILURES=$(grep -c "failed" stress-test-logs/*.log || echo "0")

if [ "$FAILURES" -gt 0 ]; then
    echo "Stress test failed with $FAILURES failures"
    exit 1
else
    echo "Stress test passed"
    exit 0
fi
```

---

## Quick Reference

### Run Automated Test
```bash
./run-test.sh automated
```

### Run with 10 Users
```bash
./run-test.sh automated --users 10
```

### Monitor Resources for 10 Minutes
```bash
./run-test.sh monitor --duration 600
```

### Manual User Testing
```bash
./run-test.sh manual --users 5
```

### Complete Test Suite
```bash
./run-test.sh complete
```

### View Results
```bash
ls -la stress-test-logs/
cat stress-test-logs/*_report_*.txt
```

### Show Help
```bash
./run-test.sh --help
```

---

## Usage Flow

```
1. cd ~/immersity-deploy/stress-test
   │
2. chmod +x run-test.sh (first time only)
   │
3. Choose a mode:
   │
   ├─── Automated test:
   │    ./run-test.sh automated --users 5
   │
   ├─── System monitoring:
   │    ./run-test.sh monitor --duration 300
   │
   ├─── Manual user test:
   │    ./run-test.sh manual --users 5
   │    (Script provides URLs for real users)
   │
   └─── Complete suite:
        ./run-test.sh complete --users 5
        │
        ├─── Phase 1: Automated stress test
        ├─── Phase 2: Manual user testing
        └─── Phase 3: Generate reports
             │
             └─── Check stress-test-logs/ for results
```

---

## Contributing

When adding new tests:
1. Follow the existing script structure
2. Use consistent logging format
3. Include help text (`--help` flag)
4. Update this README with new features
5. Test on actual VM before committing

---

## Support

For issues or questions:
- Check logs in `./stress-test-logs/`
- Review VM resources: `htop` or `top`
- Check Docker logs: `docker-compose logs`
- Review main documentation: `../README.md`

---

**Note:** These stress tests simulate HTTPS requests but cannot fully replicate real Unity WebGL 3D navigation. For comprehensive testing, always include manual user testing with real browsers and user interactions.

---

© 2024 Immersity XR

