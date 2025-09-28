{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools
}:

buildPythonPackage {
  pname = "gputil";
  version = "1.4.0";

  src = (fetchFromGitHub {
    owner = "anderskm";
    repo = "gputil";
    rev = "42ef071dfcb6469b7ab5ab824bde6ca9f6d0ab8a";
    hash = "sha256-uzdo8fnaV0YftJe/+rnLz635mI8Buj6DIkB4iSNyIRo=";
  });

  format = "setuptools";

  nativeBuildInputs = [ setuptools ];

  patches = [
    ./gputil-distutils.patch
  ];

  # It errors out about not finding a GPU, so skip the check.
  doCheck = false;

  meta = {
    description = ''
      A Python module for getting the GPU status 
      from NVIDA GPUs using nvidia-smi programmically in Python
    '';
    homepage = "https://github.com/anderskm/gputil";
    license = lib.licenses.mit;
  };
}
