# Immich with its machine-learning service on onnxruntime's CUDA execution provider
#
# Only onnxruntime is rebuilt with `cudaSupport` (swapped into the ML service's Python set, so
# rapidocr and immich-model pick it up too) rather than importing nixpkgs with a global
# `cudaSupport`, which would rebuild far more of the closure. The server derivation is untouched -
# only its `machine-learning` passthru, which the upstream module runs, is replaced.
#
# `cudaCapabilities` narrows the GPU generations compiled for by overriding the `config` of
# onnxruntime's own `cudaPackages` scope, leaving the rest of the package set alone. Empty keeps
# nixpkgs' default (every Turing+ generation; cuDNN 9.11+ dropped Maxwell/Pascal/Volta, so
# there's no point targeting an older card).
#
# NCCL is disabled: it only serves multi-GPU collectives, which single-GPU inference never uses, and
# skipping it avoids a long compile. It also dodges nixpkgs' nccl 2.32.3-1 src hash mismatch
# (GitHub `export-subst` drift, fixed upstream in NixOS/nixpkgs@f20ba3c6).
#
# onnxruntime's built-in TensorRT provider is disabled too: Immich never selects it (it uses CUDA,
# or TensorRT-RTX via the separate `onnxruntime_ep_nv_tensorrt_rtx` plugin), and the TensorRT
# 11.3 redist crashes patchelf (`shiftFile: Assertion splitIndex == -1`) in addDriverRunpath.
#
# Every `patches/*.patch` is applied to the server/web source in name order, hence the numbered
# `NNN-` prefixes; a new patch needs no change here. Patching the source means Immich is built
# locally rather than fetched from the binary cache (`pnpmDeps` is unaffected - no lockfile edits).
# When an Immich upgrade fails to apply one, rebase it or drop it if upstream now covers it:
#   - 000-shared-person-inherit: a shared person's name/birth date follows the sharer's edits
#     until the recipient sets their own (upstream only copies them once, when shared), after
#     which the sharer's value shows as an "aka". No schema change: "inherited" means empty or
#     still equal to the sharer's value.
#---------------------------------------------------------------------------------------------------
{ immich, lib, cudaCapabilities ? [ ] }:
let
  machine-learning = immich.machine-learning.override (old: {
    python3 = old.python3.override {
      packageOverrides = pyfinal: pyprev: {
        onnxruntime = pyprev.onnxruntime.override (o: {
          onnxruntime = o.onnxruntime.override (ort: {
            cudaSupport = true;
            ncclSupport = false;
            tensorrtSupport = false;
          } // lib.optionalAttrs (cudaCapabilities != [ ]) {
            cudaPackages = ort.cudaPackages.override (cp: {
              config = cp.config // { inherit cudaCapabilities; };
            });
          });
        });
      };
    };
  });
  patches = map (name: ./patches + "/${name}") (builtins.attrNames (lib.filterAttrs
    (name: type: type == "regular" && lib.hasSuffix ".patch" name) (builtins.readDir ./patches)));
in
immich.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ patches;
  passthru = old.passthru // { inherit machine-learning; };
})
