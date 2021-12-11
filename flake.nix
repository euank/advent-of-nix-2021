{
  description = "A very basic flake";

  outputs = { self, nixpkgs }: rec {
    pkgs = nixpkgs;
    lib = import ./lib.nix { inherit pkgs; };

    day1 = import ./day1 { inherit pkgs; };
    day2 = import ./day2 { inherit pkgs; };
    day3 = import ./day3 { inherit lib pkgs; };
    day4 = import ./day4 { inherit lib pkgs; };
    day5 = import ./day5 { inherit lib pkgs; };
    day6 = import ./day6 { inherit lib pkgs; };
    day7 = import ./day7 { inherit lib pkgs; };
    day8 = import ./day8 { inherit lib pkgs; };
    day9 = import ./day9 { inherit lib pkgs; };
    day10 = import ./day10 { inherit lib pkgs; };
  };
}
