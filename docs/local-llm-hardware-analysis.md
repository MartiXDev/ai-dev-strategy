# Local LLM & Hardware Analysis for Coding Tasks

> **Date:** February 16, 2026
> **Goal:** Evaluate local LLMs and hardware options for orchestrated coding task execution using Ollama, Copilot CLI, and Codex CLI.

## Table of Contents

- [Current Hardware](#current-hardware)
- [Local LLM Recommendations for Current Hardware](#local-llm-recommendations-for-current-hardware)
- [New Hardware Options](#new-hardware-options)
- [Hardware Comparison](#hardware-comparison)
- [LLM Inference Performance Comparison](#llm-inference-performance-comparison)
- [HP Z2 Mini G1a — Pros and Cons](#hp-z2-mini-g1a--pros-and-cons)
- [Lenovo ThinkStation PGX — Pros and Cons](#lenovo-thinkstation-pgx--pros-and-cons)
- [Mac Mini M4 Pro — Pros and Cons](#mac-mini-m4-pro--pros-and-cons)
- [Custom RTX 5090 Build — Pros and Cons](#custom-rtx-5090-build--pros-and-cons)
- [Using the ThinkStation PGX / DGX OS](#using-the-thinkstation-pgx--dgx-os)
- [Models Unlocked by New Hardware](#models-unlocked-by-new-hardware)
- [Decision Framework](#decision-framework)
- [Bottom-Line Recommendation](#bottom-line-recommendation)

---

## Current Hardware

**Lenovo P52**

| Component | Spec | Impact on LLM Inference |
| --------- | ---- | ----------------------- |
| CPU | Intel Core i7-8750H @ 2.20 GHz (6C/12T) | Modest speed for CPU inference; ~5-15 tok/s on 7-8B models |
| RAM | 32 GB DDR4 | CPU inference up to ~18 GB model files (leaving room for OS/apps) |
| GPU | Intel UHD 630 + NVIDIA Quadro P1000 (4 GB VRAM) | Can fully load models up to ~3B; 7-8B partially offload to CPU |
| SSD | 512 GB | Models are 1-20 GB each; watch disk space with multiple models |
| OS | Windows 11 Pro | Full compatibility with all dev tools |

---

## Local LLM Recommendations for Current Hardware

### Tier 1 — Best Balance (7-8B, ~5 GB, primary recommendation)

| Model | Size | Why |
| ----- | ---- | --- |
| **`qwen2.5-coder:7b`** | 4.7 GB | **Top pick.** Purpose-built code model. #1 open-source coder at 7B on EvalPlus (78.7), 40+ languages, strong code repair (Aider). 11M+ pulls on Ollama. |
| **`rnj-1:8b`** | 5.1 GB | New (Essential AI). 20.8% SWE-bench Verified (bash-only) — beats models 4x larger. Strong agentic + tool calling. Best for multi-file edits. |
| **`qwen3:8b`** | 5.2 GB | Best general-purpose 8B. Thinking/non-thinking modes. Rivals Qwen2.5-72B on many benchmarks. Good for mixed code + reasoning tasks. |

These partially use GPU (4 GB VRAM) + CPU RAM. Expect **~8-15 tok/s** — viable for small focused tasks.

**Install:** `ollama pull qwen2.5-coder:7b`

### Tier 2 — Speed-Optimized (1.5-3B, fits entirely in GPU)

Best for **parallel execution** where you want max throughput over multiple instances:

| Model | Size | Why |
| ----- | ---- | --- |
| **`qwen2.5-coder:3b`** | 1.9 GB | Best coding 3B model. Fits entirely in GPU VRAM → **~25-40 tok/s**. Good enough for boilerplate, simple edits, test generation. |
| **`qwen2.5-coder:1.5b`** | 986 MB | Ultra-fast. Use for trivial tasks (rename, add imports, simple refactors). |
| **`granite4:3b`** | 2.1 GB | IBM's enterprise model. Good tool-calling, 128K context. Apache 2.0. |

Sweet spot for parallelism — could run 2-3 instances simultaneously on GPU.

### Tier 3 — Maximum Quality (14B, CPU-only, slower)

For the hardest tasks where quality > speed:

| Model | Size | Why |
| ----- | ---- | --- |
| **`qwen2.5-coder:14b`** | 9.0 GB | Significant quality jump over 7B. Worth it for complex refactors, algorithm implementations. **~3-7 tok/s** on CPU. |
| **`deepcoder:14b`** | 9.0 GB | Reasoning-focused coder. Matches o3-mini (Low) on LiveCodeBench (60.6%). Best for algorithmic/logic-heavy tasks. |

Use selectively for harder tasks, not for batch parallelism.

### Tier 4 — MoE Wild Card (large footprint, lighter inference)

| Model | Size | Active Params | Notes |
| ----- | ---- | ------------- | ----- |
| **`qwen3:30b`** | ~19 GB | 3B per token | Outperforms QwQ-32B. Fits in RAM but tight (~13 GB free for OS). May swap. |
| **`glm-4.7-flash`** | 19 GB | 3B per token | 30B-A3B MoE. 59.2% SWE-bench Verified. Requires Ollama 0.14.3+. Same RAM caveat. |

**Warning:** 19 GB in RAM → ~13 GB left. Single instance only, ~3-5 tok/s.

### Practical Task Routing Strategy (Current Hardware)

```
Cloud LLMs (Claude/GPT) via GitHub SpecKit
        ↓ Generate small tasks
        ↓
┌───────────────────────────────────┐
│ Task complexity router (script)   │
├───────────────────────────────────┤
│ Trivial tasks → qwen2.5-coder:3b │  (parallel, fast)
│ Normal tasks  → qwen2.5-coder:7b │  (primary workhorse)
│ Hard tasks    → qwen2.5-coder:14b│  (sequential, quality)
└───────────────────────────────────┘
```

### Quick Start

```powershell
# Install Ollama, then pull the recommended trio:
ollama pull qwen2.5-coder:7b    # Primary workhorse
ollama pull qwen2.5-coder:3b    # Fast parallel tasks
ollama pull qwen2.5-coder:14b   # Quality fallback
# Total disk: ~15.6 GB
```

---

## New Hardware Options

### Option A: HP Z2 Mini G1a

- **CPU:** AMD Ryzen AI Max+ PRO 395, 16C/32T, 5.1 GHz (Zen 5, x86)
- **GPU:** AMD Radeon RX 8060S (integrated, ~RTX 4070 laptop class, 16 GB shared VRAM)
- **RAM:** 128 GB LPDDR5X-8533 ECC, unified (shared CPU+GPU, NOT upgradeable)
- **SSD:** 2 TB NVMe (2x M.2 2280 slots)
- **NPU:** 50 TOPS
- **OS:** Windows 11 Pro
- **Power:** 300W PSU, max draw ~245W
- **Form Factor:** Mini PC (200x168x85mm, 2.6 kg)
- **Price:** ~$4,500-5,000 (128 GB config)
- **Source:** [Notebookcheck review](https://www.notebookcheck.net/HP-Z2-Mini-G1a-with-AMD-Strix-Halo-review-Compact-workstation-with-Ryzen-AI-Max-and-Radeon-RX-8060S.1069652.0.html), HP Store

### Option B: Lenovo ThinkStation PGX (DGX Spark)

- **CPU:** NVIDIA GB10 — 20 ARM cores (10x Cortex-X925 + 10x Cortex-A725)
- **GPU:** NVIDIA Blackwell GPU with 5th-gen Tensor Cores
- **AI Performance:** Up to 1 petaFLOP FP4
- **RAM:** 128 GB LPDDR5X, unified coherent (shared CPU+GPU, NOT upgradeable)
- **SSD:** Up to 4 TB NVMe
- **OS:** NVIDIA DGX OS (Ubuntu-based Linux, **NO Windows**)
- **Architecture:** **ARM** (not x86)
- **Networking:** ConnectX (can link 2 units for 405B models)
- **Form Factor:** Mini PC (compact desktop)
- **Price:** ~$3,000-3,500 (DGX Spark base)
- **Source:** [NVIDIA DGX Spark](https://www.nvidia.com/en-us/products/workstations/dgx-spark/), [Lenovo announcement](https://news.lenovo.com/all-new-lenovo-thinkstation-pgx-big-ai-innovation-in-a-small-form-factor/)

### Option C: Mac Mini M4 Pro 48 GB — Best Price/Performance

- **CPU:** Apple M4 Pro, 12C (8P+4E), up to 4.5 GHz (ARM)
- **GPU:** Apple M4 Pro 16-core GPU (integrated, unified memory)
- **RAM:** 48 GB LPDDR5X-8533, unified (shared CPU+GPU, NOT upgradeable)
- **Memory Bandwidth:** ~273 GB/s
- **SSD:** 512 GB–2 TB NVMe (proprietary Apple module)
- **NPU:** 16-core Neural Engine
- **OS:** macOS Sequoia (NO Windows natively)
- **Architecture:** **ARM** (Apple Silicon)
- **Power:** ~70W max load, ~2.5W idle
- **Noise:** Near-silent under average load (25 dB), audible under full load (46 dB)
- **Form Factor:** Ultra-compact (127x127x50mm, 0.73 kg)
- **Price:** ~$1,599 (48 GB / 512 GB) · ~$1,799 (48 GB / 1 TB)
- **Source:** [Apple Mac Mini](https://www.apple.com/mac-mini/specs/), [Notebookcheck review](https://www.notebookcheck.net/Apple-Mac-Mini-M4-Pro-review-The-compact-and-frugal-desktop-PC-with-top-performance-and-expensive-upgrades.946883.0.html)

### Option D: Custom PC with NVIDIA RTX 5090 — Best Performance

- **CPU:** AMD Ryzen 9 9900X or Intel Core i7-14700K (16-24 cores, x86)
- **GPU:** NVIDIA GeForce RTX 5090 — 32 GB GDDR7, Blackwell architecture
- **GPU Memory Bandwidth:** 1,792 GB/s
- **AI Performance:** 3,352 TOPS (FP4 via 5th-gen Tensor Cores)
- **RAM:** 64 GB DDR5-6000 (system RAM for CPU offload of larger models)
- **SSD:** 2 TB NVMe Gen4/Gen5
- **OS:** Windows 11 Pro (or Linux)
- **Architecture:** x86-64
- **Power:** ~600-700W total system (850W+ PSU recommended)
- **Noise:** Moderate–loud under GPU load (depends on cooler)
- **Form Factor:** ATX mid-tower desktop
- **Price:** ~$4,000–5,000 total build (GPU ~$2,000 + rest ~$2,000–3,000)
- **Source:** [NVIDIA RTX 5090](https://www.nvidia.com/en-us/geforce/graphics-cards/50-series/rtx-5090/)

> **Alternative for best performance with larger models:** Mac Studio M3 Ultra 192 GB (~$4,999–5,999) — 192 GB unified at 892 GB/s, runs 100B+ models, silent, ARM/macOS. Trades per-token speed for much larger model capacity.

---

## Hardware Comparison

| Feature | **HP Z2 Mini G1a** | **ThinkStation PGX** | **Mac Mini M4 Pro 48GB** | **Custom RTX 5090 Build** | Current **P52** |
| - | - | - | - | - | - |
| **CPU** | Ryzen AI Max+ PRO 395, 16C/32T (x86) | GB10: 20 ARM cores | M4 Pro 12C (8P+4E) (ARM) | Ryzen 9 9900X or i7-14700K (x86) | i7-8750H, 6C/12T |
| **GPU** | Radeon RX 8060S (~RTX 4070 laptop) | Blackwell + 5th-gen Tensor Cores | M4 Pro 16-core (integrated) | **RTX 5090 32 GB GDDR7** | Quadro P1000 (4 GB) |
| **AI Perf** | ~50 TOPS NPU + iGPU | **1 petaFLOP FP4** | 16-core Neural Engine | **3,352 TOPS FP4** | Negligible |
| **RAM** | 128 GB LPDDR5X ECC, unified | 128 GB LPDDR5X, unified | **48 GB LPDDR5X, unified** | 64 GB DDR5 (separate) | 32 GB DDR4 |
| **Mem BW** | ~273 GB/s | ~273 GB/s | **~273 GB/s** | **1,792 GB/s (VRAM)** | ~38 GB/s |
| **SSD** | 2 TB NVMe | Up to 4 TB NVMe | 512 GB–2 TB | 2 TB NVMe | 512 GB |
| **OS** | **Windows 11 Pro** | DGX OS (Linux, ARM) | **macOS** | **Windows 11 Pro** | Windows 11 Pro |
| **Arch** | x86-64 | ARM | ARM | x86-64 | x86-64 |
| **Price** | **~$4,500-5,000** | **~$3,000-3,500** | **~$1,599-1,799** | **~$4,000-5,000** | Already owned |
| **Max LLM** | ~70B comfortably | Up to 200B | **~32B comfortably** | **~18B in VRAM; ~32B w/ offload** | ~8B (slow) |
| **Form Factor** | Mini PC (2.6 kg) | Mini PC | **Ultra-compact (0.73 kg)** | ATX mid-tower | Laptop |
| **Noise** | Very loud (70 dB!) | Quiet | **Near-silent (25 dB)** | Moderate–loud | Laptop fan |
| **Max Power** | ~245W | Efficient | **~70W** | **~600-700W** | Laptop adapter |
| **Upgradeable** | RAM: no; SSD: 2 slots | RAM: no; SSD: yes | RAM: no; SSD: proprietary | **RAM: yes; GPU: yes; SSD: yes** | RAM: yes |

---

## LLM Inference Performance Comparison

| Model | **Current P52** | **Mac Mini M4 Pro 48GB** | **HP Z2 Mini G1a** | **Custom RTX 5090** | **ThinkStation PGX** |
| - | - | - | - | - | - |
| `qwen2.5-coder:7b` (4.7 GB) | ~8-15 tok/s | **~40-55 tok/s** | ~40-60 tok/s | **~150-200 tok/s** | ~80-120 tok/s |
| `qwen2.5-coder:14b` (9 GB) | ~3-7 tok/s | **~20-30 tok/s** | ~25-40 tok/s | **~80-120 tok/s** | ~50-80 tok/s |
| `qwen2.5-coder:32b` (20 GB) | Won't run | **~10-16 tok/s** | ~15-25 tok/s | **~50-70 tok/s** ⁱ | ~30-50 tok/s |
| `qwen3:30b` MoE (19 GB) | Barely fits | **~12-18 tok/s** | ~20-35 tok/s | **~60-80 tok/s** | ~40-60 tok/s |
| `devstral-small-2:24b` (15 GB) | Won't run | **~15-22 tok/s** | ~20-30 tok/s | **~70-100 tok/s** | ~40-60 tok/s |
| 70B models (~40 GB Q4) | Won't run | Won't fit | ~8-15 tok/s | ~15-25 tok/s ² | ~20-35 tok/s |
| 200B models | Impossible | Impossible | Won't fit | Won't fit | ~5-10 tok/s |
| **Parallel instances (7B)** | 1 (slow) | **2-3 comfortably** | 2-3 comfortably | **4-6+ comfortably** | 4-6 comfortably |

*ⁱ RTX 5090 can fit 32B Q4 models entirely in 32 GB VRAM → full bandwidth (1,792 GB/s) applies.*
*² 70B on RTX 5090 requires CPU offload — speed drops significantly as most data flows through slower DDR5 (~90 GB/s).*

*Note: tok/s estimates based on memory bandwidth as the bottleneck. PGX benefits from Tensor Core acceleration with FP4/FP8 quantization.*

---

## HP Z2 Mini G1a — Pros and Cons

### Pros

- **Runs Windows 11 Pro** — existing workflow works unchanged
- Full x86 compatibility — .NET, VS Code, all tools native
- AMD ROCm + Ollama works, improving rapidly
- Can be used as primary dev machine (replaces P52)
- 128 GB unified memory handles 70B models comfortably
- Thunderbolt 4, Wi-Fi 7, ECC RAM
- ISV-certified workstation (professional support)
- 36-month warranty

### Cons

- Very loud under load (up to 70 dB, use Quiet mode)
- RAM not upgradeable
- ROCm less mature than CUDA for AI inference
- More expensive (~$4,500-5,000 for 128 GB config)
- No discrete GPU — iGPU shares memory pool
- AMD GPU sometimes has Ollama compatibility quirks
- No HDMI port

---

## Lenovo ThinkStation PGX — Pros and Cons

### Pros

- **1 petaFLOP FP4** — dramatically faster AI inference
- NVIDIA CUDA ecosystem — best AI software support
- Purpose-built for AI — optimized drivers, frameworks
- Cheaper (~$3,000)
- Can run 200B parameter models
- NVIDIA NIM, NeMo, full AI stack pre-installed
- Link two units for 405B models
- Quiet and power-efficient

### Cons

- **Linux only (DGX OS)** — NO Windows support
- **ARM architecture** — .NET/VS Code work but some tools may not
- Cannot be your primary dev machine (different OS/arch)
- You'd need TWO machines (PGX for AI + your laptop for dev)
- DGX OS is specialized — not a general-purpose desktop
- New platform — less community support for Ollama-style workflows
- ARM-based — won't build/test your .NET C# code natively with same binaries

---

## Mac Mini M4 Pro — Pros and Cons

### Pros

- **Unbeatable price/performance for LLM inference** — $1,599 for 48 GB unified memory at 273 GB/s
- 48 GB lets you comfortably run 32B coding models (qwen2.5-coder:32b = 20 GB Q4)
- Near-silent under average load (25 dB) — you won't hear it
- Ultra-low power consumption (~2.5W idle, ~70W max) — negligible electricity cost
- Ultra-compact (127x127x50mm, 0.73 kg) — fits anywhere
- Ollama on Apple Silicon is mature, fast, and well-optimized
- Thunderbolt 5, Wi-Fi 6E, built-in speaker
- Can serve as dedicated headless Ollama server on your network
- Can also be used as a second dev machine (VS Code, .NET SDK available for ARM64 macOS)
- Excellent build quality, 1-year Apple warranty

### Cons

- **macOS only** — not Windows; if used as primary dev machine, some tools may differ
- **ARM architecture** — .NET runs well on ARM64 macOS, but binary compatibility differs from x86 Windows
- 48 GB limits you to ~32B models max; no 70B support
- RAM not upgradeable — must choose at purchase
- SSD uses proprietary Apple module — expensive upgrades ($200 for 1 TB, $600 for 2 TB)
- No discrete GPU — inference relies on unified memory bandwidth (good, but not CUDA-class)
- If you already have the HP Z2 Mini for dev, this becomes an extra device

---

## Custom RTX 5090 Build — Pros and Cons

### Pros

- **Fastest per-token inference for models up to 32B** — 1,792 GB/s VRAM bandwidth is 6.5x the Mac Mini
- 32 GB GDDR7 VRAM fits qwen2.5-coder:32b entirely in GPU memory
- NVIDIA CUDA ecosystem — best software support for AI/ML
- Windows 11 Pro native — full .NET, VS Code, all dev tools without compromise
- **Fully upgradeable** — RAM, GPU, SSD, even second GPU slot for future expansion
- Can run multiple parallel Ollama instances at high speed
- 3,352 TOPS AI compute — enables FP4/FP8 quantized inference with Tensor Cores
- Standard desktop form factor — easy to build, maintain, and repair
- Can double as a gaming/general workstation

### Cons

- **Expensive total build** (~$4,000-5,000; GPU alone is ~$2,000)
- **High power consumption** (~600-700W under load) — need a quality 850W+ PSU
- Larger form factor — ATX mid-tower, not compact
- Moderate to loud under GPU load (fan-dependent)
- 32 GB VRAM limits max model size; 70B models require CPU offload and lose most of the speed advantage
- RTX 5090 availability can be limited (high demand)
- Requires building a custom PC (not plug-and-play like Mac Mini or Z2 Mini)
- System RAM (DDR5 ~90 GB/s) is far slower than VRAM — offloaded layers are much slower

---

## Using the ThinkStation PGX / DGX OS

DGX OS is an Ubuntu-based Linux distribution optimized for NVIDIA AI workloads.

### 1. As a Remote AI Inference Server (Recommended)

```
Your Windows laptop/desktop  ──HTTP API──>  ThinkStation PGX (Ollama server)
         (VS Code, scripts)                    (runs LLMs locally)
```

- Install Ollama on DGX OS, expose its API on your local network
- Your scripts call `http://pgx-machine:11434/api/generate` instead of `localhost`
- This is the most practical setup for your coding workflow

### 2. Development Directly on DGX OS

- VS Code Remote SSH from your Windows machine into the PGX
- .NET SDK is available for ARM64 Linux (works)
- But running/testing Windows-specific code won't work natively

### 3. Key Limitations

- No Windows GUI applications
- No Visual Studio (only VS Code via SSH)
- Docker works natively — can containerize everything
- ARM64 means some tools may need recompilation

---

## Models Unlocked by New Hardware

### Models Accessible Only on New Hardware (not feasible on P52)

| Model | Size | Type | Quality Level | Available On |
| ----- | ---- | ---- | ------------- | ----------- |
| `qwen2.5-coder:32b` | 20 GB | Code-specific | Near GPT-4o on coding benchmarks | All four options |
| `devstral-small-2:24b` | 15 GB | Agentic coding | 65.8% SWE-bench, Apache 2.0 | All four options |
| `qwen3-coder-next` | 52 GB | MoE coding (80B-A3B) | Agentic, 256K context, only 3B active | HP Z2, PGX only |
| `glm-4.7-flash` | 19 GB | MoE reasoning (30B-A3B) | 59.2% SWE-bench Verified | All four options |
| `deepcoder:14b` | 9 GB | Reasoning coder | Matches o3-mini (Low) on LiveCodeBench | All (barely on P52) |
| 70B class models | ~40 GB | General/coding | Frontier-class reasoning | HP (slow) / PGX (good) |
| 200B class models | ~100+ GB | Frontier | Comparable to cloud APIs | PGX only |

### Coding-Specific Model Recommendations by Hardware

**HP Z2 Mini G1a — Recommended Model Stack:**

```
Primary:    qwen2.5-coder:32b     (20 GB, best open-source coder)
Fast:       qwen2.5-coder:7b      (4.7 GB, parallel instances)
Agentic:    devstral-small-2:24b   (15 GB, SWE-bench champion at this size)
Reasoning:  deepcoder:14b          (9 GB, hard algorithmic tasks)
```

**Mac Mini M4 Pro 48 GB — Recommended Model Stack:**

```
Primary:    qwen2.5-coder:32b     (20 GB, fits in 48 GB unified memory)
Fast:       qwen2.5-coder:7b      (4.7 GB, ~45 tok/s, parallel instances)
Agentic:    devstral-small-2:24b   (15 GB, good speed on Apple Silicon)
Reasoning:  deepcoder:14b          (9 GB, ~25 tok/s)
```

**Custom RTX 5090 Build — Recommended Model Stack:**

```
Primary:    qwen2.5-coder:32b     (20 GB, fits entirely in 32 GB VRAM → FASTEST)
Fast:       qwen2.5-coder:7b      (4.7 GB, ~150+ tok/s, many parallel instances)
Agentic:    devstral-small-2:24b   (15 GB, fully in VRAM → ~80 tok/s)
Reasoning:  deepcoder:14b          (9 GB, fully in VRAM → ~100 tok/s)
```

**ThinkStation PGX — Recommended Model Stack:**

```
Primary:    qwen3-coder-next       (52 GB, MoE, fast w/ only 3B active)
Quality:    qwen2.5-coder:32b      (20 GB, battle-tested)
Agentic:    devstral-small-2:24b   (15 GB, multi-file edits)
Frontier:   70B models             (~40 GB, for the hardest tasks)
```

---

## Decision Framework

### The ROI Question for Your Workflow

Your workflow: **Cloud LLM → breaks down tasks → local LLM implements small tasks**

| Factor | Analysis |
| - | - |
| **Are small tasks hard for local LLMs?** | If tasks are truly small and well-specified, even a 7B model on your current P52 can handle many of them at ~10 tok/s. The bottleneck may not be model quality. |
| **Parallelism benefit** | New HW enables 3-6 parallel instances. If you run 100 tasks/day, this saves hours. If you run 10 tasks/day, savings are minimal. |
| **Model quality jump** | Going from 7B on P52 → 32B-70B on new HW is a major quality jump. Complex refactors, multi-file edits, and C# specific patterns improve dramatically. |
| **Cloud alternative** | For ~$0.50-2/hour, you can rent A100/H100 cloud GPUs. $3,000-5,000 buys 2,500-10,000 hours of cloud GPU time. |

### Recommendation Matrix

| If your situation is... | Recommendation |
| - | - |
| You run <20 coding tasks/day, tasks are simple | **Don't buy.** P52 + `qwen2.5-coder:7b` is sufficient. |
| You want best value for significant LLM upgrade | **Mac Mini M4 Pro 48 GB (~$1,599).** Best price/perf ratio. Use as network Ollama server from your P52. 32B models at ~12 tok/s, 7B at ~45 tok/s. Silent. |
| You run 20-100 tasks/day, mix of simple/complex | **Buy the HP Z2 Mini G1a.** Windows compatible, powerful enough for 32B models, 2-3 parallel instances. Doubles as primary workstation. |
| You want maximum per-token speed, Windows native | **Custom RTX 5090 Build (~$4,000-5,000).** 1,792 GB/s VRAM destroys everything else for models ≤32B. Full CUDA. Fully upgradeable. |
| You need 70B+ models daily, building AI-heavy product | **Buy the DGX Spark (PGX).** But keep a Windows machine for dev. Total cost: ~$3,000 + existing P52. |
| You want to experiment but minimize cost | **Use cloud GPUs** (RunPod, vast.ai, Lambda) for $0.30-1/hr. Test workflow first. Buy after validating the pipeline. |

---

## Bottom-Line Recommendation

**For this specific use case (C# .NET developer, Copilot/Codex orchestration, Windows 11 Pro user):**

1. **Mac Mini M4 Pro 48 GB is the best bang for the buck** (~$1,599) — the cheapest meaningful upgrade. Use it as a dedicated Ollama server on your network. Runs 32B coding models silently at ~12 tok/s, 7B at ~45 tok/s. Your P52 stays your dev machine; scripts call the Mac Mini's Ollama API.

2. **HP Z2 Mini G1a is the pragmatic all-in-one choice** (~$4,500-5,000) — a single machine that replaces the P52 for both development AND AI inference. Stays in the Windows ecosystem. 128 GB unified RAM handles 70B models. Can run 2-3 parallel Ollama instances.

3. **Custom RTX 5090 Build is the raw performance king** (~$4,000-5,000) — for the absolute fastest token generation on models up to 32B. 1,792 GB/s VRAM bandwidth is 6.5x the Mac Mini and HP. Windows native, CUDA native, fully upgradeable. Best choice if you want both a powerful dev workstation and the fastest possible local LLM inference.

4. **ThinkStation PGX is the AI enthusiast choice** (~$3,000) — faster inference and largest model support (200B), but it's a second machine you SSH into. Can't use it as a daily driver. The ARM/Linux constraint adds friction.

5. **Before buying any of these, validate the pipeline on the P52 first.** Pull `qwen2.5-coder:7b`, write orchestration scripts, run 50 tasks. Measure how often the model fails vs. succeeds. If 7B solves 80%+ of well-specified small tasks, the ROI shrinks dramatically. If it fails frequently, the quality jump to 32B on new hardware becomes clearly worth it — and then the Mac Mini at $1,599 is the smartest first purchase.

### Price/Performance Ranking (for coding LLM inference)

| Rank | Device | Price | Best Model | Est. tok/s | $/tok/s Efficiency |
| ---- | ------ | ----- | ---------- | ---------- | ------------------ |
| 1 | **Mac Mini M4 Pro 48 GB** | ~$1,599 | qwen2.5-coder:32b | ~12 tok/s | **$133/tok/s** |
| 2 | **ThinkStation PGX** | ~$3,000 | qwen2.5-coder:32b | ~40 tok/s | $75/tok/s |
| 3 | **Custom RTX 5090 Build** | ~$4,500 | qwen2.5-coder:32b | ~60 tok/s | $75/tok/s |
| 4 | **HP Z2 Mini G1a** | ~$4,750 | qwen2.5-coder:32b | ~20 tok/s | $238/tok/s |

*$/tok/s = price divided by sustained tok/s on the primary coding model. Lower is better for value; higher tok/s is better for raw speed.*

---

## Sources

- [Ollama Model Library](https://ollama.com/library)
- [EvalPlus Leaderboard](https://evalplus.github.io/leaderboard.html)
- [SWE-bench](https://www.swebench.com/)
- [Notebookcheck HP Z2 Mini G1a Review](https://www.notebookcheck.net/HP-Z2-Mini-G1a-with-AMD-Strix-Halo-review-Compact-workstation-with-Ryzen-AI-Max-and-Radeon-RX-8060S.1069652.0.html)
- [NVIDIA DGX Spark](https://www.nvidia.com/en-us/products/workstations/dgx-spark/)
- [Lenovo ThinkStation PGX Announcement](https://news.lenovo.com/all-new-lenovo-thinkstation-pgx-big-ai-innovation-in-a-small-form-factor/)
- [NVIDIA DGX Spark Press Release](https://nvidianews.nvidia.com/news/nvidia-puts-grace-blackwell-on-every-desk-and-at-every-ai-developers-fingertips)
- [Apple Mac Mini M4 Pro Specs](https://www.apple.com/mac-mini/specs/)
- [Notebookcheck Mac Mini M4 Pro Review](https://www.notebookcheck.net/Apple-Mac-Mini-M4-Pro-review-The-compact-and-frugal-desktop-PC-with-top-performance-and-expensive-upgrades.946883.0.html)
- [NVIDIA GeForce RTX 5090](https://www.nvidia.com/en-us/geforce/graphics-cards/50-series/rtx-5090/)
- [Apple Mac Studio Specs](https://www.apple.com/mac-studio/specs/)
- [2025 Mac Studio Announcement](https://www.notebookcheck.net/2025-Mac-Studio-unveiled-with-Apple-M4-Max-and-Apple-M3-Ultra-SoC.973066.0.html)
