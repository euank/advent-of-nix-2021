
{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  data = fileContents ./input.lines;
  initState = map toInt (splitString "," data);

  median = elemAt ((length initState) / 2) initState;

  part1Cost = map (el: abs (el - median)) initState;
in
{
  part1 = part1Cost;
}
