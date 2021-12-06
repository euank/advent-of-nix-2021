{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  lines = fileContents ./input.lines;
  linesParts = splitString "\n" lines;

  parsePoint = p:
    let
      parts = splitString "," p;
      x = elemAt parts 0;
      y = elemAt parts 1;
    in
      { x = toInt x; y = toInt y; };

  parseSegment = line:
    let
      parts = splitString " -> " line;
      start = elemAt parts 0;
      end = elemAt parts 1;
    in
      { start = parsePoint start; end = parsePoint end; };

  lineSegments = map parseSegment linesParts;

  # There's probably a fancier math-y way to do this, but a 2d array that takes
  # O(n) time seems fine. The input is small.

  # Expand the board to contain the given point
  # For example, if the current board is:
  #
  #   0 1 2
  #   0 0 1
  #
  # Then 'expandBoard {x=4;y=4;}' will give us:
  #
  #   0 1 2 _ 0
  #   0 0 1 _ 0
  #   _ _ _ _ 0
  #   _ _ _ _ 0
  #
  # It does not fill in rows/cols fully to make it a square, just the
  # referenced points. All values are filled in with 0
  expandBoard = point: board:
  let
    xlen = length board;
    ycol = elemAt board point.x;
    ylen = length ycol;
  in
    # Expand board in the x direction if needed: +1 because of 0 based indexing and 1-based gen/length-ing
    # Recurse into this function for the y direction
    if xlen <= point.x then expandBoard point (board ++ (genList (_: []) (point.x + 1 - xlen)))
    # Fill in any missing 'y' elements with '0'
    else if ylen <= point.y then (sublist 0 point.x board) ++ [ (ycol ++ (genList (_: 0) (point.y + 1 - ylen))) ] ++ (sublist (point.x + 1) (xlen - point.x + 1) board)
    else board;

  markPoint = point: board:
  let
    board' = expandBoard point board;
    col = elemAt board' point.x;
    val = elemAt col point.y;
    newCol = (sublist 0 point.y col) ++ [ (val + 1) ] ++ (sublist (point.y + 1) ((length col) - point.y + 1) col);
    newBoard = (sublist 0 point.x board') ++ [ newCol ] ++ (sublist (point.x + 1) ((length board') - point.x + 1) board');
  in
    newBoard;

  pointEqual = lhs: rhs: lhs.x == rhs.x && lhs.y == rhs.y;
  pointLinear = lhs: rhs: lhs.x == rhs.x || lhs.y == rhs.y;

  movePointTowards = point: to:
    if point.x < to.x then point // { x = point.x + 1; }
    else if point.x > to.x then point // { x = point.x - 1; }
    else if point.y < to.y then point // { y = point.y + 1; }
    else if point.y > to.y then point // { y = point.y - 1; }
    else point;

  # Recursive markLine; base case is start == end. Other case is mark start, move start towards end.
  # This takes O(n) where n is the number of points on the line. It's _slow_
  markLine = board: line:
    if pointEqual line.start line.end then board
    else if ! (pointLinear line.start line.end) then board
    else
      let
        point = line.start;
        nextStart = movePointTowards line.start line.end;
        nextLine = line // { start = nextStart; };
      in markLine (markPoint point board) nextLine;

  markedBoard = lineSegments:
    let
      initBoard = [];
      markedBoard' = board: lineSegments:
      let
        toMark = head lineSegments;
      in
      if (length lineSegments) == 0 then board
      else markedBoard' (markLine board toMark) (tail lineSegments);
    in
      markedBoard' initBoard lineSegments;
in
{
  inherit markedBoard lineSegments;
  # markedBoard = markedBoard lineSegments;
}
