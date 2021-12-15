{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  getData = filename:
  let
    data = fileContents filename;
    parts = splitString "\n\n" data;
    chars =  stringToCharacters (elemAt parts 0);
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

  stepTimes = times: chars: replacements:
    if times == 0 then chars
    else stepTimes (times - 1) (step chars replacements) replacements;

  # Surely there's a stdlib way to do this? Right?
  # note: stack overflows without 'ulimit -s unlimited'
  countListOccurances = list: foldl' (acc: el: acc // { "${el}" = 1 + (attrByPath [ "${el}" ] 0 acc); }) {} list;

  part1Answer = filename:
    let
      data = getData filename;
      chars = stepTimes 10 data.chars data.replacements;
      counts = attrValues (countListOccurances chars);
      mostCommon = foldl' max 0 counts;
      leastCommon = foldl' min (head counts) counts;
    in
      mostCommon - leastCommon;

  # part2
  # I think we can just memoize this, so let's try that.

  # state is of type:
  # { timesLeft = int; pair = { fst = char; snd = char; }; replacements = { key = replacement; }; }
  # memo is "${pair.fst}${pair.snd}${timesLeft}" = answer
  # returns { memo = memo; state = state; counts = counts; }
  countsForPairTimesLeft = memo: state:
  let
    inherit (state) timesLeft pair replacements;
    key = "${pair.fst}${pair.snd}${toString timesLeft}";
  in
  if memo ? "${key}" then { inherit memo; counts = memo."${key}"; }
  # base case
  else if timesLeft == 0 then { inherit state memo; counts = mergeCounts [ { "${pair.fst}" = 1; } { "${pair.snd}" = 1; } ]; }
  else
  let
    # Step once
    expandedPair = step [ pair.fst pair.snd ] replacements;
    # Split into sub-pairs
    subPairs = zipLists expandedPair (tail expandedPair);
    # Get the answers for each of these pairs, including memoization.
    subResult = foldl'
    (acc: pair: let
      sub = countsForPairTimesLeft acc.memo { timesLeft = acc.timesLeft; inherit pair replacements; };
      in
      acc // {
        counts = zipAttrsWith (k: vals: foldl' builtins.add 0 vals) [ acc.counts sub.counts ];
        memo = acc.memo // sub.memo;
      }
      )
      { inherit memo; counts = {}; timesLeft = timesLeft - 1; }
      subPairs;
    # This double counted though, so subtract out the double counted chars
    minusCounts = mergeCounts (map (el: { "${el}" = -1; }) (init (tail expandedPair)));
    finalCount = mergeCounts [ subResult.counts minusCounts ];
  in
    { memo = subResult.memo // { "${key}" = finalCount; }; counts = finalCount; };


  mergeCounts = l: zipAttrsWith (k: vals: foldl' builtins.add 0 vals) l;

  countChars = times: str: replacements:
  let
    countChars' = memo: chars:
      if (length chars) == 0 then { inherit memo; counts = {}; }
      else if (length chars) == 1 then { inherit memo; counts = { "${head chars}" = 1; }; }
      # Otherwise, merge counts of sub-pairs and remove duplicates at the edges
      else
        let
          pairs = zipLists chars (tail chars);
          minusCounts = mergeCounts (map (el: { "${el}" = -1; }) (init (tail chars)));
          pairCounts = foldl' (acc: pair: let sub = countsForPairTimesLeft acc.memo { timesLeft = times; inherit pair replacements; }; in { memo = sub.memo; counts = mergeCounts [ acc.counts sub.counts ]; }) { inherit memo; counts = {}; } pairs;
        in
        {
          counts = mergeCounts [ pairCounts.counts minusCounts ];
        };
    in
    countChars' {} (stringToCharacters str);

  part2Answer = filename:
    let
      data = getData filename;
      replacements = data.replacements;
      chars = data.chars;

      counts = attrValues (countChars 40 (concatStrings chars) replacements).counts;
      mostCommon = foldl' max 0 counts;
      leastCommon = foldl' min (head counts) counts;
    in
      mostCommon - leastCommon;
in
{
  part1 = part1Answer ./input.lines;
  part2 = part2Answer ./input.lines;
}
