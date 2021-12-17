{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  getData = filename:
    let
      data = fileContents filename;
      lines = splitString "\n" data;
      arr = map (l: map toInt (stringToCharacters l)) lines;
      height = length arr;
      width = length (head arr);
    in
    mk2dArr (x: y: elemAt (elemAt arr y) x) width height;

  # 2dArr functions
  mk2dArr = gen: width: height:
  {
    inherit width height;
    data = genList (n: let y = n / width; x = mod n width; in gen x y) (width * height);
  };

  get2dArr = arr: x: y:
    elemAt arr.data (y * arr.width + x);

  get2dArrDef = arr: x: y: def:
  if x < 0 || y < 0 || x >= arr.width || y >= arr.height then def
  else get2dArr arr x y;

  set2dArr = arr: x: y: val:
  let
    idx = y * arr.width + x;
  in
    {
      inherit (arr) width height;
      data = (sublist 0 idx arr.data) ++ [ val ] ++ (sublist (idx + 1) ((length arr.data) - idx + 1) arr.data);
    };


  adjacentCoords = c: [
    { x = c.x - 1; y = c.y; }
    { x = c.x + 1; y = c.y; }
    { x = c.x; y = c.y - 1; }
    { x = c.x; y = c.y + 1; }
  ];

  # max possible value, sum of all ints here. Used as 'infinity' for our shortest path found so far
  max = graph: foldl' builtins.add 0 graph.data;

  isExplored = c: explored: explored ? "${toString c.x}-${toString c.y}";

  getMinUnexploredPoint = graph: unexplored:
    foldl' (m: c: if (get2dArr graph c.x c.y) < (get2dArr graph m.x m.y) then c else m) (head unexplored) (tail unexplored);

  # state = { shortestPaths = [][]; explored = { "${x}-${y}" = boolean; }; unexplored = []{x = int; y = int }; }
  shortestVal = point: state: graph:
    let
      height = graph.height;
      width = graph.width;
      inherit (state) shortestPaths explored unexplored;
    in
    # We explored the destination, all done
    if isExplored { x = width - 1; y = height - 1; } explored then state
    else
      let
        neighbors = adjacentCoords point;
        # Find points actually within the graph and not visited
        unvisitedNeighbors = filter (c: c.x >= 0 && c.y >= 0 && c.x < height && c.y < width && !(isExplored c explored)) neighbors;
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
          unvisitedNeighbors;
        # Mark us as visited
        explored' = explored // { "${toString point.x}-${toString point.y}" = true; };
        unexplored' = filter (c: c.x != point.x || c.y != point.y) unexplored;
        # Find the next point to visit
        nextPoint = getMinUnexploredPoint shortest' unexplored';
      in
      shortestVal nextPoint { shortestPaths = shortest'; explored = explored'; unexplored = unexplored'; } graph;

  part1Answer = filename:
    let
      graph = getData filename;
      height = graph.height;
      width = graph.width;
      coords = cartesianProductOfSets { x = range 0 (width - 1); y = range 0 (height - 1); };
      initShortest =
        let
          m = max graph;
          infGraph = mk2dArr (_: _: m) graph.width graph.height;
        in
        set2dArr infGraph 0 0 0;
      initExplored = { };

      state = shortestVal
        ({ x = 0; y = 0; })
        ({ shortestPaths = initShortest; explored = initExplored; unexplored = coords; })
        graph;
    in
    get2dArr state.shortestPaths (width - 1) (height - 1);


  # Part2 stuff

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

      height = graph.height;
      width = graph.width;
      coords = cartesianProductOfSets { x = range 0 (width - 1); y = range 0 (height - 1); };
      initShortest =
        let
          m = max graph;
          infGraph = map (l: map (_: m) l) graph;
        in
        set2dArr infGraph 0 0 0;
      initExplored = { };

      state = shortestVal
        ({ x = 0; y = 0; })
        ({ shortestPaths = initShortest; explored = initExplored; unexplored = coords; })
        graph;
    in
    get2dArr state.shortestPaths (width - 1) (height - 1);
in
{
  inherit mk2dArr get2dArr set2dArr;
  part1 = part1Answer ./input.lines;
  part2 = part2Answer ./input.lines;
}
