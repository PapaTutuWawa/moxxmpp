{
  stdenv
, pubCache
, dart
, lib
}:

stdenv.mkDerivation {
  pname = "moxxmpp-docs";
  version = "0.3.1";

  PUB_CACHE = "${pubCache}";
  
  src = "${./..}/packages/moxxmpp";

  buildPhase = ''
    runHook preBuild

    (
    set -x
    echo $PUB_CACHE
    ${dart}/bin/dart pub get --no-precompile --offline
    )

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    ${dart}/bin/dart doc -o $out

    runHook postInstall
  '';
}
