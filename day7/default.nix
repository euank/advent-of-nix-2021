{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  data = fileContents ./input.lines;
  initState = sort lessThan (map toInt (splitString "," data));

  # For part 1, to minimize fuel, moving them all to the medium requires the fewest to move.
  # For example, say we have 3 crabs at 0 10 100. If we pick 10, the left + right have to move 100 total.
  # If we move one left, the left + right still have to move 100 total, but the 10 also has to move left now.
  # Same for the right.
  # This argument holds for a larger number too, regardless of the size of the gaps.
  median = elemAt initState ((length initState) / 2);
  part1Cost = foldl' builtins.add 0 (map (el: abs (el - median)) initState);

  # Part 2
  # The cost of going to a location is the sum of N numbers (n * (n + 1) / 2).
  # That gets expensive really quick. It seems plausible average will be right just because of that.
  # I'm less sure though.
  # For this one, I guess I'll programmatically find it since my math chops
  # aren't quite good enough to prove this to my satisfaction.

  # Calcualte the cost for a given location.
  sum_n = n: (n * n + n) / 2;
  cost = to: foldl' builtins.add 0 (map (el: sum_n (abs (el - to))) initState);

  # avg, just to start searching from
  avg = let sum = foldl' builtins.add 0 initState; len = length initState; in sum / len;

  # Given how it grows, there should be one global maximum, so we can just poke
  # left and right by one to verify we have the right answer.
  findVal = start:
    let
      cur = cost start;
      left = cost (start - 1);
      right = cost (start + 1);
    in
      if left > cur && right > cur then start
      else if left < cur then findVal left
      else findVal right;
in
{
  part1 = part1Cost;
  part2 = cost (findVal avg);
}
