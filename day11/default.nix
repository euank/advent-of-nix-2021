{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  data = fileContents ./input.lines;
  grid = map (s: map toInt (stringToCharacters s)) (splitString "\n" data);

  adjacentCoords = c: [
    ({ x = c.x; y = c.y + 1; })
    ({ x = c.x; y = c.y - 1; })
    ({ x = c.x + 1; y = c.y; })
    ({ x = c.x - 1; y = c.y; })
    ({ x = c.x + 1; y = c.y + 1; })
    ({ x = c.x + 1; y = c.y - 1; })
    ({ x = c.x - 1; y = c.y + 1; })
    ({ x = c.x - 1; y = c.y - 1; })
  ];

  inArr = arr: x: y:
    let
      width = length (head grid);
      height = length grid;
    in
    x < width && y < height && x >= 0 && y >= 0;

  # state:
  # {
  #   grid = int[][] # 2darr grid
  #   flashes = int  # num flashes so far
  # }
  # Single step
  step = state:
    let
      grid = state.grid;
      width = length (head grid);
      height = length grid;
      # All coordinates so we can loop over em all conveniently.
      coords = cartesianProductOfSets { x = range 0 (width - 1); y = range 0 (height - 1); };
      initFlashes = genList (_: genList (_: false) width) height;
      # initial increase
      initState = { flashes = state.flashes; grid = map (l: map (v: v + 1) l) grid; };
      f = state: flashes:
        let
          grid = state.grid;
          # Find all new flashes
          flashCoords = filter (c: (get2dArr flashes c.x c.y) == false && (get2dArr grid c.x c.y) > 9) coords;
          # Aggregate
          newFlashes = length flashCoords;
          numFlashes = state.flashes + newFlashes;
          # Mark all flashes
          flashes' = foldl' (acc: c: set2dArr acc c.x c.y true) flashes flashCoords;
          # Mark grid to 0
          grid' = foldl' (acc: c: set2dArr acc c.x c.y 0) grid flashCoords;
          # Mark adjacent grid memebers
          increaseCoords = filter (c: inArr grid c.x c.y) (concatMap (c: adjacentCoords c) flashCoords);
          # Increment all adjacent coords
          grid'' = foldl' (acc: c: if (get2dArr flashes' c.x c.y) == true then acc else set2dArr acc c.x c.y ((get2dArr acc c.x c.y) + 1)) grid' increaseCoords;
        in
        # Base case, done flashing
        if newFlashes == 0 then { inherit grid; flashes = numFlashes; }
        # mark flashes. Ideally, only recurse into adjacent coords, but I'm lazy so recurse into all coords
        else f ({ grid = grid''; flashes = numFlashes; }) flashes';
    in
    f initState initFlashes;

  stepTimes = grid: times:
    let
      init = { inherit grid; flashes = 0; };
    in
    foldl' (acc: _: step acc) init (range 0 (times - 1));
in
{
  part1 = (stepTimes grid 100).flashes;
}
