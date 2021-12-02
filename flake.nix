{
  description = "A very basic flake";

  outputs = { self, nixpkgs }: {
    day1 = import ./day1 { pkgs = nixpkgs; };
    day2 = import ./day2 { pkgs = nixpkgs; };
  };
}
