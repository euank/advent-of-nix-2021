{ pkgs }:
with pkgs;
let
  lines = builtins.map lib.toInt (lib.splitString "\n" (lib.fileContents ./input.lines));
  countIncreasing = nums:
    let
      x = lib.foldl (a: b: { prev = b; count = a.count + (if b > a.prev then 1 else 0); }) ({ count = 0; prev = (lib.head nums); }) nums;
    in
    x.count;
  windowSums = lines: lib.zipListsWith (a: b: a + b) (lib.zipListsWith (a: b: a + b) lines (lib.tail lines)) (lib.tail (lib.tail lines));

in
{
  part1 = countIncreasing lines;
  part2 = countIncreasing (windowSums lines);
}
