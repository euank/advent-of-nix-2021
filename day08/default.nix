{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  data = fileContents ./input.lines;
  rawLines = splitString "\n" data;

  parseLine = l: let parts = splitString " | " l; in { input = splitString " " (head parts); output = splitString " " (elemAt parts 1); };
  lines = map parseLine rawLines;

  segments = {
    "0" = "abcefg"; # len 6
    "1" = "cf"; # len 2
    "2" = "acdeg"; # len 5
    "3" = "acdfg"; # len 5
    "4" = "bcdf"; # len 4
    "5" = "abdfg"; # len 5
    "6" = "abdefg"; # len 6
    "7" = "acf"; # len 3
    "8" = "abcdefg"; # len 7
    "9" = "abcdfg"; # len 6
  };
  segmentToInt = mapAttrs' (k: v: nameValuePair v (toInt k)) segments;

  # part 1
  outputs = map (l: l.output) lines;

  # Outputs that have the length of 1/4/7/8
  searchLens = [
    (stringLength segments."1")
    (stringLength segments."4")
    (stringLength segments."7")
    (stringLength segments."8")
  ];
  numOutputs = foldl' (acc: v: if (elem (stringLength v) searchLens) then acc + 1 else acc) 0 (flatten outputs);

  # part 2
  # We actually have to decode now, but this _should_ be easy.
  # The puzzle, in my head, looks like so:
  # 1. Find 1/4/7 as "gimmes" per above. 8 is useless, ignore it
  # 1. Find the top line ('a') by subtracting the chars of 1 from 7.
  # 2. Find 3 - it'll be the only len=5 string that contains both '1' characters
  # 3. Find the bottom line ('g') by subtracting 7 and 4 from 3. We now have 'g'
  # 4. Find the middle line ('d') by subtracting 7 and 'g' from 3.
  # 5. Find 6 - it'll be len 6 and _not_ have both of 1's characters
  # 6. Intersect 6 with 1 to get 'f'.
  # 7. Remove 'f' from 1 to get 'c'
  # 8. Find 5, remove agdf to get 'b'
  # 9. Whatever letter we don't have yet is 'e'. All done
  #
  # So now to code this up. :|

  decodeLine = line:
    let
      # Turn the inputs into arrays of chars, it'll be easier to do intersection/subtraction/etc that way.
      inputs = map stringToCharacters line.input;
      eq = x: y: x == y;
      one = findSingle (el: (length el) == 2) null null inputs;
      four = findSingle (el: (length el) == 4) null null inputs;
      seven = findSingle (el: (length el) == 3) null null inputs;
      a = head (subtractLists one seven);
      three = findSingle (el: ((length el) == 5) && (containsAll eq el one)) null null inputs;
      g = head (subtractLists (four ++ seven) three);
      d = head (subtractLists (seven ++ [ g ]) three);
      six = findSingle (el: ((length el) == 6) && (length (intersectLists el one)) == 1) null null inputs;
      f = head (intersectLists six one);
      c = head (subtractLists [ f ] one);
      five = findSingle (el: ((length el) == 5) && (containsAll eq el [ f ]) && ! (containsAll eq el [ c ])) null null inputs;
      b = head (subtractLists [ a g d f ] five);
      e = head (subtractLists five six);

      lookup = {
        inherit a b c d e f g;
      };
      inverseLookup = mapAttrs' (k: v: nameValuePair v k) lookup;
      decodeStr = str:
        let
          chars = stringToCharacters str;
          origChars = map (c: inverseLookup."${c}") chars;
          segmentParts = map (c: inverseLookup."${c}") chars;
          segment = concatStrings (sort lessThan segmentParts);
        in
        segmentToInt."${segment}";
      outputNums = map decodeStr line.output;
    in
    toInt (removePrefixAll "0" (concatMapStrings (n: toString n) outputNums));

  # And finally, the part2 answer
  total = foldl' builtins.add 0 (map decodeLine lines);
in
{
  part1 = numOutputs;
  part2 = total;
}
