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

# 🌵 SaguaroScope

<p align="center">
  <img src="saguaroOS.jpg" width="100%" alt="SaguaroScope Screenshot">
</p>

<p align="center">
<b>An interactive comparative genomics platform for exploring the <i>Carnegiea gigantea</i> genome.</b><br>
Genome browser • BLAST annotations • RNA visualization • DuckDB analytics • Hugging Face deployment
</p>

<p align="center">

![Python](https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-black?style=flat-square&logo=flask)
![DuckDB](https://img.shields.io/badge/DuckDB-FFF000?style=flat-square&logo=duckdb&logoColor=black)
![D3.js](https://img.shields.io/badge/D3.js-F9A03C?style=flat-square&logo=d3.js&logoColor=white)
![BLAST](https://img.shields.io/badge/NCBI-BLAST-blue?style=flat-square)
![HTSlib](https://img.shields.io/badge/HTSlib-bgzip%2FFAI-darkgreen?style=flat-square)
![HuggingFace](https://img.shields.io/badge/HuggingFace-Spaces-FFD21E?style=flat-square&logo=huggingface&logoColor=black)
![Genome Browser](https://img.shields.io/badge/Genome-Interactive-success?style=flat-square)

</p>

---

# 🌵 Overview

**SaguaroScope** is a high-performance interactive genome browser built specifically for the **Saguaro cactus (*Carnegiea gigantea*)**.

The original genome assembly was publicly released, but no modern web platform existed for exploring it interactively. SaguaroScope was built from scratch to bridge that gap—combining genome visualization, sequence retrieval, BLAST annotation, comparative genomics, and interactive RNA analysis into a single web application.

Rather than functioning as a static annotation browser, SaguaroScope is designed as an exploratory research environment where genomic structure, functional annotation, and comparative biology can all be investigated in real time.

---

# ✨ Features

## 🧬 Interactive Genome Browser

Navigate entire chromosomes/scaffolds with fluid pan-and-zoom rendering.

- GPU-friendly D3.js visualization
- Multi-level zoom
- Whole-genome minimap
- Smooth navigation across millions of bases
- Instant jumping to coordinates

---

## 🎨 Rich Annotation Tracks

Every genomic feature is rendered as its own visually distinct layer.

Supports:

- Genes
- mRNA
- CDS
- Exons
- Pseudogenes
- miRNA
- snoRNA
- snRNA
- tRNA
- rRNA
- Riboswitches
- Transposable Elements
    - LTR Retrotransposons
    - Non-LTR Retrotransposons
    - TIR Elements
    - Helitrons
    - Unknown repeats

Thousands of annotations remain responsive even while navigating large genomic regions.

---

## 🔍 Dual Search Engine

Search by traditional identifiers:

- Gene IDs
- Transcript IDs
- Scaffold coordinates

or biologically meaningful annotation:

- Protein descriptions
- Species names
- Functional keywords

Examples:

```
Cytochrome P450
```

```
Lophophora williamsii
```

```
CAM
```

```
Heat Shock Protein
```

```
Aquaporin
```

making comparative genomics dramatically easier.

---

## 🧪 Whole-Genome BLAST Annotation

Every predicted gene was automatically annotated using large-scale BLAST analysis.

Each feature exposes:

- Best protein match
- Species
- Percent identity
- Bit score
- E-value
- Description

allowing rapid cross-species exploration without manually running BLAST searches.

---

## 🔗 Relationship Mapping

SaguaroScope automatically identifies genomic relationships including

- Sense overlap
- Antisense overlap
- Nearby neighbors
- Intergenic regions

Relationships appear as interactive arcs directly inside the genome browser and remain clickable for rapid navigation.

---

## 🧾 Interactive Feature Inspector

Clicking any feature immediately opens a detailed inspection panel containing

- Coordinates
- Strand
- Feature type
- Length
- GC%
- Annotation source
- Protein description
- Percent identity
- E-value
- Bit score

allowing detailed biological inspection without leaving the browser.

---

## 🧬 Live Sequence Viewer

Every annotated feature can be converted directly into nucleotide sequence.

Features include

- Automatic reverse complement handling
- Copy sequence
- FASTA download
- Instant retrieval from indexed genomes

without loading the full genome into memory.

---

## ⚡ Built for Large Genomes

Large plant genomes quickly become difficult to browse using conventional web technologies.

SaguaroScope instead uses

- DuckDB analytical queries
- bgzip compressed FASTA
- HTSlib indexing (.fai / .gzi)
- Lazy sequence retrieval

allowing gigabase-scale genomes to remain highly responsive.

---

## 🧪 Interactive RNA Viewer

Beyond genomic browsing, SaguaroScope includes an experimental RNA exploration interface.

Capabilities include

- RNA sequence visualization
- Live mutation
- Structural exploration
- Rapid iteration for transcript analysis

designed for future RNA folding and secondary-structure workflows.

---

# 🚀 Performance

Designed around analytical rather than transactional databases.

Instead of SQLite or PostgreSQL, SaguaroScope leverages **DuckDB** for high-performance genomic analytics.

Advantages include

- columnar execution
- vectorized SQL
- extremely fast aggregation
- low memory overhead
- excellent performance on large annotation datasets

making complex genomic searches feel nearly instantaneous.

---

# 🔬 Future Roadmap

SaguaroScope is intended to evolve beyond a traditional genome browser into a systems biology platform.

Planned additions include

### 🌞 Circadian Gene Expression

Visual overlays for

- daytime genes
- nocturnal genes
- CAM photosynthesis regulation
- stomatal opening pathways
- circadian oscillators

allowing researchers to view genomic organization alongside temporal expression.

---

### 🌿 Metabolic Pathway Integration

Overlay metabolic networks directly onto genomic regions.

Examples

- KEGG pathways
- Reactome pathways
- CAM photosynthesis
- Crassulacean Acid Metabolism enzymes
- Secondary metabolite synthesis
- Alkaloid biosynthesis
- Terpene biosynthesis

---

### 🧠 Comparative Evolution

Future comparative datasets include

- Prickly Pear (*Opuntia*)
- Peyote (*Lophophora*)
- Dragon Fruit (*Selenicereus*)
- Barrel Cactus
- Agave

allowing evolutionary conservation to be explored directly within the browser.

---

### 🧬 Functional Genomics

Future automated annotation layers

- GO terms
- Pfam domains
- InterPro
- Conserved domains
- Ortholog clustering
- Gene family expansion
- Duplication events

---

### 🤖 AI-Assisted Genome Exploration

Long-term plans include integrating LLM-assisted biological reasoning.

Examples

- "Show drought-related genes."

- "Find genes associated with CAM metabolism."

- "Locate all cytochrome P450 enzymes near terpene clusters."

- "Compare this scaffold against alkaloid-producing cactus species."

transforming the browser into an interactive genomic research assistant.

---

# 🛠 Technology Stack

- Python
- Flask
- DuckDB
- D3.js
- NCBI BLAST
- HTSlib
- bgzip / FAI indexing
- HTML5 Canvas
- Hugging Face Spaces

---

# 🎯 Project Goals

SaguaroScope was created to make the **Carnegiea gigantea** genome genuinely explorable.

Rather than treating genome assemblies as static datasets hidden behind flat annotation files, the goal is to provide an environment where researchers, students, and enthusiasts can navigate genomic structure, discover functional relationships, inspect sequence-level detail, and build biological intuition through interactive visualization.

As additional annotations, pathway information, comparative genomes, and expression datasets become available, SaguaroScope is designed to grow into a comprehensive platform for cactus genomics and plant systems biology.

---

*"If the data exists, it should be explorable."*



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
