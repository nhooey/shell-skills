{
  lib,
  makeWrapper,
  swift,
  swiftPackages,
  swiftpm,
  terminal-notifier,
}:

# The stdenv Swift itself is built with, clang included, as nixpkgs' own
# swiftpm packages use.
swiftPackages.stdenv.mkDerivation {
  pname = "onepassword-dialog-watcher";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Package.swift
      ./Sources
      ./Tests
    ];
  };

  nativeBuildInputs = [
    makeWrapper
    swift
    swiftpm
  ];

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    "$(swiftpmBinPath)/onepassword-dialog-watcher-tests"
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    install -D "$(swiftpmBinPath)/onepassword-dialog-watcher" "$out/bin/onepassword-dialog-watcher"
    wrapProgram "$out/bin/onepassword-dialog-watcher" \
      --prefix PATH : ${lib.makeBinPath [ terminal-notifier ]}
    runHook postInstall
  '';

  meta = {
    description = "Play a sound and notify while a 1Password approval dialog is on screen";
    platforms = lib.platforms.darwin;
    mainProgram = "onepassword-dialog-watcher";
  };
}
