{ pkgs, lib }:
with pkgs.lib;
with lib;
let
  lines = splitString "\n" (fileContents ./input.lines);
  # All lines are the same length, just use the first one arbitrarily
  numBits = stringLength (head lines);

  nums = map fromBinary lines;
  # It feels like there's a fancier way to figure out "multiple of a number and
  # its complement", but I don't have it offhand.  Let's do it how the problem
  # naively suggests and just count bits in positions.

  counts = genList (_: 0) numBits;

  addCounts = counts: n: imap1 (i: count: if (bitSet n (numBits - i)) then count + 1 else count - 1) counts;
  bitCounts = foldl' addCounts counts nums;

  # And construct a number from the bitCounts, as well as its complement
  bitCountsAsBits = concatMapStrings (bit: if bit > 0 then "1" else "0") bitCounts;
  bitCountsAsBits' = concatMapStrings (bit: if bit > 0 then "0" else "1") bitCounts;

  # Part 2 stuff now
  mostCommonBit = nums: pos:
    let
      bitBoolList = map (el: bitSet el pos) nums;
      counts = partition id bitBoolList;
    in
    if (length counts.right) >= (length counts.wrong) then 1 else 0;

  oxygenGeneratorRating =
    let
      answer = candidates: pos:
        if (length candidates) == 1 then (head candidates)
        else if pos == -1 then throw "Ran outta bits with no answer"
        else
          let
            curBit = mostCommonBit candidates pos;
            nextCandidates = filter (c: curBit == (if (bitSet c pos) then 1 else 0)) candidates;
          in
          (answer nextCandidates (pos - 1));
    in
    (answer nums (numBits - 1));

  co2ScrubberRating =
    let
      answer = candidates: pos:
        if (length candidates) == 1 then head candidates
        else if pos == -1 then throw "Ran outta bits with no answer"
        else
          let
            curBit = if (mostCommonBit candidates pos) == 1 then 0 else 1;
            nextCandidates = filter (c: curBit == (if (bitSet c pos) then 1 else 0)) candidates;
          in
          answer nextCandidates (pos - 1);
    in
    answer nums (numBits - 1);


in
{
  part1 = (fromBinary bitCountsAsBits) * (fromBinary bitCountsAsBits');
  part2 = oxygenGeneratorRating * co2ScrubberRating;
}
