{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools
}:

buildPythonPackage {
  pname = "basicauth";
  version = "1.0.0";

  src = (fetchFromGitHub {
    owner = "rdegges";
    repo = "python-basicauth";
    rev = "bccbe82ba961674b83f853bf141c7bf509198bf2";
    hash = "sha256-W7aPYUbbskTGzJdL5aCb1aOFRWPEF2ZuKZZFw4AYIoE=";
  });

  format = "setuptools";

  nativeBuildInputs = [ setuptools ];

  meta = {
    description = "An incredibly simple HTTP basic auth implementation.";
    homepage = "https://github.com/rdegges/python-basicauth";
    license = lib.licenses.unlicense;
  };
}
