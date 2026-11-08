# Separate reusable APB UVM adapter

The reusable environment lives in
[AMBA-Protocol-Verification at source ff158f4f7ed844f2a7ab9b3e19423ebc50be8f60](https://github.com/M-Roohan-Khan-28/AMBA-Protocol-Verification/blob/ff158f4f7ed844f2a7ab9b3e19423ebc50be8f60/docs/ADVANCED_APB.md).
Adapter 1 pins this repository's unchanged RTL to
`7fd99b382e13faa7a839610b63063a72748f4bf3`. It expects four aligned words
at 0, 4, 8 and 12, error responses for invalid addresses, no invalid-write
side effects, and asynchronous reset clearing memory.

The new UVM environment uses independent public-pin checking, deterministic
sequences and concurrent assertions. A separate synthetic responder exercises
wait states; this zero-wait DUT is not claimed to implement them. Its
requirements-based covergroup mode remains licence-blocked until it can run
and export a report. Procedural requirement counters are not functional coverage.

After checking out the immutable AMBA source linked above, run from its root:

```powershell
python scripts/run_apb_uvm.py --sim-bin C:\MXR\Quartus\25.1\questa_fse\win64 --uvm-lib C:\MXR\Quartus\25.1\questa_fse\uvm-1.2 --uvm-include C:\MXR\Quartus\25.1\questa_fse\verilog_src\uvm-1.2\src --adapters 1 --output C:\short\apb-modports-uvm-new
if ($LASTEXITCODE -ne 0) { throw 'APB UVM or assertion qualification failed or was blocked' }
```

Python, Git, Questa 2025.2 and its matching installed UVM 1.2 library are needed.
Use a fresh output directory and one simulator session at a time on the tested
node-locked licence. This documentation does not change RTL, existing benches,
licences, attribution or historical results. It does not claim full APB
compliance, coverage closure, synthesis, timing or hardware validation.

## Published branch evidence

A clean detached GitHub clone passed 560 accepted transfers and 848 independent comparisons for this adapter,
plus the shared five expected-negative assertion detections and one legal
assertion control. The combined three-adapter/nine-substep wrapper exited 0.
See the [immutable raw evidence and summary](https://github.com/M-Roohan-Khan-28/AMBA-Protocol-Verification/blob/2a337d28e718f274d44b0eb7cad80efd745a1331/reports/advanced-apb-2026-11-08/SUMMARY.md).
A deliberate read-data fault produced an independent scoreboard fatal and
wrapper exit 1. Functional coverage export remains NOT RUN; no percentage is claimed.
