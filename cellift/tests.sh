# Copyright 2022 Flavien Solt, ETH Zurich.
# Licensed under the General Public License, Version 3.0, see LICENSE for details.
# SPDX-License-Identifier: GPL-3.0-only

set -e -x

# Usage:
#   bash tests.sh                       # run cellift + analyze
#   bash tests.sh --naive_p1            # run vanilla, save /work/output_result/out1.trace
#   bash tests.sh --naive_p2            # run vanilla, save /work/output_result/out2.trace
#   bash tests.sh --naive               # alias of --naive_p2
NAIVE_P1=0
NAIVE_P2=0
for arg in "$@"; do
    case "$arg" in
        --naive_p1) NAIVE_P1=1 ;;
        --naive_p2) NAIVE_P2=1 ;;
        --naive)    NAIVE_P2=1 ;;
    esac
done

if [ "$NAIVE_P1" -eq 1 ] && [ "$NAIVE_P2" -eq 1 ]; then
    echo "[tests.sh] error: --naive_p1 and --naive_p2 are mutually exclusive" >&2
    exit 2
fi

export SIMLEN=500
export TRACEFILE=$PWD/out.trace
. ../../../cellift-meta/env.sh

benchmarks="$CELLIFT_META_ROOT/benchmarks/out/ibex/bin/"
( cd "$CELLIFT_META_ROOT/benchmarks" && bash build-benchmarks.sh ibex )
bin="$benchmarks/medemo.riscv"
export SIMROMELF=$bin
export SIMSRAMELF=$bin

if [ ! -f "$SIMROMELF" ] || [ ! -f "$SIMSRAMELF" ]; then
    echo "Benchmarks failed to build." >&2
    exit 1
fi

export SIMSRAMTAINT=/work/import_from_hw_sw_fuzzer/unique_regs_meminit.txt
export SIMROMTAINT=/work/import_from_hw_sw_fuzzer/unique_regs_meminit.txt

env | sort
mkdir -p /work/output_result

if [ "$NAIVE_P1" -eq 1 ]; then
    echo "[tests.sh] --naive_p1 set: skip cellift and analysize_trace_ibex.sh"
    make run_vanilla_trace
    cp "$TRACEFILE" /work/output_result/out1.trace

elif [ "$NAIVE_P2" -eq 1 ]; then
    echo "[tests.sh] --naive_p2 set: skip analysize_trace_ibex.sh"
    make run_vanilla_trace
    cp "$TRACEFILE" /work/output_result/out2.trace

else
    make run_cellift_trace
    cp "$TRACEFILE" /work/output_result/out.trace
    ( cd /work/output_result && bash /work/harness/ibex-test/analysize_trace_ibex.sh )
fi
