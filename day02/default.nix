{ pkgs, ... }:
with pkgs;
let
  toStep = line:
    let
      parts = (lib.splitString " " line);
      dir = lib.head parts;
      num = lib.pipe parts [ lib.tail lib.head lib.toInt ];
    in
    { inherit dir num; };
  steps = builtins.map toStep (lib.splitString "\n" (lib.fileContents ./input.lines));

  part1Apply = acc: step:
    if step.dir == "forward" then acc // { x = acc.x + step.num; }
    else if step.dir == "down" then acc // { depth = acc.depth + step.num; }
    else if step.dir == "up" then acc // { depth = acc.depth - step.num; }
    else throw "error";

  part2Apply = acc: step:
    if step.dir == "forward" then acc // { x = acc.x + step.num; depth = acc.depth + acc.aim * step.num; }
    else if step.dir == "down" then acc // { aim = acc.aim + step.num; }
    else if step.dir == "up" then acc // { aim = acc.aim - step.num; }
    else throw "error";

  answer1 = lib.foldl part1Apply { x = 0; depth = 0; } steps;
  answer2 = lib.foldl part2Apply { x = 0; depth = 0; aim = 0; } steps;
in
{
  part1 = answer1.x * answer1.depth;
  part2 = answer2.x * answer2.depth;
}
