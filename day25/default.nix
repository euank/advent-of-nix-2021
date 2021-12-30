{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  getData = filename:
    let
      data = fileContents filename;
      lines = splitString "\n" data;
      board = map stringToCharacters lines;
    in
    board;

  get2dArrWrapping = arr: x: y:
    let
      height = length arr;
      width = length (head arr);
    in
    if x < 0 then get2dArrWrapping arr (width + x) y
    else if y < 0 then get2dArrWrapping arr x (height + y)
    else get2dArr arr (mod x width) (mod y height);

  doStep = board:
    let
      height = length board;
      width = length (head board);
      cellValEast = b: x: y:
        let
          cell = get2dArr b x y;
          right = get2dArrWrapping b (x + 1) y;
          left = get2dArrWrapping b (x - 1) y;
        in
        # Our element moves right
        if cell == ">" && right == "." then "."
        # The element left of us moves into us
        else if cell == "." && left == ">" then ">"
        # Nothing happens eastward.
        else cell;
      steppedEast = genList (y: genList (x: cellValEast board x y) width) height;

      cellValSouth = b: x: y:
        let
          cell = get2dArr b x y;
          up = get2dArrWrapping b x (y - 1);
          down = get2dArrWrapping b x (y + 1);
        in
        if cell == "v" && down == "." then "."
        else if cell == "." && up == "v" then "v"
        # Nothing happens eastward.
        else cell;

      steppedSouth = genList (y: genList (x: cellValSouth steppedEast x y) width) height;
    in
    steppedSouth;

  boardsEqual = lhs: rhs:
    let
      compareRow = lhs: rhs: compareLists compare lhs rhs;
    in
    (compareLists compareRow lhs rhs) == 0;

  numStepsToConverge = board:
    let
      count' = n: board:
        let
          nb = doStep board;
        in
        if boardsEqual nb board then n
        else count' (n + 1) nb;
    in
    count' 1 board;


  part1Answer = filename: numStepsToConverge (getData filename);
in
{
  part1 = part1Answer ./input.lines;
}
