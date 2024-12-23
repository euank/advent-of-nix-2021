{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  heap = lib.heap2;
  getData = filename:
    let
      data = fileContents filename;
      lines = splitString "\n" data;
      arr = map (l: map toInt (stringToCharacters l)) lines;
    in
    arr;

  adjacentCoords = c: [
    { x = c.x - 1; y = c.y; }
    { x = c.x + 1; y = c.y; }
    { x = c.x; y = c.y - 1; }
    { x = c.x; y = c.y + 1; }
  ];

  # max possible value, sum of all ints here. Used as 'infinity' for our shortest path found so far
  max = graph: foldl' builtins.add 0 (flatten graph);

  # This implements A*. Initially, I wrote dijkstra's, but it was too slow for part2.
  # We have a natural heuristic function in that we know the shortest possible
  # path is always a path of all '1' values straight to the goal, so use that
  # as the heuristic.
  shortestPathHeuristic = graph: x: y:
    let
      height = length graph;
      width = length (head graph);
    in
    ((width - 1 - x) + (height - 1 - y));

  # I don't know A* by memory, unlike dijsktras, so I'm basing it off of:
  # https://www.redblobgames.com/pathfinding/a-star/implementation.html#python-astar
  # state: {
  #   shortest = attr of points to shortestDist;
  #   frontier = heap of { x = int; y = int ; val = shortestDist; hval = heuristic for shortest distance };
  # }
  shortestVal = state: graph:
    let
      height = length graph;
      width = length (head graph);
      inherit (state) shortest frontier;
      popVal = heap.pop frontier;
      frontier' = popVal.heap;
      cur = popVal.val;
    in
    # We reached the destination, all done
    if cur.x == (width - 1) && cur.y == (height - 1) then cur.val
    else
      let
        # Find points actually within the graph
        neighbors = filter (c: c.x >= 0 && c.y >= 0 && c.x < width && c.y < height) (adjacentCoords cur);
        neighborCosts = map (p: let val = cur.val + (get2dArr graph p.x p.y); in p // { inherit val; hval = val + (shortestPathHeuristic graph p.x p.y); }) neighbors;
        # neighbors that we haven't seen yet, or that are better than our current best.
        toAdd = filter (p: p.val < shortest."${toString p.x}"."${toString p.y}") neighborCosts;
        # Add them to the frontier and to shortest
        frontier'' = foldl' (f: p: heap.insert f p) frontier' toAdd;
        shortest' = foldl' (s: p: recursiveUpdate s { "${toString p.x}" = { "${toString p.y}" = p.val; }; }) shortest toAdd;
      in
      shortestVal { shortest = shortest'; frontier = frontier''; } graph;

  initShortest = graph:
    let
      height = length graph;
      width = length (head graph);
      m = max graph;
      attr = listToAttrs (genList (x: nameValuePair (toString x) (listToAttrs (genList (y: nameValuePair (toString y) m) height))) width);
    in
    recursiveUpdate attr { "0" = { "0" = 0; }; };

  part1Answer = filename:
    let
      graph = getData filename;
    in
    shortestVal
      { shortest = initShortest graph; frontier = (heap.insert (heap.mkHeap (lhs: rhs: (compare lhs.hval rhs.hval))) { x = 0; y = 0; val = 0; hval = shortestPathHeuristic graph 0 0; }); }
      graph;


  # Part2 stuff
  # Expand the graph to the part2 size
  expandGraph = graph:
    let
      modVal = val: if val > 9 then (modVal (val - 9)) else val;
      widerGraph = map (row: concatMap (i: map (el: modVal (el + i)) row) (range 0 4)) graph;
      widerTallerGraph = concatMap (i: (map (row: map (el: modVal (el + i)) row) widerGraph)) (range 0 4);
    in
    widerTallerGraph;

  part2Answer = filename:
    let
      subgraph = getData filename;
      graph = expandGraph subgraph;
    in
    shortestVal
      { shortest = initShortest graph; frontier = (heap.insert (heap.mkHeap (lhs: rhs: (compare lhs.hval rhs.hval))) { x = 0; y = 0; val = 0; hval = shortestPathHeuristic graph 0 0; }); }
      graph;

in
{
  part1 = part1Answer ./input.lines;
  part2 = part2Answer ./input.lines;
}
