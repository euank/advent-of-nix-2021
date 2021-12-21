{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  # pad hex digits out to length 4
  leftPad = len: arr:
    if (length arr) == len then arr else leftPad len ([ 0 ] ++ arr);

  hexToBits = h:
    leftPad 4 (toBaseDigits 2 { "0" = 0; "1" = 1; "2" = 2; "3" = 3; "4" = 4; "5" = 5; "6" = 6; "7" = 7; "8" = 8; "9" = 9; "A" = 10; "B" = 11; "C" = 12; "D" = 13; "E" = 14; "F" = 15; }."${h}");

  getData = filename:
    let
      data = fileContents filename;
      bits = concatMap hexToBits (stringToCharacters data);
    in
    bits;

  types = {
    sum  = 0;
    prod = 1;
    min  = 2;
    max  = 3;
    lit  = 4;
    gt   = 5;
    lt   = 6;
    eq   = 7;
  };

  parseLiteral = state: version: num:
    # Caller dealt with the typ/version stuff, so we just deal in bits
    let
      group = take 5 state.arr;
      isEnd = (head group) == 0;
      groupNum = fromBinaryBits (tail group);
      num' = num * 16 + groupNum;
      arr = drop 5 state.arr;
    in
    if isEnd then { inherit arr; packets = state.packets ++ [{ typ = types.lit; val = num'; inherit version; }]; }
    else parseLiteral (state // { inherit arr; }) version num';

  parseOperator = state: version: typ:
    let
      lenTyp = head state.arr;
      arr = tail state.arr;
    in
    if lenTyp == 0 then
      let
        n = fromBinaryBits (take 15 arr);
        arr' = drop 15 arr;
      in
      {
        arr = drop n arr';
        packets = state.packets ++ [{ inherit typ version; packets = parsePackets (take n arr'); }];
      }
    else
      let
        n = fromBinaryBits (take 11 arr);
        arr' = drop 11 arr;
        parsedState = foldl' (state: _: parsePacket state) { arr = arr'; packets = [ ]; } (range 1 n);
      in
      {
        arr = parsedState.arr;
        packets = state.packets ++ [{ inherit typ version; packets = parsedState.packets; }];
      };

  parsePacket = state:
    let
      v = fromBinaryBits (take 3 state.arr);
      arr = drop 3 state.arr;
      typ = fromBinaryBits (take 3 arr);
      arr' = drop 3 arr;
    in
    if (length state.arr) < 8 && all (e: e == 0) state.arr then state // { arr = [ ]; }
    else if typ == types.lit then (parseLiteral (state // { arr = arr'; }) v 0)
    else parseOperator (state // { arr = arr'; }) v typ;

  parsePackets = arr:
    let
      parsePackets' = state:
        if (length state.arr) == 0 then state
        else parsePackets' (parsePacket state);
      parsed = parsePackets' { inherit arr; packets = [ ]; };
    in
    parsed.packets;


  sumPacketVersions = packets:
    foldl' (sum: p: sum + p.version + (if p ? packets then (sumPacketVersions p.packets) else 0)) 0 packets;

  part1Answer = filename:
    let
      data = getData filename;
      packets = parsePackets data;
    in
    sumPacketVersions packets;

  # part2 stuff
  evalPacket = p:
  if p.typ == types.sum then sum (map evalPacket p.packets)
  else if p.typ == types.prod then foldl' (acc: p: acc * p) 1 (map evalPacket p.packets)
  else if p.typ == types.min then foldl' (lhs: rhs: if lhs == null then rhs else min lhs rhs) null (map evalPacket p.packets)
  else if p.typ == types.max then foldl' (lhs: rhs: if lhs == null then rhs else max lhs rhs) null (map evalPacket p.packets)
  else if p.typ == types.lit then p.val
  else if p.typ == types.gt then if (evalPacket (elemAt p.packets 0)) > (evalPacket (elemAt p.packets 1)) then 1 else 0
  else if p.typ == types.lt then if (evalPacket (elemAt p.packets 0)) < (evalPacket (elemAt p.packets 1)) then 1 else 0
  else if p.typ == types.eq then if (evalPacket (elemAt p.packets 0)) == (evalPacket (elemAt p.packets 1)) then 1 else 0
  else throw "unrecognized type";

  part2Answer = filename:
    let
      data = getData filename;
      packets = parsePackets data;
    in
    evalPacket (head packets);
in
{
  part1 = part1Answer ./input.lines;
  part2 = part2Answer ./input.lines;
}
