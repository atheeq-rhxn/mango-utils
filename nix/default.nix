{
  lib,
  stdenvNoCC,
  makeBinaryWrapper,
  bash,
  grim,
  slurp,
  wl-clipboard,
  libnotify,
  wayfreeze,
  satty,
  gpu-screen-recorder,
  ffmpeg,
  quickshell,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "msnap";
  version = lib.trim (builtins.readFile ../VERSION);

  src = builtins.path {
    path = ../.;
    name = "source";
  };

  nativeBuildInputs = [ makeBinaryWrapper ];

  dontConfigure = true;

  buildPhase = ''
    make build \
      PREFIX="$out" \
      BINDIR="$out/bin" \
      DATADIR="$out/share" \
      SYSCONFDIR="$out/etc/xdg" \
      LOCALSTATEDIR="$out/var/lib"
  '';

  installPhase = ''
    make install \
      PREFIX="$out" \
      BINDIR="$out/bin" \
      DATADIR="$out/share" \
      SYSCONFDIR="$out/etc/xdg" \
      LOCALSTATEDIR="$out/var/lib" \
      DESTDIR=""

    substituteInPlace "$out/bin/msnap" \
      --replace-fail '#!/usr/bin/env bash' '#!${bash}/bin/bash'

    wrapProgram "$out/bin/msnap" \
      --prefix PATH : ${
        lib.makeBinPath [
          grim
          slurp
          wl-clipboard
          libnotify
          wayfreeze
          satty
          gpu-screen-recorder
          ffmpeg
          quickshell
        ]
      }
  '';

  meta = {
    description = "Screenshot and screencast utility for mangowm";
    homepage = "https://github.com/xtheeq/msnap";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "msnap";
  };
})
