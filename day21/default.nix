{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  getData = filename:
    let
      data = fileContents filename;
      parts = splitString "\n" data;
      playerPositions = map (p: toInt (elemAt (splitString ": " p) 1)) parts;
    in
    { p1 = elemAt playerPositions 0; p2 = elemAt playerPositions 1; };

  rollDie = die:
    let
      val = if die.val == 100 then 1 else die.val + 1;
    in
    { rolls = [ val ] ++ die.rolls; inherit val; };


  playGame = state:
    let
      p1Turn = state.p1Turn;
      die = applyN 3 rollDie state.die;
      rolls = take 3 die.rolls;
      sum = foldl' add 0 rolls;
      pos = state.pos // (if p1Turn then { p1 = mod (state.pos.p1 + sum) 10; } else { p2 = mod (state.pos.p2 + sum) 10; });
      # Add 1 for 0-indexed vs 1-indexed pos.
      score = state.score // (if p1Turn then { p1 = state.score.p1 + pos.p1 + 1; } else { p2 = state.score.p2 + pos.p2 + 1; });
      state' = { p1Turn = ! p1Turn; turn = state.turn + 1; inherit die pos score; };
    in
    if state'.score.p1 >= 1000 || state'.score.p2 >= 1000 then state'
    else playGame state';

  part1Answer = filename:
    let
      data = getData filename;
      # subtract 1 from pos because we use base-0 pos (0-9 instead of 1-10) so
      # that modulo works like we want.
      game = playGame { pos = { p1 = data.p1 - 1; p2 = data.p2 - 1; }; score = { p1 = 0; p2 = 0; }; p1Turn = true; die = { rolls = [ ]; val = 0; }; };
      dieRolls = length game.die.rolls;
      losingScore = min game.score.p1 game.score.p2;
    in
    dieRolls * losingScore;

  # part2Answer
  # This one, part2 is really different from part1, so we reuse relatively little code

  # How many dice rolls give you a total.
  # i.e. { weight = 1; val = 3; } because only a single set of 3 rolls give you a 3 (111).
  diceSumWeights =
    let
      rolls = cartesianProductOfSets { r1 = [ 1 2 3 ]; r2 = [ 1 2 3 ]; r3 = [ 1 2 3 ]; };
      sums = map (a: a.r1 + a.r2 + a.r3) rolls;
      sumGroups = groupBy (el: toString el) sums;
      sumGroupCounts = mapAttrs (n: v: { weight = length v; val = toInt n; }) sumGroups;
    in
    attrValues sumGroupCounts;

  applyRoll = state: roll:
    let
      pos = {
        p1 = if state.p1Turn then mod (state.pos.p1 + roll) 10 else state.pos.p1;
        p2 = if ! state.p1Turn then mod (state.pos.p2 + roll) 10 else state.pos.p2;
      };
      score = {
        p1 = if state.p1Turn then state.score.p1 + pos.p1 + 1 else state.score.p1;
        p2 = if ! state.p1Turn then state.score.p2 + pos.p2 + 1 else state.score.p2;
      };
    in
    {
      p1Turn = ! state.p1Turn;
      inherit pos score;
    };

  addWins = weight: curWins: wins: { p1 = curWins.p1 + wins.p1 * weight; p2 = curWins.p2 + wins.p2 * weight; };

  # Returns the sum of winning games for p1 vs p2 with all possible dice rolls
  playGame2 = state:
    if state.score.p1 >= 21 then { p1 = 1; p2 = 0; }
    else if state.score.p2 >= 21 then { p2 = 1; p1 = 0; }
    else foldl' (acc: r: addWins r.weight acc (playGame2 (applyRoll state r.val))) { p1 = 0; p2 = 0; } diceSumWeights;

  part2Answer = filename:
    let
      data = getData filename;
      # subtract 1 from pos because we use base-0 pos (0-9 instead of 1-10) so
      # that modulo works like we want.
      game = playGame2 { pos = { p1 = data.p1 - 1; p2 = data.p2 - 1; }; score = { p1 = 0; p2 = 0; }; p1Turn = true; };
    in
    max game.p1 game.p2;
in
{
  part1 = part1Answer ./input.lines;
  part2 = part2Answer ./input.lines;
}
