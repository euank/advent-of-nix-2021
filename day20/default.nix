{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  getData = filename:
    let
      parseImage = dat: map (s: map (c: if c == "." then 0 else 1) (stringToCharacters s)) (splitString "\n" dat);
      data = fileContents filename;
      parts = splitString "\n\n" data;
      lookup = map (c: if c == "." then 0 else 1) (stringToCharacters (head parts));
      image = parseImage (elemAt parts 1);
    in
    { inherit image lookup; inf = 0; };

  expandImage = data:
    let
      width = length (head data.image);
      height = length data.image;
      newWidth = width + 2;
      newHeight = height + 2;
      infRow = genList (_: data.inf) newWidth;
    in
    data // ({ image = [ infRow ] ++ (map (r: [ data.inf ] ++ r ++ [ data.inf ]) data.image) ++ [ infRow ]; });

  # Get the requisite 9 pixels, convert to binary, perform lookup
  pointVal = data: x: y:
    let
      cmp = lhs: rhs: if lhs.y == rhs.y then lhs.x < rhs.x else lhs.y < rhs.y;
      coords = sort cmp (cartesianProductOfSets { x = range (x - 1) (x + 1); y = range (y - 1) (y + 1); });
      bits = map (p: get2dArrDef data.image p.x p.y data.inf) coords;
      num = fromBinaryBits bits;
    in
    elemAt data.lookup num;

  applyStep = data:
    let
      # Always expand the borders by 1 on all edges so we have space for the image growing.
      # It never grows by more than 1
      data' = expandImage data;
      img = data'.image;
      width = length (head img);
      height = length img;
      # if the 0th lookup element is '1' then the infinite image expanse toggles to 1 and back each time.
      infSwaps = if (head data.lookup) == 1 && (elemAt data.lookup 511) == 0 then true else if (head data.lookup) == 1 then throw "infinite doesn't toggle, more complex cycle" else false;
      coordsToUpdate = cartesianProductOfSets { x = (range 0 (width - 1)); y = (range 0 (height - 1)); };
    in
    { image = foldl' (img: p: set2dArr img p.x p.y (pointVal data' p.x p.y)) img coordsToUpdate; lookup = data.lookup; inf = if infSwaps then 1 - data.inf else data.inf; };

  countPixels = img:
    foldl' builtins.add 0 (map (r: foldl' builtins.add 0 r) img);

  part1Answer = filename:
    let
      data = getData filename;
      # Pre-expand since we want an extra border.
      data' = expandImage data;
      applied = applyN 2 applyStep data';
    in
    countPixels applied.image;

  # part2
  # Note: this completes, but is slow
  # I suspect we could memoize in order to make this fast (i.e. in `pointVal`,
  # go to `pointValAfterSteps` and memoize that i.e. a grid of '0101110101'
  # goes to '1' after 50 steps or such.
  # But, hey, 10 minutes isn't the end of the world. I'll take the answer and move on.
  part2Answer = filename:
    let
      data = getData filename;
      data' = expandImage data;
      applied = applyN 50 applyStep data';
    in
    countPixels applied.image;
in
rec {
  part1 = part1Answer ./input.lines;
  part2 = part2Answer ./input.lines;
}
