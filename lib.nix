{ pkgs }:
with pkgs.lib;
{
  # Convert a binary representation of a string to an integer
  fromBinary = str: foldl' (acc: n: acc * 2 + n) 0 (map toInt (stringToCharacters str));

  bitSet =
    let bitSet = n: i: if i == 0 then (mod n 2) == 1 else bitSet (n / 2) (i - 1);
    in bitSet;

  # I thought I needed these on day3, but I read the question wrong. Keeping em around just in case

  # The length of the prefix two lists share
  sharedPrefixLen =
    let
      f = acc: l1: l2:
        if (length l1) == 0 then acc
        else if (length l2) == 0 then acc
        else if (head l1) == (head l2) then f (acc + 1) (tail l1) (tail l2)
        else acc;
    in
    (f 0);

  # shared prefix length for strings
  sharedStrLen = s1: s2: sharedPrefixLen (stringToCharacters s1) (stringToCharacters s2);

}
