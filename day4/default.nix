{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  lines = fileContents ./input.lines;
  linesParts = splitString "\n\n" lines;
  draws = map toInt (splitString "," (head linesParts));
  rawBoards = drop 1 linesParts;

  # Parse boards into their initial unmarked form

  parseBoard = board:
  let
    boardLines = splitString "\n" board;
    parseLine = line: map (val: {val = toInt val; marked = false;}) (splitStringWhitespace line);
  in
    map parseLine boardLines;

  boards = map (parseBoard) rawBoards;

  rotateBoard = board:
    let
      genRow = i: map (row: elemAt row i) board;
    in
      imap0 (i: _: genRow i) board;

  isBoardWinning = board:
    let
      isWinning = row: all (el: el.marked) row;
      rows = board;
      cols = rotateBoard board;
    in
    (any isWinning rows) || (any isWinning cols);

  markBoard = board: num:
    map (row: map (el: if el.val == num then el // { marked = true; } else el) row) board;

  scoreBoard = board: winningNum:
    let
      val = v: v.val;
      unmarkedNums = flatten (map (row: map val (filter (v: ! v.marked) row)) board);
      unmarkedSum = foldl' builtins.add 0 unmarkedNums;
    in
    winningNum * unmarkedSum;


  markBoards = boards: num: map (board: markBoard board num) boards;

  findWinning = boards: draws:
  let
    findWinning' = state:
    let
      winning = filter isBoardWinning state.boards;
      draw = head state.draws;
    in
      if (length winning) > 0 then { board = (head winning); draw = state.prevDraw; }
      else if (length state.draws) == 0 then throw "no winner"
      else findWinning' ({ draws = (tail state.draws); boards = markBoards state.boards draw; prevDraw = draw; });
  in
    (findWinning' { inherit boards draws; });

  winning = findWinning boards draws;

  findWinningLast = boards: draws:
  let
    findWinningLast' = state:
    let
      winning = filter isBoardWinning state.boards;
      winningScores = state.winningScores ++ (map (b: scoreBoard b state.prevDraw) winning);
      notWinning = filter (f: ! isBoardWinning f) state.boards;
      draw = head state.draws;
    in
      if (length state.draws) == 0 then last state.winningScores
      else findWinningLast' ({
        inherit winningScores;
        draws = (tail state.draws);
        boards = markBoards notWinning draw;
        prevDraw = draw;
      });
  in
    (findWinningLast' { inherit boards draws; winningScores = [ ]; });

  winningLast = findWinningLast boards draws;
in
{
  part1 = scoreBoard winning.board winning.draw;
  part2 = findWinningLast boards draws;
}
