<h1 align="center">⚠️ 400lbhacker ⚠️</h1>

<p align="center">
<em>signal > noise • exploit culture • adversarial journalism</em>
</p>

---

### 🧠 About
I build tools, write code, and break systems — mostly to understand them.

> **Focus:** infosec · OSINT · reverse engineering · automation

---

# Binary Atlas

![screenshot](binaryatlas.jpg)

<p align="center">
  <strong>Interactive Binary Intelligence Platform</strong><br>
  Reverse Engineering • Call Graph Analysis • Vulnerability Discovery • API Correlation • Graph Exploration
</p>

<p align="center">

![Python](https://img.shields.io/badge/Python-3.11+-blue?style=flat-square&logo=python)
![SQLite](https://img.shields.io/badge/SQLite-black?style=flat-square&logo=sqlite&logoColor=cyan)
![Flask](https://img.shields.io/badge/Flask-black?style=flat-square&logo=flask)
![radare2](https://img.shields.io/badge/radare2-black?style=flat-square&logo=gnubash&logoColor=cyan)
![Cutter](https://img.shields.io/badge/Cutter-black?style=flat-square&logo=gnometerminal&logoColor=cyan)
![r2ai](https://img.shields.io/badge/r2ai-black?style=flat-square&logo=openai&logoColor=magenta)
![NetworkX](https://img.shields.io/badge/NetworkX-black?style=flat-square&logo=python&logoColor=yellow)
![Graph Analysis](https://img.shields.io/badge/Graph-Analysis-purple?style=flat-square)
![Reverse Engineering](https://img.shields.io/badge/Reverse-Engineering-red?style=flat-square)
![Cybersecurity](https://img.shields.io/badge/Cyber-Security-green?style=flat-square)

</p>

---

## What is Binary Atlas?

Binary Atlas is an interactive reverse engineering and vulnerability research platform that transforms raw binaries into an explorable intelligence graph.

Instead of manually navigating thousands of functions inside a disassembler, Binary Atlas builds a searchable knowledge graph linking:

- Functions
- Imports
- API usage
- Wrappers & thunks
- Call relationships
- Security-relevant behaviors
- Clusters
- Risk indicators
- Cross references
- Semantic categories

The result is a system that allows researchers to move from:

```text
Binary
   ↓
Disassembly
   ↓
Function Graph
   ↓
Behavior Graph
   ↓
Vulnerability Discovery
```

---

# Core Capabilities

## Interactive Call Graph

Explore thousands of functions in real time.

- Function-to-function call relationships
- Import ownership mapping
- Recursive traversal
- Path finding
- Connected component exploration
- Entry point discovery
- Cluster visualization

```text
QuarantineLocation
      ↓
MoveFileWrapper
      ↓
MoveFileExW
```

Instead of hunting through hundreds of disassembly windows, the relationship is visible immediately.

---

## API Intelligence

Binary Atlas automatically categorizes APIs into behavioral groups.

Examples:

### Filesystem

- CreateFileW
- DeleteFileW
- MoveFileExW
- CopyFileExW
- ReadFile
- WriteFile

### Registry

- RegOpenKeyExW
- RegSetValueExW
- RegDeleteKeyW

### Networking

- WinHttpOpen
- WinHttpConnect
- WinHttpSendRequest

### Threading

- CreateThread
- Sleep
- ExitThread

### Synchronization

- CreateMutexW
- SetEvent
- WaitForSingleObject

### Anti-Analysis

- IsDebuggerPresent
- QueryPerformanceCounter
- GetTickCount
- OutputDebugStringW

---

## Security Signal Detection

Binary Atlas automatically highlights suspicious behaviors.

Examples:

- Anti-debugging
- Security checks
- Fail-fast logic
- Exception-heavy routines
- Bitwise-heavy code
- Guard logic
- Wrapper functions
- Process interaction
- File-system modification chains

---

## Import Ownership Analysis

Automatically discovers:

```text
Function
      ↓
Wrapper
      ↓
Import
```

Examples:

```text
QuarantineLocation
      ↓
MoveFileWrapper
      ↓
MoveFileExW
```

This is extremely useful when analyzing:

- Malware
- EDRs
- AV engines
- Windows services
- Enterprise software

where API calls are often hidden behind dozens of wrappers.

---

## Semantic Clustering

Functions are grouped based on observed behavior.

Example clusters:

```text
Filesystem
Networking
Registry
Crypto
Memory
Threading
Synchronization
Injection
Anti-Analysis
Execution
```

Rather than viewing 1,000+ isolated functions, analysts can navigate the binary at a subsystem level.

---

## Vulnerability Discovery

Binary Atlas assists vulnerability research by automatically identifying:

### Race Conditions

```text
Lock
 ↓
Release
 ↓
Shared Object
 ↓
Reacquire
```

### TOCTOU Candidates

```text
Check
 ↓
Use
```

### Dangerous File Operations

- MoveFileExW
- DeleteFileW
- CreateFileW

without:

- GetFinalPathNameByHandleW
- PathFileExistsW
- Validation routines

### Memory Risks

- HeapFree
- VirtualProtect
- HeapReAlloc
- FreeLibrary

### Privileged Operations

- OpenProcess
- ReadProcessMemory
- CreateProcessAsUserW

---

## XREF Exploration

Instantly pivot between:

```text
Import
 ↓
Wrapper
 ↓
Caller
 ↓
Caller of Caller
```

Find:

- Who calls this?
- What does it call?
- Where does data originate?
- Which subsystem owns it?

---

## Offline SQL Analysis

Every analysis exports to SQLite.

Researchers can perform custom investigations:

```sql
SELECT *
FROM instruction_refs
WHERE target_name='MoveFileExW';
```

```sql
SELECT *
FROM functions
WHERE risk_score > 80;
```

```sql
SELECT *
FROM edges
WHERE type='call';
```

Perfect for:

- Research
- Automation
- Reporting
- CI pipelines
- Large-scale binary comparison

---

## Graph-Based Investigation

Ask questions such as:

### Filesystem

> Show every path leading to MoveFileExW

### Networking

> Show all WinHTTP consumers

### Registry

> Find registry write chains

### Threading

> Show thread creation entry points

### Security

> Find all anti-analysis functions

### Vulnerability Research

> Find file operations lacking validation

---

## Binary Intelligence Dashboard

Binary Atlas provides immediate visibility into:

- Functions
- Imports
- Exports
- Sections
- Clusters
- Graph density
- Security indicators
- Risk score
- API ownership
- Call relationships

without requiring users to manually traverse thousands of nodes.

---

# Designed For

- Reverse Engineers
- Malware Analysts
- Vulnerability Researchers
- Security Engineers
- Detection Engineers
- Incident Responders
- Threat Hunters
- Red Team Operators
- Software Security Researchers

---

# Long-Term Vision

Traditional workflows separate:

```text
Disassembler

Debugger

Decompiler

Database

Notes

Graphs
```

Binary Atlas aims to unify them into a single intelligence platform.

Future directions include:

- Dynamic execution correlation
- Time-travel debugging integration
- Runtime call graph augmentation
- Taint analysis
- Symbolic execution
- Automatic exploit path discovery
- AI-assisted vulnerability triage
- Graph-based patch analysis
- Binary diffing
- Cross-version behavioral comparison

---

# Philosophy

> Stop reading binaries one function at a time.
>
> Start exploring them as systems.

---

## 🧰 Stack

### Languages
![Python](https://img.shields.io/badge/Python-black?style=flat-square&logo=python&logoColor=cyan)
![Ruby](https://img.shields.io/badge/Ruby-black?style=flat-square&logo=ruby&logoColor=red)
![C%23](https://img.shields.io/badge/C%23-black?style=flat-square&logo=csharp&logoColor=purple)
![Delphi](https://img.shields.io/badge/Delphi-black?style=flat-square&logo=embarcadero&logoColor=red)
![Go](https://img.shields.io/badge/Go-black?style=flat-square&logo=go&logoColor=cyan)
![PowerShell](https://img.shields.io/badge/PowerShell-black?style=flat-square&logo=powershell&logoColor=blue)
![JavaScript](https://img.shields.io/badge/JavaScript-black?style=flat-square&logo=javascript&logoColor=yellow)

---

### Offensive / Security Tooling
![Metasploit](https://img.shields.io/badge/Metasploit-black?style=flat-square&logo=metasploit&logoColor=red)
![Burp Suite](https://img.shields.io/badge/Burp%20Suite-black?style=flat-square&logo=portswigger&logoColor=orange)
![BeEF XSS](https://img.shields.io/badge/BeEF--XSS-black?style=flat-square&logo=hackaday&logoColor=red)
![Maltego](https://img.shields.io/badge/Maltego-black?style=flat-square&logo=maltego&logoColor=orange)
![Havoc C2](https://img.shields.io/badge/Havoc%20C2-black?style=flat-square&logo=protonvpn&logoColor=purple)

---

### Reverse Engineering & Binary Analysis
![radare2](https://img.shields.io/badge/radare2-black?style=flat-square&logo=gnubash&logoColor=cyan)
![Cutter](https://img.shields.io/badge/Cutter-black?style=flat-square&logo=gnometerminal&logoColor=cyan)
![r2ai](https://img.shields.io/badge/r2ai-black?style=flat-square&logo=openai&logoColor=magenta)

---

#### 🧬 Featured Project — RAZORWIRE-LIVE

> Live Binary Analysis • Behavioral Signal Scoring • AI-Assisted Forensics  
> radare2 + Local LLM reasoning inside Google Colab.

[![Project Repo](https://img.shields.io/badge/View-RAZORWIRE--LIVE-black?style=flat-square&logo=github&logoColor=white)](https://github.com/400lbhacker/RAZORWIRE-LIVE)
[![Open In Colab](https://img.shields.io/badge/Open%20in-Colab-black?style=flat-square&logo=googlecolab&logoColor=orange)](https://colab.rese)

---

### Research / AI / Tradecraft
![HuggingFace](https://img.shields.io/badge/HuggingFace-black?style=flat-square&logo=huggingface&logoColor=yellow)
![Polyglot%20Models](https://img.shields.io/badge/Polyglot%20Models-black?style=flat-square&logo=tensorflow&logoColor=orange)
![Maldocs](https://img.shields.io/badge/Maldocs-black?style=flat-square&logo=microsoftword&logoColor=blue)

---

### 📡 Contact
- 🔗 LinkedIn
- 🐦 Twitter
- ✉️ Email: josepherickson135@gmail.com

---

<sub>All tooling used for research, education, and defensive analysis.</sub>
