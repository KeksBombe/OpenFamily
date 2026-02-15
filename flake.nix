{
  description = "Go (Swagger) backend + Flutter frontend + Android emulator dev shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true; # Android SDK ist unfree
          };
        };

        # Android SDK/Tools + Emulator via androidenv
        androidSdk = pkgs.androidenv.composeAndroidPackages {
          toolsVersion = "26.1.1";
          platformToolsVersion = "35.0.2";
          buildToolsVersions = [ "35.0.0" ];
          platformVersions = [ "35" ];
          emulatorVersion = "35.1.20";

          includeEmulator = true;
          includeSystemImages = true;
          systemImageTypes = [ "google_apis" ];
          abiVersions = [ "x86_64" ];

          # Optional, aber praktisch
          includeNDK = false;
          includeExtras = [
            "extras;google;gcm"
            "extras;google;m2repository"
            "extras;android;m2repository"
          ];
        };

        sdk = androidSdk.androidsdk;
      in
      {
        devShells.default = pkgs.mkShell {
          name = "go-swagger-flutter-android";

          packages = with pkgs; [
            # Go Backend
            go
            gopls
            delve
            golangci-lint

            # Swagger / OpenAPI tooling (du kannst beide nutzen)
            swagger-codegen
            openapi-generator-cli

            # Flutter / Dart
            flutter
            dart

            # Android SDK + Emulator
            sdk
            jdk17

            # Oft nötig für Emulator/Flutter tooling
            git
            unzip
            zip
            curl
            which
            file
          ];

          # Für Flutter + Android tooling
          ANDROID_HOME = "${sdk}/libexec/android-sdk";
          ANDROID_SDK_ROOT = "${sdk}/libexec/android-sdk";
          JAVA_HOME = "${pkgs.jdk17}/lib/openjdk";

          # Damit flutter/dart und adb zuverlässig gefunden werden
          shellHook = ''
            export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

            echo "✅ DevShell bereit:"
            echo "  - Go: $(go version 2>/dev/null || true)"
            echo "  - Flutter: $(flutter --version 2>/dev/null | head -n 1 || true)"
            echo "  - Android SDK: $ANDROID_HOME"
            echo
            echo "Tipps:"
            echo "  - Flutter Diagnose: flutter doctor -v"
            echo "  - AVD erstellen: avdmanager create avd -n pixel -k \"system-images;android-35;google_apis;x86_64\" --device \"pixel\""
            echo "  - Emulator starten: emulator -avd pixel"
          '';
        };
      }
    );
}
