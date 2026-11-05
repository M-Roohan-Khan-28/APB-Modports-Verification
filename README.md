# APB RAM with Master and Slave Modports

**SystemVerilog · Interface direction control · Directed simulation**

A four-word, 32-bit APB RAM with explicit master and slave modports. The interface defines the signal directions for each role, while the slave handles aligned word accesses and reports invalid addresses through `PSLVERR`.

The repository retains its directed readback testbench, simulation entry points, and historical results. It is a separate implementation from the 64-word APB interface project.

See [original source documentation](SOURCE_README.md) for the baseline files and the verification-status section below for the available evidence.

## Run

From the repository root, with the required ModelSim/Questa executables and appropriate licence available:

```bash
bash sim/run.sh
```

Existing Windows instructions, where supplied, are retained in `scripts/`. Do not assume the testbench will run in every edition of a simulator. Check [the retained validation report](source-docs/VALIDATION.md) and the original README.

## Verification status

The included logs are historical evidence copied from the source repository. **The extracted copy has not been simulated by this extraction script.** Re-run before reporting fresh results. Some original exercises were blocked by verification-feature licence restrictions; those restrictions are not changed by packaging.

## Provenance and changes

Source commit: `df8d6f66898a08df75cd2071ddac7bbba9ba9b16`. Source path: `projects/apb-modports`.

[SOURCE_PROVENANCE.json](SOURCE_PROVENANCE.json) records checksums of every original file. `SOURCE_README.md` is the unchanged original README. No RTL or testbench functionality was changed during extraction. Source history remains available in the original repository; this is a snapshot, not a rewrite of its authorship.

## Next engineering work

Planned tests will cover all implemented addresses, invalid-address responses, reset interruption, and back-to-back transfers. New results will be recorded separately from the retained source logs.
