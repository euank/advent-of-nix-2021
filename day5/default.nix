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

  markLine = board: line:
    if pointEqual line.start line.end then board
    else if line.start.x == line.end.x
    # Mark off a 'y' aligned line
    then
      let
        board' = expandBoard line.end (expandBoard line.start board);
        x = line.start.x;
        col = elemAt board' x;
        toMark = if line.start.y < line.end.y then { start = line.start.y; len = (line.end.y - line.start.y); } else { start = line.end.y; len = (line.start.y - line.end.y); };
        newCol = (sublist 0 toMark.start col) ++ (map (el: el + 1) (sublist toMark.start toMark.len col)) ++ (sublist (toMark.start + toMark.len + 1) ((length col) - (toMark.start + toMark.len + 1)) col);
        newBoard = (sublist 0 x board') ++ [ newCol ] ++ (sublist (x + 1) ((length board') - x + 1) board');
      in
        newBoard
    else if line.start.y == line.end.y
    # Mark off an 'x' aligned line
    then
    let
        board' = expandBoard line.end (expandBoard line.start board);
        y = line.start.y;
        toMark = if line.start.x < line.end.x then { start = line.start.x; len = line.end.x - line.start.x; } else { start = line.end.x; len = line.start.x - line.end.x; };
        updateCols = sublist toMark.start toMark.len board';
        updatedCols = map (c: (sublist 0 y) ++ [ ((elemAt c y) + 1) ] ++ (sublist (y + 1) ((length c) + 1 - y) c)) updateCols;
        newBoard = (sublist 0 toMark.start board') ++ updatedCols ++ (sublist (toMark.start + toMark.len) ((length board') - (toMark.start + toMark.len) + 1) board');
    in
      newBoard
    else board;


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
  x = markedBoard lineSegments;
}
