{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  data = fileContents ./input.lines;
  initState = map toInt (splitString "," data);
  sortedState = sort lessThan initState;

  # binary search the last zero; return -1 if there's no zero, or the index of the last 0
  lastZero = list:
    if (length list) == 0 then 0
    else if (length list) == 1 && (elemAt list 0) == 0 then 0
    else if (length list) == 1 && (elemAt list 0) != 0 then -1
    else
      let
        half = (length list) / 2;
        el = elemAt list half;
      in
      if el == 0 then half + (lastZero (sublist half ((length list) - half) list))
      else lastZero (sublist 0 half list);

  stepDay = state:
    let
      zfishNdx = lastZero state;
      # drop the zeros, we'll add them as 6's in a sec
      nonzFish = drop (zfishNdx + 1) state;
      # age the nonzFish
      nonzFish' = map (el: el - 1) nonzFish;
      # Append on the 6s
      origFishAged = nonzFish' ++ (genList (_: 6) (zfishNdx + 1));
      # Append on the new fish
      newState = origFishAged ++ (genList (_: 8) (zfishNdx + 1));
    in
    # We need to sort because of we appended 6s, but it's possible to have a
      # 7 from one round ago. We'll be mostly sorted, so this should be fast.
    sort lessThan newState;

  stepDays = days: state:
    if days == 0 then state
    else stepDays (days - 1) (stepDay state);

  # Part 2
  # numGenerated: unused, this is too slow, I immediately needed memoization
  numGenerated = daysLeft: val:
    if daysLeft <= val then 1
    # Generate us + our child recursively
    else (numGenerated (daysLeft - val) 9) + (numGenerated (daysLeft - val) 7);

  # memoized. Fast. Good.
  numGeneratedMemo = memo: daysLeft: val:
    if daysLeft <= val then { inherit memo; val = 1; }
    else if memo ? "${toString daysLeft}-${toString val}" then { inherit memo; val = memo."${toString daysLeft}-${toString val}"; }
    else
      let
        lhs = (numGeneratedMemo memo (daysLeft - val) 9);
        rhs = (numGeneratedMemo lhs.memo (daysLeft - val) 7);
        answer = lhs.val + rhs.val;
        newMemo = rhs.memo // { "${toString daysLeft}-${toString val}" = answer; };
      in
      { memo = newMemo; val = answer; };

  totalGenerated = days: state:
    let memo = { };
    in pkgs.lib.foldl' (acc: rhs: let tmp = numGeneratedMemo acc.memo days rhs; in { val = acc.val + tmp.val; memo = tmp.memo; }) ({ inherit memo; val = 0; }) state;
in
{
  part1 = (totalGenerated 80 sortedState).val;
  part2 = (totalGenerated 256 sortedState).val;
}
