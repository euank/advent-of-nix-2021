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

  maxPoint = lineSegments:
    let
      allPoints = concatMap (line: [ line.start line.end ]) lineSegments;
    in
    foldl' (acc: p: { x = max p.x acc.x; y = max p.y acc.y; }) (head allPoints) (tail allPoints);

  pointEqual = lhs: rhs: lhs.x == rhs.x && lhs.y == rhs.y;
  pointLinear = lhs: rhs: lhs.x == rhs.x || lhs.y == rhs.y;

  markLine = board: line:
    if pointEqual line.start line.end then board
    else if line.start.x == line.end.x
    # Mark off a 'y' aligned line
    then
      let
        x = line.start.x;
        col = elemAt board x;
        toMark = if line.start.y < line.end.y then { start = line.start.y; len = line.end.y - line.start.y + 1; } else { start = line.end.y; len = line.start.y - line.end.y + 1; };
        newCol = (sublist 0 toMark.start col) ++ (map (el: el + 1) (sublist toMark.start toMark.len col)) ++ (sublist (toMark.start + toMark.len) ((length col) - (toMark.start + toMark.len)) col);
        newBoard = (sublist 0 x board) ++ [ newCol ] ++ (sublist (x + 1) ((length board) - x + 1) board);
      in
        newBoard
    else if line.start.y == line.end.y
    # Mark off an 'x' aligned line
    then
    let
        y = line.start.y;
        toMark = if line.start.x < line.end.x then { start = line.start.x; len = line.end.x - line.start.x + 1; } else { start = line.end.x; len = line.start.x - line.end.x + 1; };
        updateCols = sublist toMark.start toMark.len board;
        updatedCols = map (c: (sublist 0 y c) ++ [ ((elemAt c y) + 1) ] ++ (sublist (y + 1) ((length c) + 1 - y) c)) updateCols;
        newBoard = (sublist 0 toMark.start board) ++ updatedCols ++ (sublist (toMark.start + toMark.len) ((length board) - (toMark.start + toMark.len) + 1) board);
    in
      newBoard
    else board;


  markedBoard = lineSegments:
    let
      mp = maxPoint lineSegments;
      initBoard = genList (_: genList (_: 0) (mp.y + 1)) (mp.x + 1);
      markedBoard' = board: lineSegments:
      let
        toMark = head lineSegments;
      in
      if (length lineSegments) == 0 then board
      else markedBoard' (markLine board toMark) (tail lineSegments);
    in
      markedBoard' initBoard lineSegments;

  answer = markedBoard:
    count (el: el > 1) (flatten markedBoard);

  # part 2 stuff

  markPoint = point: board:
  let
    col = elemAt board point.x;
    val = elemAt col point.y;
    newCol = (sublist 0 point.y col) ++ [ (val + 1) ] ++ (sublist (point.y + 1) ((length col) - point.y + 1) col);
    newBoard = (sublist 0 point.x board) ++ [ newCol ] ++ (sublist (point.x + 1) ((length board) - point.x + 1) board);
  in
    newBoard;

  markLine2 = board: line:
    if line.start.x != line.end.x && line.start.y != line.end.y
    # 45 degree angled, we're promised
    then
      let
        xs = if line.start.x < line.end.x then range line.start.x line.end.x else (reverseList (range line.end.x line.start.x));
        ys = if line.start.y < line.end.y then range line.start.y line.end.y else (reverseList (range line.end.y line.start.y));
        points = map (el: { x = el.fst; y = el.snd; }) (zipLists xs ys);
      in
        foldl' (b: p: markPoint p b) board points
    else if line.start.x == line.end.x
    # Mark off a 'y' aligned line
    then
      let
        x = line.start.x;
        col = elemAt board x;
        toMark = if line.start.y < line.end.y then { start = line.start.y; len = line.end.y - line.start.y + 1; } else { start = line.end.y; len = line.start.y - line.end.y + 1; };
        newCol = (sublist 0 toMark.start col) ++ (map (el: el + 1) (sublist toMark.start toMark.len col)) ++ (sublist (toMark.start + toMark.len) ((length col) - (toMark.start + toMark.len)) col);
        newBoard = (sublist 0 x board) ++ [ newCol ] ++ (sublist (x + 1) ((length board) - x + 1) board);
      in
        newBoard
    else if line.start.y == line.end.y
    # Mark off an 'x' aligned line
    then
    let
        y = line.start.y;
        toMark = if line.start.x < line.end.x then { start = line.start.x; len = line.end.x - line.start.x + 1; } else { start = line.end.x; len = line.start.x - line.end.x + 1; };
        updateCols = sublist toMark.start toMark.len board;
        updatedCols = map (c: (sublist 0 y c) ++ [ ((elemAt c y) + 1) ] ++ (sublist (y + 1) ((length c) + 1 - y) c)) updateCols;
        newBoard = (sublist 0 toMark.start board) ++ updatedCols ++ (sublist (toMark.start + toMark.len) ((length board) - (toMark.start + toMark.len) + 1) board);
    in
      newBoard
    else board;

  markedBoard2 = lineSegments:
    let
      mp = maxPoint lineSegments;
      initBoard = genList (_: genList (_: 0) (mp.y + 1)) (mp.x + 1);
      markedBoard' = board: lineSegments:
      let
        toMark = head lineSegments;
      in
      if (length lineSegments) == 0 then board
      else markedBoard' (markLine2 board toMark) (tail lineSegments);
    in
      markedBoard' initBoard lineSegments;

in
rec {
  part1 = answer (markedBoard lineSegments);
  part2 = answer (markedBoard2 lineSegments);
}
