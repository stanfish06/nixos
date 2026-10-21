# Ghidra plus what scripts and agents need to drive its API headless: PyGhidra
# (CPython in-process via JPype), JDK 21 + gradle for Java scripts and
# extension builds, and the Python type stubs ghidra ships as a wheel.
# home-manager module, imported by home.nix and home-darwin.nix.
{ pkgs, ... }:
let
  # unstable tracks upstream releases, 26.05 lags a minor
  ghidra = pkgs.unstable.ghidra;
  ghidraHome = "${ghidra}/lib/ghidra";
  # same JDK the ghidra launcher wraps (zulu on darwin, openjdk on linux)
  jdk = pkgs.unstable.jdk21;
  python3Packages = pkgs.unstable.python3Packages;

  ghidra-stubs = python3Packages.buildPythonPackage {
    pname = "ghidra-stubs";
    inherit (ghidra) version;
    format = "wheel";
    src = "${ghidraHome}/docs/ghidra_stubs/ghidra_stubs-${ghidra.version}-py3-none-any.whl";
  };
  # nixpkgs pyghidra instead of ghidra's bundled wheels: the manylinux jpype1
  # wheel can't find libstdc++ under nix python
  python = python3Packages.python.withPackages (ps: [
    ps.pyghidra
    ghidra-stubs
  ]);

  # ghidra's pyghidraRun asks via input() to create a venv on first run, which
  # hangs non-interactive callers; these wrappers call pyghidra directly.
  # JAVA_HOME_OVERRIDE skips pyghidra's probe of `java` on PATH (macOS
  # /usr/bin/java resolves to Corretto 11; ghidra needs 21)
  pyghidraEnv = ''
    export GHIDRA_INSTALL_DIR=${ghidraHome}
    export JAVA_HOME_OVERRIDE=${jdk.home}
  '';
  # python with pyghidra importable: `ghidra-python script.py`
  ghidra-python = pkgs.writeShellScriptBin "ghidra-python" ''
    ${pyghidraEnv}
    exec ${python}/bin/python3 "$@"
  '';
  # pyghidra CLI: `pyghidra -g` for the GUI with the python console,
  # `pyghidra <binary> <script.py>` to run a script against a program
  pyghidra = pkgs.writeShellScriptBin "pyghidra" ''
    ${pyghidraEnv}
    exec ${python}/bin/pyghidra "$@"
  '';
  # analyzeHeadless under PyGhidra so -preScript/-postScript take .py as well
  # as .java; same launch pyghidraRun -H does
  analyzeHeadless = pkgs.writeShellScriptBin "analyzeHeadless" ''
    ${pyghidraEnv}
    exec ${python}/bin/python3 -m pyghidra.ghidra_launch \
      --install-dir ${ghidraHome} ghidra.app.util.headless.AnalyzeHeadless "$@"
  '';
in
{
  home.packages = [
    ghidra
    # java/javac on PATH; shadows /usr/bin/java on macOS
    jdk
    # support/buildExtension.gradle needs >= 8.5; nixpkgs gradle runs on jdk21
    pkgs.unstable.gradle
    ghidra-python
    pyghidra
    analyzeHeadless
  ];
  # for gradle buildExtension and pyghidra installs outside the wrappers
  home.sessionVariables.GHIDRA_INSTALL_DIR = ghidraHome;
}
