{ pkgs }:
with pkgs;
let
  lines = builtins.map lib.toInt (lib.splitString "\n" (lib.fileContents ./input.lines));
  res = lib.foldl (a: b: { prev = b; count = a.count + (if b > a.prev then 1 else 0);}) ({count = 0; prev = (lib.head lines);}) lines;
in
  res.count
