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

  isExplored = c: explored: explored ? "${toString c.x}-${toString c.y}";

  getMinUnexploredPoint = graph: unexplored:
  let
    unexploredList = attrValues unexplored;
  in
    foldl' (m: c: if (get2dArr graph c.x c.y) < (get2dArr graph m.x m.y) then c else m) (head unexploredList) (tail unexploredList);

  # state = { shortestPaths = [][]; explored = { "${x}-${y}" = boolean; }; unexplored = { "${x}=${y}" = {x=int; y=int;}; }; }
  shortestVal = point: state: graph:
    let
      height = length graph;
      width = length (head graph);
      inherit (state) shortestPaths explored unexplored;
    in
    # We explored the destination, all done
    if isExplored { x = width - 1; y = height - 1; } explored then state
    else
      let
        neighbors = adjacentCoords point;
        # Find points actually within the graph and not visited
        unvistedNeighbors = filter (c: c.x >= 0 && c.y >= 0 && c.x < width && c.y < height && !(isExplored c explored)) neighbors;
        # Update their shortest paths
        myShortest = get2dArr shortestPaths point.x point.y;
        # Update shortestPaths for each of these points
        shortest' = foldl'
          (acc: c:
            let
              curShortest = get2dArr acc c.x c.y;
              val = get2dArr graph c.x c.y;
            in
            if (myShortest + val) < curShortest then (set2dArr acc c.x c.y (myShortest + val)) else acc)
          shortestPaths
          unvistedNeighbors;

        unexplored' = foldl' (acc: c: (acc // { "${toString c.x}-${toString c.y}" = c; })) unexplored unvistedNeighbors;
        # Mark us as visited
        explored' = explored // { "${toString point.x}-${toString point.y}" = true; };
        unexplored'' = removeAttrs unexplored' [ "${toString point.x}-${toString point.y}" ];
        # Find the next point to visit
        nextPoint = getMinUnexploredPoint shortest' unexplored'';
      in
      shortestVal nextPoint { shortestPaths = shortest'; explored = explored'; unexplored = unexplored''; } graph;

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
      initExplored = { };

      state = shortestVal
        ({ x = 0; y = 0; })
        ({ shortestPaths = initShortest; explored = initExplored; unexplored = {}; })
        graph;
    in
    get2dArr state.shortestPaths (width - 1) (height - 1);


  # Part2 stuff
  # Expand the graph to the part2 size
  expandGraph = graph:
  let
    modVal = val: if val > 9 then (modVal (val - 9)) else val;
    widerGraph = map (row: concatMap (i: map (el: modVal (el + i)) row) (range 0 4)) graph;
    widerTallerGraph = concatMap (i: (map (row: map (el: modVal (el + i)) row) widerGraph)) (range 0 4);
  in widerTallerGraph;

  part2Answer = filename:
    let
      subgraph = getData filename;
      graph = expandGraph subgraph;

      height = length graph;
      width = length (head graph);
      coords = cartesianProductOfSets { x = range 0 (width - 1); y = range 0 (height - 1); };
      coordsAttr = foldl' (acc: c: acc // { "${toString c.x}-${toString c.y}" = c; }) {} coords;
      initShortest =
        let
          m = max graph;
          infGraph = map (l: map (_: m) l) graph;
        in
        set2dArr infGraph 0 0 0;
      initExplored = { };

      state = shortestVal
        ({ x = 0; y = 0; })
        ({ shortestPaths = initShortest; explored = initExplored; unexplored = coordsAttr; })
        graph;
    in
    get2dArr state.shortestPaths (width - 1) (height - 1);

in
{
  part1 = part1Answer ./input.lines;
  part2 = part2Answer ./input.lines;
}
