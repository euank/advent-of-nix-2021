{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  data = fileContents ./input.lines;
  lines = splitString "\n" data;

  parseEdge = s:
    let
      parts = splitString "-" s;
    in
    { from = elemAt parts 0; to = elemAt parts 1; };
  edges = lines: map parseEdge lines;

  # Storing the graph as an adjacency list:
  # node is of type
  # {
  #   type = small | big
  #   name = string
  #   adj = nodeNames[]
  # }
  # We'll also have a graph structure which is really just an attrset of { nodeName => node }
  # This will let us lookup adjacencies and the start node

  mkGraph = edges:
    let
      nodeNames = unique (concatMap (e: [ e.from e.to ]) edges);
      nodeAdj = name: (map (n: n.to) (filter (l: l.from == name) edges)) ++ (map (n: n.from) (filter (l: l.to == name) edges));
      nodes = foldl' (acc: name: acc // { "${name}" = { val = name; adj = nodeAdj name; type = if (matches "^[a-z].*" name) then "small" else "big"; }; }) { } nodeNames;
    in
    nodes;

  findPaths = nodes:
    let
      f = node: nodes: visitedSmallNodes: pathSoFar:
        # Found end, done
        if node.val == "end" then [ (pathSoFar ++ [ node.val ]) ]
        # Dead path, we are a small node that has been visited.
        else if visitedSmallNodes ? "${node.val}" then [ ]
        # Otherwise, visit all adjacent nodes.
        else
          let
            path = pathSoFar ++ [ node.val ];
            visitedSmallNodes' = visitedSmallNodes // (if node.type == "small" then { "${node.val}" = true; } else { });
          in
          concatMap (n: f nodes."${n}" nodes visitedSmallNodes' path) node.adj;
    in
    f nodes.start nodes { } [ ];
in
{
  part1 = length (findPaths (mkGraph (edges lines)));
}
