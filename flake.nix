{
  description = "moxxmpp";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-dart.url = "github:tadfisher/nix-dart";
  };

  outputs = { self, nixpkgs, flake-utils, nix-dart }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs {
      inherit system;
      config = {
        android_sdk.accept_license = true;
        allowUnfree = true;
      };

      overlays = [
        (prev: final: {
          pub2nix-lock = nix-dart.packages."${system}".pub2nix-lock;
          buildDartPackage = (nix-dart.overlay prev final).buildDartPackage;
        })
      ];
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
    pinnedJDK = pkgs.jdk;

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

    devShell = pkgs.mkShell {
      buildInputs = with pkgs; [
        flutter pinnedJDK android.platform-tools dart pub2nix-lock # Dart
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

        # Dev
        pythonEnv
      ];

      CPATH = "${pkgs.xorg.libX11.dev}/include:${pkgs.xorg.xorgproto}/include";
      LD_LIBRARY_PATH = with pkgs; lib.makeLibraryPath [ atk cairo epoxy gdk-pixbuf glib gtk3 harfbuzz pango ];

      JAVA_HOME = pinnedJDK;
    };
  });
}
