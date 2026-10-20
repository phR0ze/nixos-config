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
          } // lib.optionalAttrs (cudaCapabilities != [ ]) {
            cudaPackages = ort.cudaPackages.override (cp: {
              config = cp.config // { inherit cudaCapabilities; };
            });
          });
        });
      };
    };
  });
in
immich.overrideAttrs (old: {
  passthru = old.passthru // { inherit machine-learning; };
})
