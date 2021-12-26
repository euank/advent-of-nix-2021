{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  getData = filename:
    let
      data = fileContents filename;
      parsePoint = s:
        let
          parts = splitString "," s;
        in
        { x = toInt (elemAt parts 0); y = toInt (elemAt parts 1); z = toInt (elemAt parts 2); };
      scannerSections = splitString "\n\n" data;
      parseScanner = sec:
        let
          secs = splitString "\n" sec;
        in
        { points = map parsePoint (tail secs); name = head secs; };
    in
    map parseScanner scannerSections;

  matrixMultP3 = m: p:
    let
      a = matrixMult m [ p.x p.y p.z ];
    in
    { x = elemAt a 0; y = elemAt a 1; z = elemAt a 2; };

  rotateZ = points:
    let
      rotMatrix = [ [ 0 (-1) 0 ] [ 1 0 0 ] [ 0 0 1 ] ];
    in
    map (p: matrixMultP3 rotMatrix p) points;

  rotateX = points:
    let
      rotMatrix = [ [ 1 0 0 ] [ 0 0 (-1) ] [ 0 1 0 ] ];
    in
    map (p: matrixMultP3 rotMatrix p) points;

  pointAdd = lhs: rhs: { x = lhs.x + rhs.x; y = lhs.y + rhs.y; z = lhs.z + rhs.z; };
  pointSub = lhs: rhs: { x = lhs.x - rhs.x; y = lhs.y - rhs.y; z = lhs.z - rhs.z; };
  pointEq = lhs: rhs: lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z;

  # Return a list of all 24 rotations for this set of points
  getRotations = points:
    let
      # We can do this by getting all 4 z rotations in each of 6 faces being 'up'.
      # First, 6 "up" faces
      upFaces = (foldl' (acc: n: acc ++ [ (applyN n rotateX points) ]) [ ] (range 0 3)) ++
        [ (rotateX (rotateZ points)) ] ++ [ (applyN 3 rotateX (rotateZ points)) ];
    in
    # And now the 4 Z rotations per face being up
    (concatMap (uf: map (n: applyN n rotateZ uf) (range 0 3)) upFaces);

  containsPoint = points: point: any (p: pointEq p point) points;

  # Num points overlapping with a given offset
  numOverlappingWithOffset = lhs: rhs: offset:
    let
      offsetRhs = applyOffset rhs offset;
    in
    foldl' (acc: p: acc + (if (containsPoint offsetRhs p) then 1 else 0)) 0 lhs;

  # numOverlapping returns how many points are overlapping in two sets if we
  # shift them onto each other optimally, and the offset to shift by.
  numOverlapping = lhs: rhs:
    # For now, I'm just brute-forcing this. I'm not sure if there's a more clever answer or not.
    let
      offsetsToTrySets = cartesianProductOfSets { inherit lhs rhs; };
      offsetsToTry = map (a: pointSub a.lhs a.rhs) offsetsToTrySets;
      numOverlappingAtOfset = map (offset: { inherit offset; overlapping = numOverlappingWithOffset lhs rhs offset; }) offsetsToTry;
    in
    foldl' (m: el: if el.overlapping > m.overlapping then el else m) ({ overlapping = 0; }) numOverlappingAtOfset;

  applyOffset = points: off: map (p: pointAdd p off) points;

  solveScanners = scanners:
    let
      correctOrientation = fixed: scanner:
        let
          orientations = getRotations scanner.points;
          overlapping = map (o: (numOverlapping fixed.points o) // { points = o; }) orientations;
          # We're given that 12 overlapping means it's right
          answer = findFirst (o: o.overlapping >= 12) null overlapping;
        in
        if answer == null then null else { name = scanner.name; points = answer.points; offset = answer.offset; };

      # state:
      # { oriented = []; remaining = []; }
      solveWith = fixed: state:
        let
          # Solve as many as we can
          oriented = map (s: correctOrientation fixed s) state.remaining;
          solved = filter (p: p != null) oriented;
          # Add the solved ones oriented correctly, and drop them from remaining
          solvedNames = map (s: s.name) solved;
          offsetSolved = map (s: { points = applyOffset s.points s.offset; name = s.name; }) solved;
          state' = {
            remaining = filter (el: ! (elem el.name solvedNames)) state.remaining;
            oriented = state.oriented ++ offsetSolved;
            unfixed = (filter (el: el.name != fixed.name) state.unfixed) ++ offsetSolved;
          };
        in
        if (traceVal (length state'.remaining)) == 0 then state'
        else solveWith (head state'.unfixed) state';
    in
    (solveWith (head scanners) { oriented = [ (head scanners) ]; remaining = tail scanners; unfixed = [ ]; }).oriented;


  cmpPoints = lhs: rhs:
    let
      cx = compare lhs.x rhs.x;
      cy = compare lhs.y rhs.y;
      cz = compare lhs.z rhs.z;
    in
    if cx != 0 then cx
    else if cy != 0 then cy
    else cz;

  # mergeSortedLists merges two lists that may have duplicates, removing the duplicates.
  # The lists must be sorted already, and must have only unique elements themselves.
  # Takes O(n) time complexity.
  mergeSortedLists = cmp: lhs: rhs:
    let
      nextLhs = head lhs;
      nextRhs = head rhs;
      c = cmp nextLhs nextRhs;
    in
    if (length lhs == 0) then rhs
    else if (length rhs == 0) then lhs
    else if c < 0 then [ nextLhs ] ++ (mergeSortedLists cmp (tail lhs) rhs)
    else if c == 0 then [ nextLhs ] ++ (mergeSortedLists cmp (tail lhs) (tail rhs))
    else [ nextRhs ] ++ (mergeSortedLists cmp lhs (tail rhs));

  mergeSolvedScanners = scanners:
    let
      sortBeacons = scanner: sort (a: b: (cmpPoints a b) < 0) scanner.points;
      sortedBeacons = map sortBeacons scanners;
    in
    foldl' (acc: s: mergeSortedLists cmpPoints acc s) [ ] sortedBeacons;

  part1Answer = filename:
    let
      data = getData filename;
      solvedScanners = solveScanners data;
    in
    length (mergeSolvedScanners solvedScanners);
in
{
  part1 = part1Answer ./input.lines;
}
