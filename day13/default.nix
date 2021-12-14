{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  data = fileContents ./input.lines;
  parts = splitString "\n\n" data;
  coordParts = splitString "\n" (elemAt parts 0);
  foldParts = splitString "\n" (elemAt parts 1);

  parseFold = line:
  let
    kv = removePrefix "fold along " line;
    parts = splitString "=" kv;
  in
    { axis = elemAt parts 0; n = toInt (elemAt parts 1); };

  parseCoord = coord:
  let
    parts = splitString "," coord;
  in
    { x = toInt (elemAt parts 0); y = toInt (elemAt parts 1); };

  coords = map parseCoord coordParts;
  folds = map parseFold foldParts;

  board = coords:
    let
      maxX = foldl' max 0 (map (p: p.x) coords);
      maxY = foldl' max 0 (map (p: p.y) coords);
      zeroBoard = genList (_: genList (_: 0) (maxX + 1)) (maxY + 1);
    in
    foldl' (acc: c: set2dArr acc c.x c.y 1) zeroBoard coords;

  getHeight = board: length board;
  getWidth = board: length (head board);

  rotateRight = board:
  let
    w = getWidth board;
    h = getHeight board;
  in
    genList (x: genList (y: get2dArr board x (h - y - 1)) (h)) (w);
  rotateLeft = board: rotateRight (rotateRight (rotateRight board));

  mirror = board:
  let
    w = getWidth board;
    h = getHeight board;
  in
    genList (y: genList (x: get2dArrDef board x (h - y - 1) 0) w) h;

  mergeBoards = lhs: rhs:
  let
    w = getWidth lhs;
    h = getHeight rhs;
  in
    genList (y: genList (x: max (get2dArrDef lhs x y 0) (get2dArrDef rhs x y 0)) w) h;

  doFold = board: fold:
  # So we only have to code one fold, rotate the board and fold along y for x folds.
  # It should be the same, and rotating the board is inefficient, but feels nicer than coding fold twice.
  if fold.axis == "x" then rotateLeft (doFold (rotateRight board) { axis = "y"; n = fold.n; })
  else
  let
    h = getHeight board;
    topHalf = sublist 0 fold.n board;
    bottomHalf = sublist (fold.n + 1) (h - fold.n - 1) board;
  in
    mergeBoards topHalf (mirror bottomHalf);

  countDots = board:
    foldl' builtins.add 0 (flatten board);

  prettyPrintBoard = board: concatStringsSep "\n" (map (l: concatStrings (map (c: if c == 0 then " " else "#") l)) board);
in
rec {
  part1 = countDots (doFold (board coords) (head folds));
  part2 = prettyPrintBoard (foldl' (board: fold: doFold board fold) (board coords) folds);
}
