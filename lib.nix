{ pkgs }:
with pkgs.lib;
rec {
  # Convert a binary representation of a string to an integer
  fromBinary = str: foldl' (acc: n: acc * 2 + n) 0 (map toInt (stringToCharacters str));

  bitSet = n: i: if i == 0 then (mod n 2) == 1 else bitSet (n / 2) (i - 1);

  splitStringWhitespace = s: pkgs.lib.flatten (builtins.filter builtins.isList (builtins.split "([^ ]+)" s));

  abs = x: if x < 0 then (-1) * x else x;

  containsAll = eq: xs: searches: all (el: any (eq el) xs) searches;

  removePrefixAll = prefix: str: if ! (hasPrefix prefix str) then str else removePrefixAll prefix (removePrefix prefix str);
}
