{
    description = "Nvsleepify port to NixOS";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        flake-utils.url = "github:numtide/flake-utils";
    };

    outputs = { self, nixpkgs, flake-utils }:
        flake-utils.lib.eachDefaultSystem (system:
            let
                pkgs = nixpkgs.legacyPackages.${system};
                stdenv = pkgs.stdenv;
            in {
                packages.default = pkgs.rustPlatform.buildRustPackage {
                    pname = "nvsleepify";
                    version = "1.0.0";
                    src = pkgs.fetchFromGitHub {
                        owner = "JuanDelPueblo";
                        repo = "nvsleepify";
                        rev = "16b61842580a0c059b8dc5da8e09b9bcf02d9101";
                        sha256 = "sha256-vbV4dGxlYLTLHDCwt02n+JjQp3Rm/NYISQPs+ICxSqo=";
                    };
                    cargoHash = "sha256-f8E58+lT+4RqqUnsRg3m3f43ONHmOfCq8qV21qicL1I=";
                    nativeBuildInputs = with pkgs; [ makeWrapper ];
                    cargoBuildFlags = [ "--bins" ];
                    installPhase = ''
                        install -Dm755 $(find target -type f -name nvsleepify) $out/bin/nvsleepify
                        install -Dm755 $(find target -type f -name nvsleepifyd) $out/bin/nvsleepifyd
                        install -Dm755 $(find target -type f -name nvsleepify-tray) $out/bin/nvsleepify-tray
                        install -Dm644 org.nvsleepify.conf $out/share/dbus-1/system.d/nvsleepify.conf

                        install -Dm644 nvsleepify-tray.desktop $out/share/applications/nvsleepify-tray.desktop
                        install -Dm644 icons/nvsleepify-gpu-active.svg $out/share/icons/hicolor/scalable/apps/nvsleepify-gpu-active.svg
                        install -Dm644 icons/nvsleepify-gpu-suspended.svg $out/share/icons/hicolor/scalable/apps/nvsleepify-gpu-suspended.svg
                        install -Dm644 icons/nvsleepify-gpu-off.svg $out/share/icons/hicolor/scalable/apps/nvsleepify-gpu-off.svg
                        $(find target -type f -name nvsleepify) completion bash > nvsleepify || true
                        $(find target -type f -name nvsleepify) completion zsh > _nvsleepify || true
                        $(find target -type f -name nvsleepify) completion fish > nvsleepify.fish || true
                        install -Dm644 nvsleepify $out/share/bash-completion/completions/nvsleepify || true
                        install -Dm644 _nvsleepify $out/share/zsh/site-functions/_nvsleepify || true
                        install -Dm644 nvsleepify.fish $out/share/fish/vendor_completions.d/nvsleepify.fish || true
                        mkdir -p $out/share/dbus-1/system-services
                        cat > $out/share/dbus-1/system-services/org.nvsleepify.Service.service << EOF
                        [D-BUS Service]
                        Name=org.nvsleepify.Service
                        Exec=${placeholder "out"}/bin/nvsleepifyd
                        User=root
                        SystemdService=nvsleepifyd.service
                        EOF
                    '';
                    meta.mainProgram = "nvsleepify";
                    postInstall = ''
                        wrapProgram $out/bin/nvsleepifyd --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.lsof ]}
                    '';
                };
            }
        ) // {
            nixosModules.default = { config, lib, pkgs, ... }:
                let
                    cfg = config.services.nvsleepify;
                in {
                    options.services.nvsleepify = {
                        enable = lib.mkEnableOption "nvidia dGPU control daemon for Asus Zephyrus Laptops";
                        package = lib.mkOption {
                            type = lib.types.package;
                            default = pkgs.nvsleepify;
                            description = "nvsleepify package for usage in daemon";
                        };
                    };
                    config = lib.mkIf cfg.enable {
                        environment.systemPackages = [ pkgs.nvsleepify ];
                        systemd.packages = [ pkgs.nvsleepify ];
                        systemd.services.nvsleepifyd = {
                            description = "nvsleeipify GPU daemon";
                            wantedBy = [ "multi-user.target" ];
                            after = [ "dbus.service" ];
                            serviceConfig = {
                                ExecStart = "${cfg.package}/bin/nvsleepifyd";
                                Restart = "on-failure";
                                User = "root";
                            };
                        };
                        services.dbus.packages = [ pkgs.nvsleepify ];
                    };
                };
                overlays.default = final: prev: {
                    nvsleepify = self.packages.${final.system}.default;
                };
            };
}