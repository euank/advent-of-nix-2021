## Advent of Nix 2021

This is my attempt to solve all the [Advent of Code 2021](https://adventofcode.com/2021) problems in pure nix.

I wasn't trying to make efficient solutions, just efficient enough to complete
and get me a successful answer. This was primarily to just play around with
nix, not to code golf or do anything fancy.

### Running solutions

In general, `nix eval '.#dayX'` (where 'X' is the number of the day, padded to length 2, such as
`nix eval '.#day03'`) will display the answer to a given day.

### Specific day's notes

#### day 05

This one is the first one where the performance is _bad_. Really bad.

Bad enough that you need to run it specially:

```
$ ulimit -s unlimited
$ nix eval '.#day05.part1'
$ nix eval '.#day05.part2'
```

Running the parts separately helps, and removing the stack size limit is needed for part 2.

On my computer, it takes around 4 minutes to complete.
It takes more than 15GiB of memory as well.

I may come back to this one to optimize the solution further since having to
increase the stack size seems far from ideal.

#### day 13 - part 2

This is the first part where the answer needs specific formatting.

Using `--raw` or `--json | jq '.' -r` will provide correct formatting. For example:

```
$ nix eval '.#day13.part2' --raw
```

Also, you need a fixed width terminal, but that's kinda a given.
