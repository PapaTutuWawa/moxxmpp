{
  description = "moxxmpp";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, android-nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem (system: let
     pkgs = import nixpkgs {
      inherit system;
      config = {
        android_sdk.accept_license = true;
        allowUnfree = true;
      };
    };
    # Everything to make Flutter happy
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
    lib = pkgs.lib;
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
      prosody-newer-community-modules = pkgs.prosody.overrideAttrs (old: {
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

      ANDROID_SDK_ROOT = "${android.androidsdk}/share/android-sdk";
      ANDROID_HOME = "${android.androidsdk}/share/android-sdk";
      JAVA_HOME = pinnedJDK;

      # Fix an issue with Flutter using an older version of aapt2, which does not know
      # an used parameter.
      GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${android.androidsdk}/share/android-sdk/build-tools/34.0.0/aapt2";
    };

    apps = {
      regenerateNixPackage = let
        script = pkgs.writeShellScript "regenerate-nix-package.sh" ''
          set -e
          ${pythonEnv}/bin/python ./scripts/pubspec2lock.py ./packages/moxxmpp/pubspec.lock ./nix/moxxmpp.lock
          ${pythonEnv}/bin/python ./scripts/lock2nix.py ./nix/moxxmpp.lock ./nix/pubcache.moxxmpp.nix moxxmpp
        '';
      in {
        type = "app";
        program = "${script}";
      };
    };
  });
}
