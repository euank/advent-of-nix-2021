{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  parseField = filename:
    let
      data = fileContents filename;
      ranges = splitString ", " (elemAt (splitString ": " data) 1);
      parseRange = range:
      let
        parts = splitString "=" range;
        numParts = map toInt (splitString ".." (elemAt parts 1));
      in
        numParts;
      parsedRanges = map parseRange ranges;
      xs = elemAt parsedRanges 0;
      ys = elemAt parsedRanges 1;
    in
    rec {
      x = min (elemAt xs 0) (elemAt xs 1);
      y = min (elemAt ys 0) (elemAt ys 1);
      toX = max (elemAt xs 1) (elemAt xs 0);
      toY = max (elemAt ys 0) (elemAt ys 1);
      contains = point: point.x >= x && point.y >= y && point.x <= toX && point.y <= toY;
    };

  towardsZero = i: if i > 0 then i - 1 else if i < 0 then i + 1 else 0;

  # returns { h = maxHeight | null; terminal = true | unset; }
  # h is the max height, or null if it does not intersect.
  # Terminal is set if no velocity with a greater Y value will ever intersect.
  shootProbe = field: velocity:
  let
    shootProbe' = maxh: vel: pos:
    # Will never intersect w/ greater y since we immediately drop below it after returning to '0'.
    if pos.y == 0 && (abs vel.y) > (abs field.y) then { h = null; terminal = true; }
    # Will never intersect. Only ever going down, and we're below already
    else if pos.y < (field.y) && vel.y <= 0 then { h = null; }
    else if field.contains pos then { h = maxh; }
    # Otherwise step 1 to see if we hit
    else shootProbe' (if pos.y > maxh then pos.y else maxh) { x = towardsZero vel.x; y = vel.y - 1; } { x = pos.x + vel.x; y = pos.y + vel.y; };
  in
  shootProbe' 0 velocity { x = 0; y = 0; };


  findMaxProbe = field:
  let
    # Try every X vel from 1 to one that instantly overshoots
    validXs = range 0 field.toX;
    maxForX = max: x: y:
    let
      s = shootProbe field { inherit x y; };
    in
      if s ? terminal then max
      else if max == null then maxForX s.h x (y + 1)
      else if s.h != null && s.h > max then maxForX s.h x (y + 1)
      else maxForX max x (y + 1);
  in
  foldl' (max: x: let m = maxForX 0 x 0; in if m > max then m else max) 0 validXs;


  # Part 2
  countHittingVelocities = field:
  let
    # Try every X vel from 1 to one that instantly overshoots
    validXs = range 0 field.toX;
    countForX = count: x: y:
    let
      s = shootProbe field { inherit x y; };
    in
      if s ? terminal then count
      else if s.h != null then countForX (count + 1) x (y + 1)
      else countForX count x (y + 1);
  in
  foldl' (count: x: count + (countForX 0 x field.y)) 0 validXs;
in
{
  part1 = findMaxProbe (parseField ./input.lines);
  part2 = countHittingVelocities (parseField ./input.lines);
}
