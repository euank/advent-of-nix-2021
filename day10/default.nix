{ lib, pkgs }:
with pkgs.lib;
with lib;
let
  data = fileContents ./input.lines;
  lines = map stringToCharacters (splitString "\n" data);

  pairs = {
    "{" = "}";
    "[" = "]";
    "<" = ">";
    "(" = ")";
  };
  isOpening = c: c == "{" || c == "[" || c == "(" || c == "<";
  isClosing = c: ! (isOpening c);

  findMismatchedChar = lineChars:
    let
      f = stack: chars:
        if (length chars) == 0 then null
        else
          let
            c = head chars;
            closing = isClosing c;
          in
          if closing && (c != (head stack)) then c
          else if closing then f (tail stack) (tail chars)
          # else opening, add expected closing to the stack
          else f ([ pairs."${c}" ] ++ stack) (tail chars);
    in
    f [ ] lineChars;

  mismatchedLineChars = lines: foldl' (acc: line: let c = findMismatchedChar line; in if c == null then acc else acc ++ [ c ]) [ ] lines;

  scores = {
    ")" = 3;
    "]" = 57;
    "}" = 1197;
    ">" = 25137;
  };

  scoreChars = cs: foldl' builtins.add 0 (map (c: scores."${c}") cs);

  # Part 2
  # So, the root of the problem is "what completes a line"
  # The answer really is just whatever's on the stack because of how we structured this
  # To avoid breaking part1, copy+paste and modify

  # Filter to what we need
  incompleteChar = lines: filter (l: (findMismatchedChar l) == null) lines;

  findMissingChars = lineChars:
    let
      f = stack: chars:
        # No chars, just return the stack
        if (length chars) == 0 then stack
        else
          let
            c = head chars;
            closing = isClosing c;
          in
          if closing && (c != (head stack)) then throw "Mismatched char, oh no"
          else if closing then f (tail stack) (tail chars)
          # else opening, add expected closing to the stack
          else f ([ pairs."${c}" ] ++ stack) (tail chars);
    in
    f [ ] lineChars;

  missingChars = lines: map findMissingChars (incompleteChar lines);

  p2scores = {
    ")" = 1;
    "]" = 2;
    "}" = 3;
    ">" = 4;
  };
  scorePart2Line = line: foldl' (acc: c: acc * 5 + p2scores."${c}") 0 line;
  scorePart2Chars = lineChars: map scorePart2Line lineChars;

  middleScore = scores:
    let
      ss = sort lessThan scores;
    in
    elemAt ss ((length ss) / 2);
in
{
  part1 = scoreChars (mismatchedLineChars lines);
  part2 = middleScore (scorePart2Chars (missingChars lines));
}
