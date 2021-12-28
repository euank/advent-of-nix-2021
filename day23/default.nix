{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  # This puzzle's space looks legit small enough that we can just brute force
  # the whole thing. Let's do it.
  getData = filename:
  let
    data = fileContents filename;
    lines = splitString "\n" data;
    topLine = elemAt lines 2;
    bottomLine = elemAt lines 3;
    topChars = filter (c: matches "^[A-Z]$" c) (stringToCharacters topLine);
    bottomChars = filter (c: matches "^[A-Z]$" c) (stringToCharacters bottomLine);
  in
  # Store all state as a list, with 0..10 being the hallway and then 11.12 being the 'a' room, etc.
  (genList (_: "_") 11) ++ (flatten (zipListsWith (l: r: [ l r ]) topChars bottomChars));

  scoreMap = {
    "A" = 1;
    "B" = 10;
    "C" = 100;
    "D" = 1000;
  };
  roomIdx = {
    "A" = 11;
    "B" = 13;
    "C" = 15;
    "D" = 17;
  };

  isSolved = board: (concatStrings (sublist 11 8 board)) == "AABBCCDD";

  # idx is the place on the board to look. There's 19 total locations (11 hallway squares + 8 room squares).
  # Each idx can result in multiple possible "next" moves.
  makeMoveAt = board: idx:
  let
    b = board.board;
    el = elemAt b idx;
    isHallway = idx <= 10;
    score = board.score;
  in
  if el == "_" then []
  else if isHallway then maybeMoveToRoom b score idx
  else maybeMoveToHallway b score idx;

  isTrappedInRoom = b: idx: (mod idx 2) == 0 && (elemAt b (idx - 1)) != "_";

  numMoves = idx: tgt:
  # always calc from room -> hallway
  if tgt > idx then numMoves tgt idx
  # if we're in the back of the room, move to the front, then move out
  else if (mod idx 2) == 0 then 1 + (numMoves (idx - 1) tgt)
  # rooms pop out at 2/4/6/8 in the hallway.
  # rooms are stored at idx 11/13/15/17
  # So subtract 9 to get the room idx -> hallways square, and then move to that square.
  # And add 1 for the 0-based index off-by-1
  else (abs ((idx - 9) - tgt)) + 1;

  isInFinalLocation = b: el: idx:
  # in back of the right room
  if (mod idx 2) == 0 then idx == (roomIdx."${el}" + 1)
  # in front of right room, with right back
  else idx == roomIdx."${el}" && (elemAt b (roomIdx."${el}" + 1)) == el;

  numMoves2 = idx: tgt:
  if idx == tgt then 0
  else if idx <= 10 && tgt <= 10 then numMovesBetweenRooms idx tgt
  else numMoves idx tgt;

  numMovesBetweenRooms = idx: tgt:
  if (mod idx 2) == 0 then 1 + numMovesBetweenRooms (idx - 1) tgt
  else if (mod tgt 2) == 0 then 1 + numMovesBetweenRooms idx (tgt - 1)
  else if tgt < idx then numMovesBetweenRooms tgt idx
  # 2 for 'step into hallway, step into room'
  # Conveniently, the width between rooms and the depth is the same... so the 2
  # spaces between room entrances in the array matcehs the hallway width.
  else 2 + (tgt - idx);



  maybeMoveToHallway = b: score: idx:
  let
    el = elemAt b idx;
    validHallwayIdxes = filter (i: (elemAt b i) == "_" && canReachHallway b idx i) (range 0 10);
  in
  if isInFinalLocation b el idx then []
  else map (i: { board = swap b i idx; score = score + (numMoves idx i) * scoreMap."${el}"; }) validHallwayIdxes;

  canReachHallway = b: idx: tgt:
  if isTrappedInRoom b idx then false
  # Can't stop right outside a room
  else if tgt == 2 || tgt == 4 || tgt == 6 || tgt == 8 then false
  else
  let
    roomHallwayIdx = (idx - 9 - (if (mod idx 2) == 0 then 1 else 0));
    checkFrom = (min roomHallwayIdx tgt);
    checkTo = (max roomHallwayIdx tgt);
    squares = sublist checkFrom (checkTo - checkFrom) b;
  in
  ! (any (s: s != "_") squares);

  canReachRoom = b: idx: tgt:
  let
    roomHallwayIdx = (tgt - 9 - (if (mod tgt 2) == 0 then 1 else 0));
    checkFrom = (min roomHallwayIdx idx);
    checkTo = (max roomHallwayIdx idx);
    checkIdexes = filter (i: i != idx) (range checkFrom checkTo);
    squares = map (i: elemAt b i) checkIdexes;
  in
  ! (any (s: s != "_") squares);


  # If we're in the hallway, there's one valid move: moving to the right room
  maybeMoveToRoom = b: score: idx:
  let
    el = elemAt b idx;
    ridx = roomIdx."${el}";
    targetIdx = if (elemAt b (ridx + 1)) == el then ridx else ridx + 1;
  in
  # Full room, 2 in it already
  if (elemAt b ridx) != "_" then []
  else if (elemAt b targetIdx) != "_" then []
  else if (elemAt b (ridx + 1)) != "_" && (elemAt b (ridx + 1)) != el then []
  else if ! canReachRoom b idx targetIdx then []
  else [ { board = swap b idx targetIdx; score = score + (numMoves idx targetIdx) * scoreMap."${el}"; } ];

  minNull = lhs: rhs: if lhs == null then rhs else if rhs == null then lhs else min lhs rhs;


  # Estimate how far from complete a board is
  # Our heuristic is the distance each thing is from its target room
  heuristic = board:
  let
    as = filter (el: el != null) (imap0 (i: el: if el == "A" then i else null) board);
    bs = filter (el: el != null) (imap0 (i: el: if el == "B" then i else null) board);
    cs = filter (el: el != null) (imap0 (i: el: if el == "C" then i else null) board);
    ds = filter (el: el != null) (imap0 (i: el: if el == "D" then i else null) board);
  in
  ((numMoves2 (head as) roomIdx.A) + (numMoves2 (head as) (roomIdx.A) + 1)) * scoreMap.A +
  ((numMoves2 (head bs) roomIdx.B) + (numMoves2 (head bs) (roomIdx.B) + 1)) * scoreMap.B +
  ((numMoves2 (head cs) roomIdx.C) + (numMoves2 (head cs) (roomIdx.C) + 1)) * scoreMap.C +
  ((numMoves2 (head ds) roomIdx.D) + (numMoves2 (head ds) (roomIdx.D) + 1)) * scoreMap.D;


  # b
  findBestBoard = boards:
  let
    boards' = heap.pop boards;
    board = traceValSeq boards'.val;
    nextBoards = concatMap (idx: makeMoveAt board idx) (range 0 ((length board.board) - 1));
    boards'' = foldl' (h: b: heap.insert h (b // { hscore = b.score + heuristic b.board; })) boards'.heap nextBoards;
  in
  if isSolved board.board then board.score
  else findBestBoard boards'';

  part1Answer = filename:
  let
    data = getData filename;
    initHeap = heap.insert (heap.mkHeap (lhs: rhs: compare lhs.hscore rhs.hscore)) { board = data; score = 0; };
  in
  (findBestBoard initHeap).score;
in
{
  part1 = part1Answer ./input.lines;
}
