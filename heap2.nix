{ pkgs, lib }:

with pkgs.lib;
with lib;

let
  percDown = heap: node:
  let
    cmpLhs = heap.cmp node.val node.lhs.val;
    cmpRhs = heap.cmp node.val node.rhs.val;
    cmpLhsRhs = heap.cmp node.lhs.val node.rhs.val;
  in
  # Leaf node, we're as far down as we go
  if isLeaf node then node
  # rhs null, only check lhs
  # If we're greater than lhs, we should perc down one more layer. Swap vals and perc down.
  else if node.rhs == null && cmpLhs > 0 then node // { val = node.lhs.val; lhs = percDown heap (node.lhs // { val = node.val; }); }
  # no rhs node, and we're already far enough down
  else if node.rhs == null then node
  # both nodes, but we're down far enough
  else if cmpLhs <= 0 && cmpRhs <= 0 then node
  # Otherwise, swap with the lesser of the two
  else if cmpLhsRhs < 0 then node // { val = node.lhs.val; lhs = percDown heap (node.lhs // { val = node.val; }); }
  else node // { val = node.rhs.val; rhs = percDown heap (node.rhs // { val = node.val; }); };

  percUp = size: heap: node:
  if size == 0 || size == 1 then node
  else
  let
    f = lr: node:
    let
      goRight = head lr;
      childNode = if goRight then f (tail lr) node.rhs else f (tail lr) node.lhs;
    in
    if (length lr) == 0 then node
    # if the child perc'd up node is less than us, perc it up one more.
    else if (heap.cmp childNode.val node.val) < 0 then node // ({ val = childNode.val; }) // (if goRight then { rhs = childNode // { val = node.val; }; } else { lhs = childNode // { val = node.val; }; })
    # Otherwise, we're in the right place already
    else node;
    binaryDigits = tail (toBaseDigits 2 size);
  in
    f (map (d: d == 1) binaryDigits) node;

  isLeaf = node: node.lhs == null && node.rhs == null;

  removeLastVal = size: node:
  let
    f = lr: node:
      let
        removeRhs = f (tail lr) node.rhs;
        removeLhs = f (tail lr) node.lhs;
        goRight = head lr;
      in
        if (length lr) == 0 then { val = node.val; node = null; }
        else if goRight then { node = node // { rhs = removeRhs.node; }; val = removeRhs.val; }
        else { node = node // { lhs = removeLhs.node; }; val = removeLhs.val; };
    # To figure out where to navigate in our complete tree, we can look at the
    # size base2 of our target size, ignoring our root.
    binaryDigits = tail (toBaseDigits 2 size);
  in
    f (map (d: d == 1) binaryDigits) node;

  addLastVal = size: node: val:
  let
    f = lr: node:
      let
        goRight = head lr;
      in
        if (length lr) == 0 then { lhs = null; rhs = null; inherit val; }
        else if goRight then node // { rhs = f (tail lr) node.rhs; }
        else node // { lhs = f (tail lr) node.lhs; };
    # Same as above, but our new goal size.
    binaryDigits = tail (toBaseDigits 2 (size + 1));
  in
    f (map (d: d == 1) binaryDigits) node;
in
rec {
  # mkHeap returns a min binary heap which may be used with the other functions
  # in this library.
  mkHeap = cmp: { inherit cmp; root = null; size = 0; };

  # min returns the minimum element on the heap (O(1))
  min = heap:
  if heap.size == 0 then throw "heap: cannot pop empty heap"
  else heap.root.val;

  # pop removes the minimum element
  # it returns an attr of { heap = heapWithMinRemoved; val = minVal; }
  pop = heap:
  if heap.size == 1 then { val = min heap; heap = { cmp = heap.cmp; size = 0; root = null; }; }
  else
  let
    val = min heap;
    # Remove the last node and get its value so we can swap it into the root.
    lastVal = removeLastVal heap.size heap.root;
    # Put the last val in as the root val and reheapify
    heap' = { cmp = heap.cmp; size = heap.size - 1; root = lastVal.node // { val = lastVal.val; }; };
    # Reheapify
    heap'' = heap' // { root = percDown heap' heap'.root; };
  in
  { inherit val; heap = heap''; };

  # insert a value
  insert = heap: el:
  let
    heap' = { cmp = heap.cmp; size = heap.size + 1; root = addLastVal heap.size heap.root el; };
  in
  heap' // { root = percUp heap'.size heap' heap'.root; };
}
