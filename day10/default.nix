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
in
{
  part1 = scoreChars (mismatchedLineChars lines);
}
