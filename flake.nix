{
  description = "A very basic flake";

  outputs = { self, nixpkgs }:
  let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
    };
    dayDirs = pkgs.lib.filterAttrs (name: _: pkgs.lib.hasPrefix "day" name) (builtins.readDir ./.);
    lib = import ./lib.nix { inherit pkgs; };
  in
  rec {
    inherit pkgs lib;

    bench = import ./bench { inherit pkgs lib; };

  } // (pkgs.lib.mapAttrs (name: _: import ./${name} { inherit pkgs lib; }) dayDirs);
}
