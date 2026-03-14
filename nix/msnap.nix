{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
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
stdenvNoCC.mkDerivation rec {
  pname = "msnap";
  version = "0.2.1";
  src = fetchFromGitHub {
    owner = "atheeq-rhxn";
    repo = "msnap";
    rev = "v${version}";
    hash = "sha256-Qf5YTk9md2BkLJ58fRby/XBuqyBh7GlC0/kc1ppcen8=";
  };
  nativeBuildInputs = [ makeWrapper ];
  dontConfigure = true;
  buildPhase = ''
    make build \
      PREFIX="$out" \
      BINDIR="$out/bin" \
      DATADIR="$out/share" \
      SYSCONFDIR="$out/etc/xdg"
  '';
  installPhase = ''
    make install \
      PREFIX="$out" \
      BINDIR="$out/bin" \
      DATADIR="$out/share" \
      SYSCONFDIR="$out/etc/xdg" \
      DESTDIR=""
    substituteInPlace "$out/bin/msnap" \
      --replace-fail '#!/usr/bin/env bash' '#!${bash}/bin/bash'
    wrapProgram "$out/bin/msnap" \
      --prefix PATH : ${lib.makeBinPath [
        grim
        slurp
        wl-clipboard
        libnotify
        wayfreeze
        satty
        gpu-screen-recorder
        ffmpeg
        quickshell
      ]}
  '';
  meta = {
    description = "Screenshot and screencast utility for mangowm";
    homepage = "https://github.com/atheeq-rhxn/msnap";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    platforms = lib.platforms.linux;
    mainProgram = "msnap";
  };
}
