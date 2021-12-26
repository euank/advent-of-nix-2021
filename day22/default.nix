{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  getData = filename:
    let
      data = fileContents filename;
      lines = splitString "\n" data;
      parseRange = range:
        let
          parts = splitString "=" range;
          numParts = map toInt (splitString ".." (elemAt parts 1));
        in
        { from = elemAt numParts 0; to = elemAt numParts 1; };
      parseLine = line:
        let
          parts = splitString " " line;
          onOff = head parts;
          rangeParts = splitString "," (elemAt parts 1);
          ranges = map parseRange rangeParts;
        in
        { toggle = onOff; cube = { x = elemAt ranges 0; y = elemAt ranges 1; z = elemAt ranges 2; }; };
    in
    map parseLine lines;

  cubeContains = cube: x: y: z:
    if x < cube.x.from || x > cube.x.to then false
    else if y < cube.y.from || y > cube.y.to then false
    else if z < cube.z.from || z > cube.z.to then false
    else true;


  # The naive thing to do is actually to toggle everything, but it feels
  # slightly easier to code the check as "find the last step touching this
  # point, and it's on/off value is what we ended up as"
  isOn = revToggles: x: y: z:
    let
      toggle = findFirst (t: cubeContains t.cube x y z) null revToggles;
    in
    if toggle == null then false else toggle.toggle == "on";

  part1Answer = filename:
    let
      toggles = getData filename;
      revToggles = reverseList toggles;
      cube = cartesianProductOfSets { x = range (-50) 50; y = range (-50) 50; z = range (-50) 50; };
    in
    foldl' builtins.add 0 (map (c: if isOn revToggles c.x c.y c.z then 1 else 0) cube);

in
{
  part1 = part1Answer ./input.lines;
}
