{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  getData = filename:
    let
      lines = splitString "\n" (fileContents filename);
      # Parse a numeric literal
      parseNumber = rem:
        let
          parts = splitUntil (e: ! matches "[0-9]" e) rem;
        in
        { rem = parts.snd; val = toInt (concatStrings parts.fst); };

      # parse a pair
      parsePair = rem:
        let
          # Tail to chop off '['
          fst = parseElement (tail rem);
          # Tail to chop off ','
          snd = parseElement (tail fst.rem);
        in
        # Tail to chop off ']'
        { rem = tail snd.rem; val = { fst = fst.val; snd = snd.val; }; };

      # Parse an 'element', which may be a pair or numeric litearl
      parseElement = rem:
        if (head rem) == "[" then parsePair rem
        else parseNumber rem;

      parseLine = l:
        (parseElement (stringToCharacters l)).val;
    in
    map parseLine lines;

  reduceNumber = tree:
    let
      addLeftmostVal = tree: val:
        let
          addLeftmostVal = tree: val:
            if isInt tree then tree + val
            else tree // { fst = addLeftmostVal tree.fst val; };
        in
        if isInt tree then tree + val
        else tree // { snd = addLeftmostVal tree.snd val; };

      addRightmostVal = tree: val:
        let
          addRightmostVal = tree: val:
            if isInt tree then tree + val
            else tree // { snd = addRightmostVal tree.snd val; };
        in
        if isInt tree then tree + val
        else tree // { fst = addRightmostVal tree.fst val; };

      applyExplosion = depth: tree:
        let
          lhs = applyExplosion (depth + 1) tree.fst;
          lhsTree = tree // { fst = lhs.tree; };
          rhs = applyExplosion (depth + 1) tree.snd;
          rhsTree = tree // { snd = rhs.tree; };
        in
        # leaf ints can't explode
        if isInt tree then { exploded = false; inherit tree; }
        else if lhs.exploded && lhs.eval ? snd then { exploded = true; tree = addLeftmostVal lhsTree lhs.eval.snd; eval = removeAttrs lhs.eval [ "snd" ]; }
        else if lhs.exploded then { exploded = true; eval = lhs.eval; tree = lhsTree; }
        else if rhs.exploded && rhs.eval ? fst then { exploded = true; tree = addRightmostVal rhsTree rhs.eval.fst; eval = removeAttrs rhs.eval [ "fst" ]; }
        else if rhs.exploded then { exploded = true; eval = rhs.eval; tree = rhsTree; }
        # Always explode at depth 4
        else if depth == 4 then { exploded = true; eval = tree; tree = 0; }
        else { exploded = false; inherit tree; };

      applySplit = tree:
        let
          lhs = applySplit tree.fst;
          rhs = applySplit tree.snd;
        in
        if isInt tree && tree >= 10 then { split = true; tree = { fst = tree / 2; snd = (tree + 1) / 2; }; }
        else if isInt tree then { split = false; inherit tree; }
        else if lhs.split then { split = true; tree = tree // { fst = lhs.tree; }; }
        else if rhs.split then { split = true; tree = tree // { snd = rhs.tree; }; }
        else { split = false; inherit tree; };

      explode = applyExplosion 0 tree;
      split = applySplit tree;
    in
    if explode.exploded then reduceNumber explode.tree
    else if split.split then reduceNumber split.tree
    else tree;


  calcMagnitude = tree:
    if isInt tree then tree
    else 3 * (calcMagnitude tree.fst) + 2 * (calcMagnitude tree.snd);

  part1Answer = filename:
    let
      lines = getData filename;
      answer = foldl' (acc: t: reduceNumber { fst = acc; snd = t; }) (head lines) (tail lines);
    in
    calcMagnitude answer;

  # part 2
  part2Answer = filename:
    let
      lines = getData filename;
      numberedLines = imap0 (i: line: { inherit i line; }) lines;
      pairs = cartesianProductOfSets { fst = numberedLines; snd = numberedLines; };
      pairs' = filter (a: a.fst.i == a.fst.i) pairs;
      pairs'' = map (p: { fst = p.fst.line; snd = p.snd.line; }) pairs';
    in
    foldl' (acc: pair: let m = calcMagnitude (reduceNumber pair); in max acc m) 0 pairs'';

in
{
  part1 = part1Answer ./input.lines;
  part2 = part2Answer ./input.lines;
}
