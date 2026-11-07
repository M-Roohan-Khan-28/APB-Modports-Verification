# Four-word APB contract and verification plan

`apb_slave_ram` exposes four 32-bit words at aligned byte addresses `00`,
`04`, `08`, and `0C` through `apb_if`. During SETUP and idle it drives
PREADY/PSLVERR low and PRDATA zero. In ACCESS it responds immediately:
valid reads return the addressed word, valid writes commit on the rising
clock, and every other address returns PSLVERR without a write. Active-low
asynchronous reset clears all four words and cancels a pending write. This
bounded design has no wait-state, byte-strobe, or larger peripheral contract.

The original [two-readback bench](../tb/tb_top.sv) remains unchanged. The new
[portable contract bench](../tb/apb_contract_test.sv) maintains independent
four-word expected storage. It never reads the DUT memory to predict an
output. It checks PREADY, PSLVERR and PRDATA in SETUP, ACCESS and idle using
four-state comparisons, with a 5,000,000 ns testbench watchdog.

| Requirement | Evidence in contract bench |
| --- | --- |
| All address/direction combinations | 256 addresses x read/write = 512 named probes |
| Four-word memory isolation | Four guard reads after every probe write, plus initialization/boundary/reset guards |
| Invalid and misaligned response | All invalid addresses, explicit `10`/`01` writes, error then valid recovery |
| Reset cancellation | Assert reset during a pending ACCESS write before its accepting edge, then read all words |
| Independent data | Deterministic xorshift32 write values, seed `0x28AB4B05` |

The committed source `df4cd7d1ebe1cfed0dbb5dd6b5326fb5f8d44777`
passed 2 legacy checks and 12,488 contract comparisons across 512 probes,
1,049 guard transfers, 507 observed error transfers, and one later reset.
[Raw passing results](../reports/technical-completion-2026-11-07/passing/results.json)
show simulator version, source hash, commands, markers and exit status. A
[disposable range fault](../reports/technical-completion-2026-11-07/range-fault/fault-summary.json)
made address `10` valid: the legacy test still passed, while the independent
oracle emitted `APB_CONTRACT_MISMATCH` and the wrapper exited 1.

The measured APB figures, raw VCD and renderer metadata are published next
to the passing logs. The renderer is not a protocol checker. The observed
comparison count is not a code/functional/assertion coverage percentage.
The original RTL, source history, attribution and historical reports are
unchanged. UVM, SVA and covergroup execution remain blocked by installed
simulator capability and were not substituted for this portable suite.

