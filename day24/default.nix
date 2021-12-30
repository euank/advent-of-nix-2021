{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  getData = filename:
    let
      data = fileContents filename;
      lines = splitString "\n" data;
      parseInstruction = line:
        let
          parts = splitString " " line;
          op = elemAt parts 0;
        in
        if op == "inp" then { inherit op; store = elemAt parts 1; }
        else { inherit op; store = elemAt parts 1; arg = elemAt parts 2; };
    in
    map parseInstruction lines;

  # For posterity, I wrote an ALU simulator and simplifier for the instructions, spent some time waiting on a brute force, gave up, and then ran through the simplified instructions by hand.
  #
  # That let me notice there are 3 constants and the block is otherwise repeated, and the blocks all look like so, with C1..C3 being the constants.
  #
  # if (prevZ % 26 + C2 == W) {
  #   if (C1 == 26) {
  #     z = prevZ / 26
  #   } else {
  #     z = prevZ
  #   }
  # } else {
  #   if (c1 == 26) {
  #     z = prevZ + W + C3
  #   } else {
  #     z = prevZ * 26 + W + C3
  #   }
  # }
  #
  # I noticed that:
  #
  # 1. At each input step, we depend on the previous value of Z and the input only.
  # 2. The value of Z only increases and decreases by small amounts at once (i.e. mul or div 26, and small constants)
  #
  # From that, I decided to try and bruteforce it again, which is what we've got below. Which works this time.
  # My pen-and-paper notes for figuring the above out aren't getting captured here, oh well.
  #
  # I feel like I'm still missing something a little more clever, but I'm happy enough with what I've got. It works.

  # Parse out the C1..C3 variables
  getConsts = data: map (chunk: { c1 = toInt (elemAt chunk 4).arg; c2 = toInt (elemAt chunk 5).arg; c3 = toInt (elemAt chunk 15).arg; }) (map (i: sublist (i * 18) 18 data) (range 0 13));

  # Calculate z for a step
  z = w: prevZ: consts:
    if (mod prevZ 26) + consts.c2 == w then if consts.c1 == 26 then prevZ / 26 else prevZ
    else if consts.c1 == 26 then prevZ + w + consts.c3 else prevZ * 26 + w + consts.c3;


  # bruteforce max
  findMaxAnswer = ws: curZ: consts:
    let
      # count how many times there's a `/ 26` possibly left to get an upper bound on 'z' values.
      numDivsLeft = sum (map (c: if c.c1 == 26 then 1 else 0) consts);
      # Limit z so that we can definitely get it back down to 0. Since we only
      # divide by 26 / subtract a small constant to reduce it, we can limit it
      # pretty heavily.
      maxZ = pow 26 (numDivsLeft) + 20 * (length consts);
      nextWs = range 1 9;
    in
    if (length consts) == 0 && curZ == 0 then ws
    else if (length consts) == 0 then null
    else foldl' (best: w: let
      z' = z w curZ (head consts);
      ww = findMaxAnswer (ws * 10 + w) z' (tail consts);
    in
    if z' > maxZ then best else if ww != null && ww > best then ww else best) 0 nextWs;


  part1Answer = filename:
    let
      consts = getConsts (getData filename);
    in
    findMaxAnswer 0 0 consts;


  # Bruteforce min.
  findMinAnswer = ws: curZ: consts:
    let
      # count how many times there's a `/ 26` possibly left to get an upper bound on 'z' values.
      numDivsLeft = sum (map (c: if c.c1 == 26 then 1 else 0) consts);
      # Limit z so that we can definitely get it back down to 0. Since we only
      # divide by 26 / subtract a small constant to reduce it, we can limit it
      # pretty heavily.
      maxZ = pow 26 (numDivsLeft) + 20 * (length consts);
      nextWs = range 1 9;
    in
    if (length consts) == 0 && curZ == 0 then ws
    else if (length consts) == 0 then null
    else foldl' (best: w: let
      z' = z w curZ (head consts);
      ww = findMinAnswer (ws * 10 + w) z' (tail consts);
    in
    if z' > maxZ then best else if ww != null && ww < best then ww else best) 99999999999999 nextWs;

  part2Answer = filename:
    let
      consts = getConsts (getData filename);
    in
    findMinAnswer 0 0 consts;

in
{
  part1 = part1Answer ./input.lines;
  part2 = part2Answer ./input.lines;
}
