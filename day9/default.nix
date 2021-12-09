{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  data = fileContents ./input.lines;
  chars = map stringToCharacters (splitString "\n" data);
  gridLines = map (line: map toInt line) chars;
  width = length (head gridLines);
  height = length gridLines;
  grid = {
    data = gridLines;
    inherit width height;
  };

  gridContains = grid: x: y:
    if x < 0 || x >= grid.width then false
    else if y < 0 || y >= grid.height then false
    else true;

  getPoint = grid: x: y: default:
    if ! (gridContains grid x y) then default
    else (elemAt (elemAt grid.data y) x);


  # Get all candidate coordinates
  coords = cartesianProductOfSets { x = range 0 (width - 1); y = range 0 (height - 1); };

  # Filter down to min points
  isMinPoint = grid: x: y:
    let
      val = getPoint grid x y null;
      lval = getPoint grid (x - 1) y 9;
      rval = getPoint grid (x + 1) y 9;
      uval = getPoint grid x (y - 1) 9;
      dval = getPoint grid x (y + 1) 9;
    in
      val < lval && val < rval && val < uval && val < dval;

  minPoints = grid: coords: filter (p: isMinPoint grid p.x p.y) coords;

  minPointVals = grid: points: map (p: (getPoint grid p.x p.y null) + 1) points;
in
{
  part1 = foldl' builtins.add 0 (minPointVals grid (minPoints grid (minPoints grid coords)));
}
