# Parameterized-Set-Associative-Cache-Controller-Write-Back-Write-Allocate

A synthesizable, parameterized RTL implementation of a **set-associative cache controller** written in **Verilog HDL**. The controller supports configurable cache organization, LRU replacement, write-back, write-allocate, dirty block management, and memory stall handling. The design has been functionally verified using 11 independent testbenches and synthesized on a Xilinx Artix-7 FPGA using Vivado.

---

## Features

- Parameterized cache architecture
- Configurable associativity
- Configurable number of cache lines
- Configurable line size
- 32-bit addressing
- Read hit / Read miss handling
- Write hit / Write miss handling
- Write-Back policy
- Write-Allocate policy
- Dirty bit management
- Valid bit management
- LRU replacement policy
- Memory stall generation
- Parameterized FSM-based controller
- Synthesizable RTL

---

## Verified Configuration

| Parameter | Value |
|-----------|------:|
| Address Width | 32 bits |
| Cache Lines | 256 |
| Line Size | 2 Bytes |
| Associativity | 2-Way |
| Memory Latency | 4 Cycles |

Although the RTL is parameterized, the above configuration has been fully verified and synthesized.

---

## Cache Organization

```
                  CPU
                   │
             Cache Controller
                   │
      ┌────────────┴────────────┐
      │                         │
  Tag Array                Data Array
      │                         │
 Valid / Dirty            Cache Memory
      │                         │
      └────────────┬────────────┘
                   │
              LRU Logic
                   │
           Memory Interface
                   │
              Main Memory
```

---

## Project Structure

```
Cache_Controller/
│
├── RTL/
│   ├── TOP_MODULE.v
│   ├── CACHE_CONTROL_UNIT.v
│   ├── FSM_UNIT.v
│   ├── CACHE_MAPPING.v
│   ├── DATA_MEMORY.v
│   └── PBUF.v
│
├── Testbenches/
│   ├── tb_01_read_miss.v
│   ├── tb_02_read_hit.v
│   ├── tb_03_lru_replacement.v
│   ├── tb_04_set_independence.v
│   ├── tb_05_mixed_access.v
│   ├── tb_06_lru_complete.v
│   ├── tb_07_reset.v
│   ├── tb_08_boundary_address.v
│   ├── tb_09_write_hit.v
│   ├── tb_10_write_miss_clean.v
│   └── tb_11_dirty_eviction.v
│
├── Constraints/
│   └── CONST.xdc
│
├── Reports/
│   ├── top_module_utilization_synth.rpt
│   ├── top_module_timing_summary_routed.rpt
└── README.md
```

---

## Functional Verification

The controller was verified using twelve standalone testbenches covering normal operation and corner cases.

| Testbench | Description |
|------------|-------------|
| TB-01 | Read Miss |
| TB-02 | Read Hit |
| TB-03 | LRU Replacement |
| TB-04 | Set Independence |
| TB-05 | Mixed Read Access |
| TB-06 | Complete LRU Verification |
| TB-07 | Reset Verification |
| TB-08 | Boundary Address Verification |
| TB-09 | Write Hit |
| TB-10 | Write Miss (Clean Block) |
| TB-11 | Dirty Block Eviction |

**Verification Status**

✔ All 11 testbenches passed successfully.

---

# Synthesis Results

**Tool**

- Xilinx Vivado 2025.2

**Target Device**

- Xilinx Artix-7 XC7A15T-CPG236-3

### Resource Utilization

| Resource | Used | Available | Utilization |
|----------|------:|----------:|-----------:|
| LUTs | 8768 | 10400 | 84.31% |
| Flip-Flops | 13997 | 20800 | 67.29% |
| Block RAM | 0 | 25 | 0% |
| DSP | 0 | 45 | 0% |
| I/O | 53 | 106 | 50.0% |

---

# Timing Results

### Target Clock

- **100 MHz (10 ns)**

### Timing Summary

| Metric | Result |
|---------|-------:|
| Worst Negative Slack (WNS) | +0.958 ns |
| Total Negative Slack (TNS) | 0.000 ns |
| Worst Hold Slack (WHS) | +0.165 ns |
| Total Hold Slack (THS) | 0.000 ns |

### Timing Status

- All user-defined timing constraints met.
- Estimated maximum operating frequency: **≈110 MHz**

---

## Cache Features Implemented

- Tag comparison
- Cache indexing
- Valid bit handling
- Dirty bit handling
- LRU replacement
- Write-back policy
- Write-allocate policy
- Cache refill
- Dirty block eviction
- CPU stall management
- Parameterized cache organization
- FSM-based cache controller

---

## Design Flow

```
Architecture
      │
      ▼
RTL Design
      │
      ▼
Functional Simulation
      │
      ▼
Verification (11 Testbenches)
      │
      ▼
Synthesis (Vivado)
      │
      ▼
Implementation
      │
      ▼
Timing Analysis
```

---

## Tools

- Verilog HDL
- Xilinx Vivado 2025.2
- XSIM Simulator

---

## Future Enhancements

- Configurable replacement policies
- AXI4-Lite interface
- Burst memory transactions
- Separate Instruction and Data Cache
- Multi-level cache hierarchy

---

## Author

**Sathwik**


