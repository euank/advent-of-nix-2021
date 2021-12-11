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

  # set2dArr returns a new array with the same elements as 'arr', except for 'x,y' being set to 'val'.
  # The array is interpreted such a 2x4 array would have x,y values refer to the following elements:
  # [ [ "0,0" "1,0" ]
  #   [ "0,1" "1,1" ]
  #   [ "0,2" "1,2" ]
  #   [ "0,3" "1,3" ] ]
  set2dArr = arr: x: y: val:
    let
      toY = sublist 0 y arr;
      elY = elemAt arr y;
      afterY = sublist (y + 1) ((length arr) - (y + 1)) arr;
      toX = sublist 0 x elY;
      afterX = sublist (x  + 1) ((length elY) - (x + 1)) elY;
    in
      toY ++ [ (toX ++ [ val ] ++ afterX) ] ++ afterY;
}
