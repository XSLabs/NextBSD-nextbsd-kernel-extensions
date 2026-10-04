#!/bin/sh
# /usr/tests/nextbsd/kext/run.sh — the kext GPU validation (T6).
#
# The kext image is the nextbsd `continuous` image with the virtio-gpu trio
# injected (the FreeBSD-VM mutation drops the kexts into /System/Library/
# Extensions). kextd auto-loads on boot any GPU kext whose personality matches
# a present device -- no explicit kextload. The shared harness boots both arches
# with -device virtio-gpu-pci (nextbsd-ci v0.3.0: alongside q35's default VGA
# on amd64, as the display on virt/arm64), so the binding GPU kext is
# VirtIOGraphics on BOTH lanes, and the assertion is arch-invariant.
#
# We validate the load with kextstat only, then emit the sentinel the shared
# harness reads as the LAST line. A -FAIL means the GPU kext did not come up
# (a real graphics regression); the harness's fail-gates policy turns that into
# a non-zero boot rc.
set -u
ok=0
fail=0
skip=0

if kextstat 2>/dev/null | grep -qi virtiographics; then
    echo "VIRTIO-OK: VirtIOGraphics is loaded (virtio-gpu bound)"
    kextstat 2>/dev/null | grep -i virtio || true
    ok=$((ok + 1))
else
    echo "VIRTIO-FAIL: no virtio-gpu GPU kext in kextstat"
    kextstat 2>/dev/null || true
    fail=$((fail + 1))
fi

echo "NEXTBSD-KEXT-SUITE-DONE"
echo "NEXTBSD-TEST-SUMMARY ok=$ok fail=$fail skip=$skip"
