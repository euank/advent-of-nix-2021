{ pkgs }:
with pkgs.lib;
let
  lib = rec {
  # Convert a binary representation of a string to an integer
  fromBinary = str: fromBinaryBits (map toInt (stringToCharacters str));

  fromBinaryBits = bits: foldl' (acc: n: acc * 2 + n) 0 bits;

  bitSet = n: i: if i == 0 then (mod n 2) == 1 else bitSet (n / 2) (i - 1);

  splitStringWhitespace = s: pkgs.lib.flatten (builtins.filter builtins.isList (builtins.split "([^ ]+)" s));

  abs = x: if x < 0 then (-1) * x else x;

  sum = l: foldl' builtins.add 0 l;

  # x^n
  pow = x: n: if n == 1 then x else x * (pow x (n - 1));

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

  get2dArr = arr: x: y: elemAt (elemAt arr y) x;
  get2dArrDef = arr: x: y: def:
    if x < 0 || y < 0 then def
    else if y >= (length arr) then def
    else if x >= (length (elemAt arr y)) then def
    else elemAt (elemAt arr y) x;

  matches = regex: str: (builtins.match regex str) != null;

  swap = arr: i: j:
    builtins.genList (idx: let idx' = if idx == i then j else if idx == j then i else idx; in builtins.elemAt arr idx') (builtins.length arr);

  heap = import ./heap.nix { inherit pkgs lib; };
  heap2 = import ./heap2.nix { inherit pkgs lib; };

  graph = import ./graph.nix { inherit pkgs lib; };

  # splitUntil splits at list into two pieces, a piece before the predicate
  # returns true, and a piece after the predicate first returns true,
  # inclusive.
  # For example:
  #   splitUntil (el: el == 2) [ 0 1 2 3 4 5 6] # { fst = [ 0 1 ]; snd = [ 2 3 4 5 6 ]; }
  #   splitUnti (_: false) [ 0 1 2 ] # { fst = [ 0 1 2 ]; snd = []; }
  splitUntil = pred: list:
    let
      splitIdx = head (remove null (imap0 (i: c: if pred c then i else null) list));
    in
      {
        fst = sublist 0 splitIdx list;
        snd = sublist splitIdx ((length list) - splitIdx) list;
      };

  dotProduct = v1: v2:
  if (length v1) != (length v2) then throw "dot product requires equal length vectors"
  else foldl' builtins.add 0 (zipListsWith (x: y: x * y) v1 v2);

  matrixMult = matrix: vec: map (mrow: dotProduct mrow vec) matrix;

  applyN = n: f: init: foldl' (acc: _: f acc) init (range 1 n);
};
in lib
