{
  description = "A very basic flake";

  outputs = { self, nixpkgs }: rec {
    pkgs = nixpkgs;
    lib = import ./lib.nix { inherit pkgs; };

    day01 = import ./day01 { inherit pkgs; };
    day02 = import ./day02 { inherit pkgs; };
    day03 = import ./day03 { inherit lib pkgs; };
    day04 = import ./day04 { inherit lib pkgs; };
    day05 = import ./day05 { inherit lib pkgs; };
    day06 = import ./day06 { inherit lib pkgs; };
    day07 = import ./day07 { inherit lib pkgs; };
    day08 = import ./day08 { inherit lib pkgs; };
    day09 = import ./day09 { inherit lib pkgs; };
    day10 = import ./day10 { inherit lib pkgs; };
    day11 = import ./day11 { inherit lib pkgs; };
  };
}
