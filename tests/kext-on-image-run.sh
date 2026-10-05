# /usr/tests/nextbsd/kext/run.sh — per-arch display validation (T6).
#
# IOKit's present-scan picks each arch's NATIVE display kext from the
# devices the machine actually has:
#
#   amd64 (q35): the FIRST video device is the machine's boot VGA
#     (vgapci0: <VGA-compatible display> "Boot video device") — it cannot
#     be removed (OVMF/efifb depend on it), so amd64 ALWAYS has a bochs
#     VGA first and the virtio-gpu add-on (if any) is a second, inert
#     device. IOKit maps the boot VGA -> BochsGraphics: that is amd64's
#     display, and it is what the gate asserts (BOCHS).
#     The virtio-gpu add-on does not attach on amd64 (vgap gap,
#     nextbsd-ci#6): tracked as VGAP, warn-class, reported not gated.
#
#   arm64 (-M virt): there is NO VGA; the only video device is the
#     virtio-gpu -> VirtIOGraphics. That is arm64's display (VIRTIO).
#
# Each image therefore emits ONLY its own arch's markers: the harness'
# marker arms are policy-driven, and a fail-gates -FAIL line exits 1 even
# when the marker is off-arch, so arm64 must never print BOCHS/VGAP and
# amd64 must never print VIRTIO. The VGAP check is informational: it is
# NOT counted in the summary verdict (its marker arm carries the signal;
# counting it would let a lost serial line flip the suite's own verdict).
set -u
ok=0
fail=0
skip=0

# FreeBSD names the arm64 arch "arm64" (uname -m), Linux/ELF "aarch64";
# accept both. Anything else is treated as amd64: a display gate that
# cannot tell the arch apart should fail loudly, not silently skip.
machine=$(uname -m 2>/dev/null || echo unknown)
echo "kext suite: machine=$machine"

case "$machine" in
aarch64|arm64)
    # arm64: VirtIOGraphics is the display (the only video device on virt).
    if kextstat 2>/dev/null | grep -qi virtiographics; then
        echo "VIRTIO-OK: VirtIOGraphics is loaded (virtio-gpu bound)"
        kextstat 2>/dev/null | grep -i virtio || true
        ok=$((ok + 1))
    else
        echo "VIRTIO-FAIL: no VirtIOGraphics in kextstat (arm64 display down)"
        kextstat 2>/dev/null || true
        fail=$((fail + 1))
    fi
    ;;
*)
    # amd64: BochsGraphics is the display (boot VGA -> vgapci0).
    if kextstat 2>/dev/null | grep -qi bochsgraphics; then
        echo "BOCHS-OK: BochsGraphics is loaded (boot VGA bound)"
        kextstat 2>/dev/null | grep -i bochs || true
        ok=$((ok + 1))
    else
        echo "BOCHS-FAIL: no BochsGraphics in kextstat (amd64 display down)"
        kextstat 2>/dev/null || true
        fail=$((fail + 1))
    fi

    # The amd64 virtio-gpu add-on: known vgap attach gap (nextbsd-ci#6).
    # Warn-class only — reported, never gated, not in the summary verdict.
    if kextstat 2>/dev/null | grep -qi virtiographics; then
        echo "VGAP-OK: VirtIOGraphics loaded on amd64 (vgap attach recovered)"
        kextstat 2>/dev/null | grep -i virtio || true
    else
        echo "VGAP-FAIL: no VirtIOGraphics in kextstat (amd64 vgap still undriven)"
        kextstat 2>/dev/null | grep -i virtio || true
    fi
    ;;
esac

echo "NEXTBSD-KEXT-SUITE-DONE"
echo "NEXTBSD-TEST-SUMMARY ok=$ok fail=$fail skip=$skip"
