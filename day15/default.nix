{ lib, pkgs }:
with pkgs.lib;
with lib;
let
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

  getMinUnexploredPoint = graph: explored:
    let
      width = length (head graph);
      height = length graph;
      coords = cartesianProductOfSets { x = range 0 (width - 1); y = range 0 (height - 1); };
      isUnexplored = c: (get2dArrDef explored c.x c.y 1) == 0;
    in
    foldl' (m: c: if m == null && (isUnexplored c) then c else if ! isUnexplored c then m else if (get2dArr graph c.x c.y) < (get2dArr graph m.x m.y) then c else m) null coords;

  # state = { shortestPaths = [][]; explored = [][]; }
  shortestVal = point: state: graph:
    let
      height = length graph;
      width = length (head graph);
      inherit (state) shortestPaths explored;
    in
    # We explored the destination, all done
    if (get2dArr explored (width - 1) (height - 1)) == 1 then state
    else if (get2dArr explored point.x point.y) == 1 then throw "explored node visited again"
    else
      let
        neighbors = adjacentCoords point;
        # Find points actually within the graph and not visited
        unvistedNeighbors = filter (c: (get2dArrDef explored c.x c.y 1) == 0) neighbors;
        # Update their shortest paths
        myShortest = get2dArr shortestPaths point.x point.y;
        # Update shortestPaths for each of these points
        shortest' = foldl' (acc: c: let
          curShortest = get2dArr acc c.x c.y;
          val = get2dArr graph c.x c.y;
        in
        if (myShortest + val) < curShortest then (set2dArr acc c.x c.y (myShortest + val)) else acc) shortestPaths unvistedNeighbors;
        # Mark us as visited
        explored' = set2dArr explored point.x point.y 1;
        # Find the next point to visit
        nextPoint = getMinUnexploredPoint shortest' explored';
      in
      shortestVal nextPoint { shortestPaths = shortest'; explored = explored'; } graph;

  part1Answer = filename:
    let
      graph = getData filename;
      height = length graph;
      width = length (head graph);
      initShortest =
        let
          m = max graph;
          infGraph = map (l: map (_: m) l) graph;
        in
        set2dArr infGraph 0 0 0;
      initExplored = map (l: map (_: 0) l) graph;

      state = shortestVal
        ({ x = 0; y = 0; })
        ({ shortestPaths = initShortest; explored = initExplored; })
        graph;
    in
    get2dArr state.shortestPaths (width - 1) (height - 1);

in
{
  part1 = part1Answer ./input.lines;
}
