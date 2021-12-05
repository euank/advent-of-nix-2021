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
  };
}
