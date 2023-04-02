{
  description = "moxxmpp";
  inputs = {
    nixpkgs.url = "github:AtaraxiaSjel/nixpkgs/update/flutter";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs {
      inherit system;
      config = {
        android_sdk.accept_license = true;
        allowUnfree = true;
      };
    };
    unstable = import nixpkgs-unstable {
      inherit system;
    };
    android = pkgs.androidenv.composeAndroidPackages {
      # TODO: Find a way to pin these
      #toolsVersion = "26.1.1";
      #platformToolsVersion = "31.0.3";
      #buildToolsVersions = [ "31.0.0" ];
      #includeEmulator = true;
      #emulatorVersion = "30.6.3";
      platformVersions = [ "28" ];
      includeSources = false;
      includeSystemImages = true;
      systemImageTypes = [ "default" ];
      abiVersions = [ "x86_64" ];
      includeNDK = false;
      useGoogleAPIs = false;
      useGoogleTVAddOns = false;
    };
    pinnedJDK = pkgs.jdk17;

    pythonEnv = pkgs.python3.withPackages (ps: with ps; [
      pyyaml
      requests
    ]);

    moxxmppPubCache = import ./nix/pubcache.moxxmpp.nix {
      inherit (pkgs) fetchzip runCommand;
    };
  in {
    packages = {
      moxxmppDartDocs = pkgs.callPackage ./nix/moxxmpp-docs.nix {
        inherit (moxxmppPubCache) pubCache;
      };
    };

    devShell = let
      prosody-newer-community-modules = unstable.prosody.overrideAttrs (old: {
        communityModules = pkgs.fetchhg {
          url = "https://hg.prosody.im/prosody-modules";
          rev = "e3a3a6c86a9f";
          sha256 = "sha256-C2x6PCv0sYuj4/SroDOJLsNPzfeNCodYKbMqmNodFrk=";
        };

        src = pkgs.fetchhg {
          url = "https://hg.prosody.im/trunk";
          rev = "8a2f75e38eb2";
          sha256 = "sha256-zMNp9+wQ/hvUVyxFl76DqCVzQUPP8GkNdstiTDkG8Hw=";
        };
      });
      prosody-sasl2 = prosody-newer-community-modules.override {
        withCommunityModules = [
          "sasl2" "sasl2_fast" "sasl2_sm" "sasl2_bind2"
        ];
      };
    in pkgs.mkShell {
      buildInputs = with pkgs; [
        flutter pinnedJDK android.platform-tools dart # Dart
	      gitlint # Code hygiene
	      ripgrep # General utilities 

        # Flutter dependencies for Linux desktop
        atk
        cairo
        clang
        cmake
        epoxy
        gdk-pixbuf
        glib
        gtk3
        harfbuzz
        ninja
        pango
        pcre
        pkg-config
        xorg.libX11
        xorg.xorgproto

        # For the scripts in ./scripts/
        pythonEnv

        # For integration testing against a local prosody server
        prosody-sasl2
        mkcert
      ];

      CPATH = "${pkgs.xorg.libX11.dev}/include:${pkgs.xorg.xorgproto}/include";
      LD_LIBRARY_PATH = with pkgs; lib.makeLibraryPath [ atk cairo epoxy gdk-pixbuf glib gtk3 harfbuzz pango ];

      JAVA_HOME = pinnedJDK;
    };
  });
}
