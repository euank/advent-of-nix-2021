{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  lines = fileContents ./input.lines;
  linesParts = splitString "\n" lines;
in
{
}
