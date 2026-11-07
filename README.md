# APB RAM with Master and Slave Modports

**SystemVerilog · Interface direction control · Directed simulation**

A four-word, 32-bit APB RAM with explicit master and slave modports. The interface defines the signal directions for each role, while the slave handles aligned word accesses and reports invalid addresses through `PSLVERR`.

The repository retains its directed readback testbench, simulation entry points, and historical results. It is a separate implementation from the 64-word APB interface project.

See [original source documentation](SOURCE_README.md) for the baseline files and the verification-status section below for the available evidence.

## Run

From the repository root, with Python 3.9+ and compatible ModelSim/Questa
`vlib`, `vlog`, and `vsim` available, use a fresh output directory:

```powershell
$env:MODELSIM_BIN = 'C:\intelFPGA\20.1\modelsim_ase\win32aloem'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/run_sim.ps1 -OutputDir C:\short\apb-modports-unique -CaptureWave
```

The shell launcher is `bash sim/run.sh /new/output/path` on systems with
Python 3 and a compatible simulator; only `bash -n` was run here, so no Linux
simulation is claimed. The new runner refuses to overwrite output, requires
exact counts and pass markers, checks transcript errors/fatals even if the
simulator exits zero, and has 120-second per-command bounds. Historical
reports are unchanged. See the [retained validation report](source-docs/VALIDATION.md)
for earlier evidence.

## Verification status

Extraction-time logs remain historical. At source commit
`df4cd7d1ebe1cfed0dbb5dd6b5326fb5f8d44777`, a clean-source run passed
the preserved **2 readback checks** and **12,488 independent comparisons**.
The new bench exercised all **512 address-direction probes** (256 addresses x
read/write), 1,049 additional guard transfers, 507 observed error transfers,
and a reset-cancelled write using deterministic data seed `0x28AB4B05`.
ModelSim Intel FPGA Starter Edition `vsim 2020.1 Simulator 2020.02 Feb 28
2020` and the wrapper exited 0. [Raw logs and JSON](reports/technical-completion-2026-11-07/passing/)
record the real result. A disposable range fault made address `0x10` legal:
the old two-check bench still passed, while the new oracle reported
`APB_CONTRACT_MISMATCH` and the wrapper exited 1. The [fault evidence](reports/technical-completion-2026-11-07/range-fault/)
is separate from active RTL.

The [measured APB transaction figure](reports/technical-completion-2026-11-07/passing/apb-contract.svg),
[address-error window](reports/technical-completion-2026-11-07/passing/apb-boundary.svg),
and [reset window](reports/technical-completion-2026-11-07/passing/apb-reset.svg)
come from the [raw simulator VCD](reports/technical-completion-2026-11-07/passing/apb-contract.vcd).
The sibling JSON files record VCD hash, 1 ps timebase and exact crops.
[Verification plan](docs/verification_plan.md) states the bounded contract.

Installed Starter edition did not execute the probed randomization,
covergroups, SVA, or UVM flows. Those remain blocked/NOT RUN; portable check
counts do not establish coverage closure or full APB compliance. Synthesis,
timing, FPGA, and hardware were not run.

## Provenance and changes

Source commit: `df8d6f66898a08df75cd2071ddac7bbba9ba9b16`. Source path: `projects/apb-modports`.

[SOURCE_PROVENANCE.json](SOURCE_PROVENANCE.json) records checksums of every original file. `SOURCE_README.md` is the unchanged original README. No RTL or testbench functionality was changed during extraction. Source history remains available in the original repository; this is a snapshot, not a rewrite of its authorship.

## Next engineering work

This is a four-word APB lab, not a complete peripheral subsystem. A separate
future milestone can add licensed UVM/coverage or hardware-target evidence.
