{ pkgs, lib }:
with pkgs;
with lib;
let
  swap1 = arr: i: j:
    builtins.genList (idx: let idx' = if idx == i then j else if idx == j then i else idx; in builtins.elemAt arr idx') (builtins.length arr);

  swap2 = arr: i: j:
    if i > j then swap2 arr j i
    else (pkgs.lib.sublist 0 i arr) ++ [ (builtins.elemAt arr j) ] ++ (pkgs.lib.sublist (i + 1) (j - i - 1) arr) ++ [ (builtins.elemAt arr i) ] ++ (pkgs.lib.sublist (j + 1) ((builtins.length arr) - j - 1) arr);

  swap3 = arr: i: j:
    pkgs.lib.imap0 (idx: v: if idx == i then (builtins.elemAt arr j) else if idx == j then (builtins.elemAt arr i) else v) arr;

  testArr = builtins.genList (i: i * 10) 3000;

  benchSwap = swap: builtins.deepSeq (builtins.foldl' (acc: _: swap acc 100 800) testArr (pkgs.lib.range 0 5000)) "done";
in
{
  swap1 = benchSwap swap1;
  swap2 = benchSwap swap2;
  swap3 = benchSwap swap3;
}
