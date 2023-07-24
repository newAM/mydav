{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    crane.url = "github:ipetkov/crane";
    crane.inputs.nixpkgs.follows = "nixpkgs";

    advisory-db.url = "github:rustsec/advisory-db";
    advisory-db.flake = false;
  };

  outputs = {
    self,
    advisory-db,
    nixpkgs,
    crane,
  }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    craneLib = crane.lib.x86_64-linux;

    src = craneLib.cleanCargoSource self;

    cargoArtifacts = craneLib.buildDepsOnly {inherit src;};
  in {
    packages.x86_64-linux.default =
      craneLib.buildPackage
      {
        inherit cargoArtifacts src;
      };

    overlays.default = final: prev: {
      mydav = self.packages.${prev.system}.default;
    };
    nixosModules.default = import ./module.nix;

    checks.x86_64-linux = let
      nixSrc = nixpkgs.lib.sources.sourceFilesBySuffices self [".nix"];
    in {
      pkg = self.packages.x86_64-linux.default;

      audit = craneLib.cargoAudit {
        inherit src advisory-db;
      };

      clippy = craneLib.cargoClippy {
        inherit cargoArtifacts src;
        cargoClippyExtraArgs = "-- --deny warnings";
      };

      rustfmt = craneLib.cargoFmt {inherit src;};

      alejandra = pkgs.runCommand "alejandra" {} ''
        ${pkgs.alejandra}/bin/alejandra --check ${nixSrc}
        touch $out
      '';

      statix = pkgs.runCommand "statix" {} ''
        ${pkgs.statix}/bin/statix check ${nixSrc}
        touch $out
      '';
    };
  };
}
