{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  getData = filename:
    let
      data = fileContents filename;
      parts = splitString "\n\n" data;
      chars = stringToCharacters (elemAt parts 0);
      replacementsList = map (l: splitString " -> " l) (splitString "\n" (elemAt parts 1));
      replacements = listToAttrs (map (pair: nameValuePair (elemAt pair 0) (elemAt pair 1)) replacementsList);
    in
    { inherit chars replacements; };

  step = chars: replacements:
    let
      fst = head chars;
      pairs = zipLists chars (tail chars);
      insertPair = pair: if replacements ? "${pair.fst}${pair.snd}" then "${replacements."${pair.fst}${pair.snd}"}${pair.snd}" else pair.snd;
      replacedPairs = concatMapStrings insertPair pairs;
    in
    stringToCharacters (fst + replacedPairs);

  # Surely there's a stdlib way to do this? Right?
  countListOccurances = list: foldl' (acc: el: acc // { "${el}" = 1 + (attrByPath [ "${el}" ] 0 acc); }) { } list;

  mergeCounts = l: zipAttrsWith (k: vals: foldl' builtins.add 0 vals) l;

  # state is of type:
  # { timesLeft = int; chars []char; replacements = { key = replacement; }; }
  # memo is "${pair.fst}${pair.snd}${timesLeft}" = answer
  # returns { memo = memo; counts = counts; }
  countCharsMemo = memo: state:
    let
      inherit (state) timesLeft chars replacements;
      key = s: "${elemAt s 0}${elemAt s 1}${toString timesLeft}";
    in
    if timesLeft == 0 then { inherit memo; counts = countListOccurances chars; }
    else if (length chars) == 2 && memo ? "${key chars}" then { inherit memo; counts = memo."${key chars}"; }
    else
      let
        # Step once
        expandedPair = step chars replacements;
        # Split into sub-pairs
        subPairs = zipLists expandedPair (tail expandedPair);
        # Get the answers for each of these pairs, including memoization.
        subResult = foldl'
          (acc: pair:
            let
              sub = countCharsMemo acc.memo { timesLeft = acc.timesLeft; chars = [ pair.fst pair.snd ]; inherit replacements; };
            in
            {
              timesLeft = acc.timesLeft;
              counts = mergeCounts [ acc.counts sub.counts ];
              memo = acc.memo // sub.memo;
            })
          { inherit memo; counts = { }; timesLeft = timesLeft - 1; }
          subPairs;
        # This double counted though, so subtract out the double counted chars
        minusCounts = mergeCounts (map (el: { "${el}" = -1; }) (init (tail expandedPair)));
        finalCount = mergeCounts [ subResult.counts minusCounts ];
      in
      { memo = subResult.memo // { "${key chars}" = finalCount; }; counts = finalCount; };

  countChars = times: str: replacements:
    countCharsMemo { } { timesLeft = times; chars = (stringToCharacters str); inherit replacements; };

  answer = filename: iters:
    let
      data = getData filename;
      replacements = data.replacements;
      chars = data.chars;

      counts = attrValues (countChars iters (concatStrings chars) replacements).counts;
      mostCommon = foldl' max 0 counts;
      leastCommon = foldl' min (head counts) counts;
    in
    mostCommon - leastCommon;
in
{
  part1 = answer ./input.lines 10;
  part2 = answer ./input.lines 40;
}
