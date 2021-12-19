{ pkgs, lib }:

with pkgs.lib;
with lib;

let
  percDown = idx: heap:
  # Leaf node
  if (idx * 2 + 1) > heap.size then heap
  else
  let
    val = elemAt heap.data idx;
    lhsVal = elemAt heap.data (idx * 2);
    cmpLhs = heap.cmp lhsVal val;
    hasRhs = (idx * 2 + 1) < heap.size;
    rhsVal = elemAt heap.data (idx * 2 + 1);
    cmpRhs = heap.cmp rhsVal val;
  in
  if !hasRhs then
    if cmpLhs < 0 then percDown (idx * 2) ({ inherit (heap) cmp size; data = swap heap.data idx (idx * 2); })
    else heap
  # if we're less than lhs || rhs we swap with the lesser of the two
  else if cmpLhs < 0 || cmpRhs < 0 then
    let
      lessIdx = if (heap.cmp lhsVal rhsVal) <= 0 then idx * 2 else idx * 2 + 1;
    in
      percDown lessIdx ({ inherit (heap) cmp size; data = swap heap.data idx lessIdx; })
  # in the right spot
  else heap;

  percUp = idx: heap:
    if idx == 0 then heap
    else
    let
      parentIdx = idx / 2;
      val = elemAt heap.data idx;
      parentVal = elemAt heap.data parentIdx;
    in
    if (heap.cmp parentVal val) > 0 then percUp parentIdx ({ inherit (heap) cmp size; data = swap heap.data idx parentIdx; })
    else heap;
in
rec {
  # mkHeap returns a max binary heap which may be used with the other functions
  # in this library.
  mkHeap = cmp: { inherit cmp; data = []; size = 0; };

  # min returns the minimum element on the heap (O(1))
  min = heap: head heap.data;

  # pop removes the minimum element
  # it returns an attr of { heap = heapWithMinRemoved; val = minVal; }
  pop = heap:
  if (length heap.data) == 1 then { val = min heap; heap = { cmp = heap.cmp; size = 0; data = []; }; }
  else
  let
    val = min heap;
    # Swap in the last element
    heap' = { cmp = heap.cmp; size = heap.size - 1; data = [ (elemAt heap.data (heap.size - 1)) ] ++ (sublist 1 (heap.size - 2) heap.data); };
    # Reheapify
    heap'' = percDown 0 heap';
  in
  { inherit val; heap = heap''; };

  # insert a value
  insert = heap: el:
  let
    heap' = { cmp = heap.cmp; size = heap.size + 1; data = heap.data ++ [ el ]; };
  in
    percUp heap.size heap';
}
