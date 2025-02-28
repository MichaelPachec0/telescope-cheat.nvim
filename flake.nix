{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
  };
  outputs = {
    self,
    systems,
    nixpkgs,
  }: let
    # NOTE: compose a function that will take a function over each system target
    eachSystem = nixpkgs.lib.genAttrs (import systems);

    # NOTE: Builds each nixpkgs target using the eachSystem function
    pkgsFor = eachSystem (system:
      import nixpkgs {
        localSystem = system;
        overlays = with self.overlays; [
          default
        ];
      });
  in {
    overlays = {
      default = final: prev: {
        vimPlugins =
          prev.vimPlugins
          // {
            telescope-cheat-nvim = prev.vimPlugins.telescope-cheat-nvim.overrideAttrs (old: {
              src = ./.;
            });
          };
      };
    };
    # NOTE: does the same for packages, this outputs a package for every target supported by nixpkgs
    packages = eachSystem (system: {
      inherit
        (pkgsFor.${system}.vimPlugins)
        telescope-cheat-nvim
        ;
    });
    # TODO: there is some interesting stuff with precommit hooks (https://github.com/cachix/pre-commit-hooks.nix) that i want to incorporate.
    # TODO: implement devshell
    devShells = eachSystem (system: {
      default =
        pkgsFor.${system}.mkShell.override {
        } {
          name = "test-shell";
        };
    });
  };
}
