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
    sdk = android-nixpkgs.sdk.${system} (sdkPkgs: with sdkPkgs; [
      cmdline-tools-latest
      build-tools-30-0-3
      build-tools-33-0-2
      build-tools-34-0-0
      platform-tools
      emulator
      patcher-v4
      platforms-android-28
      platforms-android-29
      platforms-android-30
      platforms-android-31
      platforms-android-33
    ]);
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
        flutter37 pinnedJDK sdk dart # Dart
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

      ANDROID_SDK_ROOT = "${sdk}/share/android-sdk";
      ANDROID_HOME = "${sdk}/share/android-sdk";
      JAVA_HOME = pinnedJDK;

      # Fix an issue with Flutter using an older version of aapt2, which does not know
      # an used parameter.
      GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${sdk}/share/android-sdk/build-tools/34.0.0/aapt2";
    };
  });
}
