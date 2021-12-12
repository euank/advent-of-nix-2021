{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  data = fileContents ./input.lines;
  chars = map stringToCharacters (splitString "\n" data);
  gridLines = map (line: map toInt line) chars;
  width = length (head gridLines);
  height = length gridLines;
  grid = {
    data = gridLines;
    inherit width height;
  };

  # Get all candidate coordinates
  coords = cartesianProductOfSets { x = range 0 (width - 1); y = range 0 (height - 1); };

  gridContains = grid: x: y:
    if x < 0 || x >= grid.width then false
    else if y < 0 || y >= grid.height then false
    else true;

  getPoint = grid: x: y: default:
    if ! gridContains grid x y then default
    else elemAt (elemAt grid.data y) x;



  # Filter down to min points
  isMinPoint = grid: x: y:
    let
      val = getPoint grid x y null;
      lval = getPoint grid (x - 1) y 9;
      rval = getPoint grid (x + 1) y 9;
      uval = getPoint grid x (y - 1) 9;
      dval = getPoint grid x (y + 1) 9;
    in
    val < lval && val < rval && val < uval && val < dval;

  minPoints = grid: coords: filter (p: isMinPoint grid p.x p.y) coords;

  minPointVals = grid: points: map (p: (getPoint grid p.x p.y null) + 1) points;

  # Part 2 stuff
  # So, the approach I'm thinking is basically to walk all coordinates (O(n)),
  # and then greedily search out all basins for each coordinate.
  # To avoid wasting work, mark each point we've already searched, and don't
  # expand a basin on it again since we already got it. This should all be O(n)
  # still, so it should be fast enough.
  # This means we need to keep track of what we've seen.
  # I'm doing this via 'marked', a 2d arr of bools for things we've already
  # expanded suitably. We can skip marking 9s because we know we never have to
  # do work for em anyway.
  # In addition to the 'marked' list, we'll also keep a list of coords we
  # haven't been to yet at the top level since that seems simpler than doing
  # something fancy with marked.

  # state is of shape:
  # {
  #   basins = int[];
  #   coords = {x = int; y = int; }[];
  #   marked = bool[][]
  #   grid = { data = int[][]; width = int; height = int; };
  # }


  # Given a coordinate, return the size of the basin for that coordinate. 9 or
  # marked coordinates are 0, unmarked coordinates recursively find all
  # adjacent space's basin size.
  # Returns a new 'state' with the basin added in, and with 'marked' updated.
  expandBasin = coord: initState:
    let expandBasin' = coord: state:
      let
        coord' = coord;
        val = getPoint state.grid coord'.x coord.y 9;
        isMarked = elemAt (elemAt state.marked coord.y) coord.x;
        # And now mark ourselves
        marked = set2dArr state.marked coord.x coord.y true;
        mstate = state // { marked = (marked); };
        # Walk udlr, marking as we go
        u = expandBasin' { x = coord.x - 1; y = coord.y; } mstate;
        d = expandBasin' { x = coord.x + 1; y = coord.y; } u.state;
        l = expandBasin' { y = coord.y - 1; x = coord.x; } d.state;
        r = expandBasin' { y = (coord.y + 1); x = coord.x; } l.state;
      in
      # Not a new point, or an edge, don't go further. Also don't reference
        # marked so we don't walk off the grid
      if val == 9 || isMarked then ({ inherit state; basin = 0; })
      # new point, explore udlr and also add ourselves to the basin size
      else { state = r.state; basin = 1 + u.basin + d.basin + l.basin + r.basin; };
    in
    let
      basinState = (expandBasin' coord initState);
    in
    basinState.state // { basins = basinState.state.basins ++ [ basinState.basin ]; };

  findBasins = state:
    if (length state.coords) == 0 then state
    else
      let
        coord = head state.coords;
        coords = tail state.coords;
        isMarked = elemAt (elemAt state.marked coord.y) coord.x;
        val = getPoint state.grid coord.x coord.y 9;
        state' = state // { inherit coords; };
      in
      # If it's marked, we already added this coord to a basin or skipped it
        # And for 9s, we can also just do nothing
      if isMarked || val == 9 then findBasins state'
      # Find this basin, then find any others.
      else findBasins (expandBasin coord state');


  basinAnswer = state:
    let
      sorted = sort (l: r: ! (lessThan l r)) state.basins;
      top3 = take 3 sorted;
    in
    foldl' builtins.mul 1 top3;

in
{
  part1 = foldl' builtins.add 0 (minPointVals grid (minPoints grid (minPoints grid coords)));
  part2 = basinAnswer (findBasins { basins = [ ]; coords = coords; marked = genList (_: (genList (_: false) grid.width)) grid.height; inherit grid; });
}
