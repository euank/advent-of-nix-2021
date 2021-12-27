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

  # part2
  # We clearly need to be more clever since the above was _slow_.
  # What we really want to do, I think, is do a bunch of cube intersections,
  # and just add/subtract areas based on that.

  # null if they don't intersect, the cube they intersect in if they do.
  intersectCubes = c1: c2:
    # no overlap cases
    if c1.x.to < c2.x.from || c1.y.to < c2.y.from || c1.z.to < c2.z.from then null
    else if c1.x.from > c2.x.to || c1.y.from > c2.y.to || c1.z.from > c2.z.to then null
    # Overlap
    else {
      x = { from = max c2.x.from c1.x.from; to = min c2.x.to c1.x.to; };
      y = { from = max c2.y.from c1.y.from; to = min c2.y.to c1.y.to; };
      z = { from = max c2.z.from c1.z.from; to = min c2.z.to c1.z.to; };
    };

  # Add 1 since the ranges are inclusive
  cubeArea = c: (c.x.to - c.x.from + 1) * (c.y.to - c.y.from + 1) * (c.z.to - c.z.from + 1);

  calcOnAreaIn = initToggles: cube:
    let
      f = toggles: applied:
        let
          t = head toggles;
          toggles' = tail toggles;
          applied' = applied ++ [ t ];
          intc = intersectCubes t.cube cube;
          area = cubeArea intc;
        in
        if (length toggles) == 0 then 0
        else if intc == null then f toggles' applied'
        # Add our area, and subtract anything we double counted (anything already on in our area), and recurse
        else if t.toggle == "on" then area - (calcOnAreaIn applied intc) + (f toggles' applied')
        # Subtract anything that was on in our area, we turned it off, and recurse
        else (-1) * (calcOnAreaIn applied intc) + (f toggles' applied');
    in
    f initToggles [ ];

  part2Answer = filename:
    let
      toggles = getData filename;
      fieldCube = foldl'
        (acc: t: {
          x = { from = min acc.x.from t.cube.x.from; to = max acc.x.to t.cube.x.to; };
          y = { from = min acc.y.from t.cube.y.from; to = max acc.y.to t.cube.y.to; };
          z = { from = min acc.z.from t.cube.z.from; to = max acc.z.to t.cube.z.to; };
        })
        { x = { from = 0; to = 0; }; y = { from = 0; to = 0; }; z = { from = 0; to = 0; }; }
        toggles;
      # Find the field size so we can re-use calcOnAreaIn
    in
    calcOnAreaIn toggles fieldCube;
in
{
  part1 = part1Answer ./input.lines;
  part2 = part2Answer ./input.lines;
}
