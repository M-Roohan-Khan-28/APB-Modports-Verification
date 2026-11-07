#!/usr/bin/env python3
"""Run the preserved APB-modports bench and independent four-word oracle."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time


def executable(name):
    prefix = os.environ.get("MODELSIM_BIN")
    choices = ([str(Path(prefix) / (name + ".exe")), str(Path(prefix) / name)]
               if prefix else []) + [name, name + ".exe"]
    for candidate in choices:
        found = shutil.which(candidate)
        if found:
            return found
    raise RuntimeError("Missing simulator tool: " + name)


def command(argv, cwd, logfile, timeout=120):
    try:
        result = subprocess.run(argv, cwd=cwd, capture_output=True, timeout=timeout,
                                check=False)
    except subprocess.TimeoutExpired as exc:
        logfile.write_bytes((exc.stdout or b"") + (exc.stderr or b""))
        raise RuntimeError("Timed out after %d seconds: %s" % (timeout, argv[0])) from exc
    raw = result.stdout + result.stderr
    logfile.write_bytes(raw)
    return result.returncode, raw.decode("utf-8", errors="replace")


def clean_simulation(code, log):
    return (code == 0 and not re.search(r"\*\*\s+(?:Error|Fatal):", log)
            and "# Errors: 0, Warnings: 0" in log and "$finish" in log)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--rtl", type=Path, help="Disposable fault source override")
    parser.add_argument("--capture-wave", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    out = args.output_dir.resolve()
    if out.exists():
        raise RuntimeError("Output directory exists: " + str(out))
    out.mkdir(parents=True)
    rtl = (args.rtl or root / "rtl/design.sv").resolve()
    files = [rtl, root / "tb/tb_top.sv", root / "tb/apb_contract_test.sv"]
    report = {
        "repository": "APB-Modports-Verification",
        "source_revision": subprocess.check_output(["git", "-C", str(root), "rev-parse", "HEAD"],
                                                    text=True).strip(),
        "source_dirty": bool(subprocess.check_output(["git", "-C", str(root),
                                                        "status", "--porcelain"])),
        "sources": [{"path": str(path), "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
                    for path in files],
        "seed": "0x28AB4B05 (xorshift32 write data)",
        "timeout_seconds_per_command": 120,
        "simulations": [], "overall": "FAIL"
    }
    start = time.monotonic()
    try:
        vlib, vlog, vsim = (executable(name) for name in ("vlib", "vlog", "vsim"))
        report["simulator_version"] = command([vsim, "-version"], out,
                                               out / "version.log")[1].strip()
        if command([vlib, "work"], out, out / "library.log")[0]:
            raise RuntimeError("vlib failed")
        compile_code, compile_log = command([vlog, "-sv"] + [str(p) for p in files],
                                            out, out / "compile.log")
        if compile_code or "Errors: 0, Warnings: 0" not in compile_log:
            raise RuntimeError("vlog failed or reported diagnostics")
        for top in ("tb_apb_modport", "apb_contract_test"):
            do = "run -all; quit -code 0"
            if args.capture_wave and top == "apb_contract_test":
                signals = ["PCLK", "PRESETn"] + ["bus/" + s for s in
                    "PADDR PSEL PENABLE PWRITE PWDATA PRDATA PREADY PSLVERR".split()]
                do = "vcd file apb-contract.vcd; " + "; ".join(
                    "vcd add /apb_contract_test/" + name for name in signals) + "; " + do
            argv = [vsim, "-c", "-onfinish", "exit", top, "-do", do]
            code, log = command(argv, out, out / (top + ".log"))
            entry = {"top": top, "simulator_exit_code": code, "command": argv,
                     "status": "FAIL"}
            report["simulations"].append(entry)
            if not clean_simulation(code, log):
                raise RuntimeError(top + " simulator error, fatal, missing $finish, or missing clean end")
            if top == "tb_apb_modport":
                if not re.search(r"TOTAL PASSED\s*=\s*2\b", log) or not re.search(
                        r"TOTAL FAILED\s*=\s*0\b", log) or "ALL APB TESTS PASSED" not in log:
                    raise RuntimeError("Legacy two-check result missing or wrong")
                entry["checks"] = 2
            else:
                marker = re.search(r"APB_MODPORT_CONTRACT_PASS probes=(\d+) guards=(\d+) "
                                   r"checks=(\d+) errors=(\d+) resets=(\d+) seed=0x([0-9A-F]+)", log)
                if not marker or tuple(int(x) for x in marker.groups()[:5]) != \
                        (512, 1049, 12488, 507, 1) or marker.group(6) != "28AB4B05":
                    raise RuntimeError("Independent contract count/seed marker missing or wrong")
                entry.update({"checks": 12488, "probes": 512, "guards": 1049,
                              "errors": 507, "resets": 1})
            entry["status"] = "PASS"
            print("PASS " + top + " checks=" + str(entry["checks"]))
        if args.capture_wave:
            vcd = out / "apb-contract.vcd"
            if not vcd.is_file() or not vcd.stat().st_size:
                raise RuntimeError("Requested measured waveform was not produced")
            report["waveform"] = {"path": str(vcd),
                                  "sha256": hashlib.sha256(vcd.read_bytes()).hexdigest()}
            renderer = root / "tools/vcd_to_svg.py"
            signals = ["apb_contract_test.PCLK", "apb_contract_test.PRESETn"]
            signals += ["apb_contract_test.bus." + s for s in
                        "PADDR PSEL PENABLE PWRITE PWDATA PREADY PSLVERR".split()]
            signals.append("apb_contract_test.bus.PRDATA*")
            render = [sys.executable, str(renderer), "--vcd", str(vcd), "--signals",
                      *signals, "--start", "0", "--end", "500000",
                      "--output", str(out / "apb-contract.svg"),
                      "--origin", "simulator", "--title", "Measured APB modports contract"]
            if command(render, out, out / "render.log")[0]:
                raise RuntimeError("VCD render failed")
        report["overall"] = "PASS"
    except Exception as exc:
        report["error"] = str(exc)
        print("FAIL: " + str(exc), file=sys.stderr)
    finally:
        report["elapsed_seconds"] = round(time.monotonic() - start, 3)
        (out / "results.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return 0 if report["overall"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
