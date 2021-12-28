{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  getData = filename:
  let
    data = fileContents filename;
    lines = splitString "\n" data;
    filterLine = l: filter (c: matches "^[A-Z]$" c) (stringToCharacters l);
    topLine = filterLine (elemAt lines 2);
    secondLine = [ "D" "C" "B" "A" ];
    thirdLine = [ "D" "B" "A" "C" ];
    fourthLine = filterLine (elemAt lines 3);
    roomLines = [ topLine secondLine thirdLine fourthLine ];
  in
  # Store all state as a list, with 0..10 being the hallway, and then a dead
  # square so rooms align to a multiple of 4, and then all 4 rooms.
  (genList (_: "_") 11) ++ [ "x" ] ++ (map (l: elemAt l 0) roomLines) ++
    (map (l: elemAt l 1) roomLines) ++
    (map (l: elemAt l 2) roomLines) ++
    (map (l: elemAt l 3) roomLines);

  scoreMap = {
    "A" = 1;
    "B" = 10;
    "C" = 100;
    "D" = 1000;
  };
  # 4 spaces between them now
  roomIdx = {
    "A" = 12;
    "B" = 16;
    "C" = 20;
    "D" = 24;
  };

  isSolved = board: (concatStrings (sublist roomIdx.A (4*4) board)) == "AAAABBBBCCCCDDDD";

  makeMoveAt = b: idx:
  let
    el = elemAt b idx;
    isHallway = idx <= 10;
  in
  if el == "_" then []
  else if isHallway then maybeMoveToRoom b idx
  else maybeMoveToHallway b idx;

  isTrappedInRoom = b: idx:
  let
    roomDepth = mod idx 4;
    roomAlignedIdx = idx - roomDepth;
  in
  if roomDepth == 0 then false
  else any (c: c != "_") (sublist roomAlignedIdx roomDepth b);

  numMoves = idx: tgt:
  # always calc from room -> hallway
  if tgt > idx then numMoves tgt idx
  # if we're in the back of the room, move to the front, then move out
  else if (mod idx 4) != 0 then (mod idx 4) + (numMoves (idx - (mod idx 4)) tgt)
  # rooms pop out at 2/4/6/8 in the hallway.
  # rooms are stored at idx 12/16/20/24
  # So divide by 2 and subtract 4 to get the hallway idx.
  # Add 1 for popping out of the room too.
  else abs ((idx / 2 - 4) - tgt) + 1;

  isInFinalLocation = b: el: idx:
  let
    ridx = roomIdx."${el}";
    roomDepth = mod idx 4;
  in
  if idx < ridx || idx > (ridx + 3) then false
  # Are all the elements in front of us in the room in the right spot.
  else ! any (e: e != el) (sublist idx (4 - roomDepth) b);

  maybeMoveToHallway = b: idx:
  let
    el = elemAt b idx;
    validHallwayIdxes = filter (i: (elemAt b i) == "_" && canReachHallway b idx i) (range 0 10);
  in
  if (isInFinalLocation b el idx) then []
  else map (i: { lastMove = "hallway"; board = swap b i idx; score = (numMoves idx i) * scoreMap."${el}"; }) validHallwayIdxes;

  roomIdxToHallwayIdx = idx:
  let
    roomDepth = mod idx 4;
    roomAlignedIdx = idx - roomDepth;
  in roomAlignedIdx / 2 - 4;

  canReachHallway = b: idx: tgt:
  # Can't stop right outside a room
  if tgt == 2 || tgt == 4 || tgt == 6 || tgt == 8 then false
  else if (isTrappedInRoom b idx) then false
  else
  let
    roomHallwayIdx = roomIdxToHallwayIdx idx;
    checkFrom = (min roomHallwayIdx tgt);
    checkTo = (max roomHallwayIdx tgt);
    squares = sublist checkFrom (checkTo - checkFrom) b;
  in
  ! (any (s: s != "_") squares);

  canReachRoom = b: idx: tgt:
  let
    roomHallwayIdx = roomIdxToHallwayIdx tgt;
    checkFrom = (min roomHallwayIdx idx);
    checkTo = (max roomHallwayIdx idx);
    checkIdexes = filter (i: i != idx) (range checkFrom checkTo);
    squares = map (i: elemAt b i) checkIdexes;
  in
  ! (any (s: s != "_") squares);

  # If we're in the hallway, there's one valid move: moving to the right room
  maybeMoveToRoom = b: idx:
  let
    el = elemAt b idx;
    ridx = roomIdx."${el}";
    # Always move as far back in the room as we legally can, only moving closer
    # to the front if the rest of the room is already valid.
    targetIdx =
    if elemAt b (ridx + 3) == el && elemAt b (ridx + 2) == el && elemAt b (ridx + 1) == el then ridx
    else if elemAt b (ridx + 3) == el && elemAt b (ridx + 2) == el then ridx + 1
    else if elemAt b (ridx + 3) == el then ridx + 2
    else ridx + 3;
  in
  # Full room, 4 in it already
  if (elemAt b ridx) != "_" then []
  # Something already in our square
  else if (elemAt b targetIdx) != "_" then []
  else if ! canReachRoom b idx targetIdx then []
  else [ { lastMove = "room"; board = swap b idx targetIdx; score = (numMoves idx targetIdx) * scoreMap."${el}"; } ];

  minNull = lhs: rhs: if lhs == null then rhs else if rhs == null then lhs else min lhs rhs;

  bruteForceBoard = board: score: seen:
  let
    fingerprint = concatStrings board;
    nextBoards = concatMap (idx: makeMoveAt board idx) (filter (i: i != 11) (range 0 ((length board) - 1)));
    roomBoard = findFirst (b: b.lastMove == "room") null nextBoards;
    nextBoards' = if roomBoard == null then nextBoards else [ roomBoard ];
    hasSeen = seen ? "${fingerprint}";
    seen' = if hasSeen && seen."${fingerprint}" <= score then seen else (seen // { "${fingerprint}" = score; });
    bestBoard = foldl' (acc: b: let res = bruteForceBoard b.board (score + b.score) acc.seen; in { seen = res.seen; score = minNull acc.score res.score; }) { seen = seen'; score = null; } nextBoards';
  in
  if isSolved board then { inherit score seen; }
  # prune, there's a better path here
  else if hasSeen && seen."${fingerprint}" < score then { score = null; inherit seen; }
  else bestBoard;

  part2Answer = filename:
  let data = getData filename;
  in (bruteForceBoard data 0 {}).score;
in part2Answer
