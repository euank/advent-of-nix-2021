{ pkgs, lib }:
with pkgs.lib;
with lib;
let
  lines = splitString "\n" (fileContents ./input.lines);
  # All lines are the same length, just use the first one arbitrarily
  numBytes = stringLength (head lines);

  nums = map fromBinary lines;
  # It feels like there's a fancier way to figure out "multiple of a number and
  # its complement", but I don't have it offhand.  Let's do it how the problem
  # naively suggests and just count bits in positions.

  counts = genList (_: 0) numBytes;

  addCounts = counts: n: imap1 (i: count: if (bitSet n (numBytes - i)) then count + 1 else count - 1) counts;
  bitCounts = foldl' addCounts counts nums;

  # And construct a number from the bitCounts, as well as its complement
  bitCountsAsBits = concatMapStrings (bit: if bit > 0 then "1" else "0") bitCounts;
  bitCountsAsBits' = concatMapStrings (bit: if bit > 0 then "0" else "1") bitCounts;

  # Part 2 stuff now
in
{
  part1 = (fromBinary bitCountsAsBits) * (fromBinary bitCountsAsBits');
}
