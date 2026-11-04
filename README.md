# netgamut-networks

Network files for [netgamut](https://github.com/mapequation/netgamut) that it
can't fetch from an upstream source as they are. They come in two parts:

- **Stored files**, on `main`: networks with no public source, kept byte for
  byte. See [Stored files](#stored-files).
- **The web mirror**, on the `mirror` branch: Netzschleuder, KONECT and SNAP
  networks converted to gzipped Pajek, so a web page can load them. See
  [Web mirror](#web-mirror).

This repository was called `networks-store` until November 2026. GitHub
redirects the old name.

## Web mirror

The upstream hosts don't let a web page read their files, so the netgamut
[catalog explorer](https://mapequation.org/netgamut/explorer.html) can't hand a
network straight to the [Network Navigator](https://mapequation.org/navigator/).
The mirror fills that gap. Each month, `.github/workflows/mirror.yml` runs
`netgamut export-networks`, which works as follows:

- It converts networks from all three sources in one size order, smallest
  first, until 4 GB is spent.
- It keeps every file under 95 MB, since GitHub refuses files of 100 MiB.
- It downloads again only networks whose catalog entry changed, so a month
  without upstream changes commits nothing.
- It works in slices of 45 minutes and commits each slice to the `mirror`
  branch before starting the next. A run that reaches the job's time limit
  starts the next run itself, which continues where it stopped. Until a run
  gets through every network, the manifest's `complete` is false.

The manifest lists each network with its file, size, node and link counts,
direction and citations, and says why each other one was left out:

```
https://raw.githubusercontent.com/mapequation/netgamut-networks/mirror/index.json
```

A `file` path in the manifest is relative to the manifest. Each file opens with
`#` comment lines that name its source and how to cite it.
raw.githubusercontent.com serves the files with
`Access-Control-Allow-Origin: *`, but without a `Content-Encoding` header, so a
reader decompresses them itself, for example with `DecompressionStream("gzip")`.

Node ids are the source's own. They are not renumbered 1..N, so a node keeps
the id the source gave it in every subgraph of a dataset, such as the
snapshots of a temporal network, even in one where it has no links. This means
ids can start at 0 and skip numbers, and `*Vertices N` counts the vertex lines,
not the largest id. Read nodes by id, as Infomap does; a comment line in each
file gives its id range. For a dataset with several subgraphs, the mirror holds
the one netgamut loads by default.

The networks belong to their authors and the collections that publish them. The
mirror only changes their format, so cite the original as each file says. To
have a network removed, open an issue.

## Stored files

Network files that have no public source: data processed in our own papers,
benchmark inputs that cannot be regenerated, and processed versions of public
data that we cannot reproduce from the raw data. Networks with a public source
are not stored here; netgamut fetches them from that source. netgamut is also
where generators live, so synthetic networks are not stored here either. For
example, the overlapping-community memory networks used by the Infomap
benchmarks come from
`netgamut.generate.overlapping_memory_benchmark(om, E, seed=1)`.

Files are stored as they were used, byte for byte. `SHA256SUMS` pins every file;
check a fetched copy with `shasum -a 256 -c SHA256SUMS`.

Some of these files are derived from third-party data; each section below names
the source as far as it is known.


### `first-order/`

| file | network | used by |
|---|---|---|
| `netscicoauthor2010.net` | co-authorship among network scientists, 2010; 552 nodes, 1,318 weighted undirected edges (weights like 1/3) | the Infomap columnar benchmark until 2026-10-10; it now uses netzschleuder's `netscience` |

Where this file came from is not yet documented here. Its authors overlap
netzschleuder's `netscience` (2006): 422 of its 546 distinct names appear
there, so it is a later compilation, not a subset.

Two other first-order files were hosted here until 2026-10-10 and have been
removed from the history: a journal citation network derived from licensed
Journal Citation Reports data, and a network of Swedish political blogs whose
labels name individuals with their party. The Infomap benchmark replaced them
with netzschleuder's `word_assoc` and `polblogs`.

### `memory/`

Rosvall et al., *Memory in network flows and its effects on spreading dynamics
and community detection*, Nature Communications 5, 4630 (2014). Supplementary
Note 1 describes the processing. Trigram files have one line per `i j k weight`.
A line `i i j w` is a self-memory trigram: it marks `w` pathways starting at `i`
and is used only for the teleportation weights.

| file | network | used by |
|---|---|---|
| `air2011/air2011-trigrams.txt` | US airline itineraries from DB1B (BTS), first three quarters of 2011: 464 airports, 335,111 trigrams, total weight 44,823,256 including the self-memory trigrams | source of `air30k.net` |
| `air2011/air30k.net` | second-order state network on the 183 airports kept in the paper: 13,213 state nodes, 264,989 links, total weight 24,072,258 | the paper; the Infomap columnar benchmark used it until 2026-10-10 and now rebuilds it from DB1B (below) |
| `enron/enron-trigrams.txt` | Enron email threads: 146 users (144 present), 2,948 trigrams | — |
| `taxi/taxi-trigrams.txt` | Uber taxi trajectories in San Francisco on a hexagonal grid: 416 cells, 8,396 trigrams | — |

`air30k.net` is exactly `air2011-trigrams.txt` with the self-memory trigrams
dropped and every trigram restricted to the 183 airports in its `*Vertices`
list. Every link and weight agrees. Airport names are the BTS names with spaces
removed. No passenger threshold we tried on the trigram file (legs in, out or
both, itinerary origins, transfers) selects exactly these 183, so the list is
defined by the file.

The trigram file can be rebuilt from the public DB1B coupons almost, but not
exactly. `netgamut.paths.load("db1b-coupon", year=2011, quarter=q)` for
`q = 1, 2, 3` returns passenger-weighted itineraries. Turning each one into its
triples, plus one self-memory trigram per itinerary, gives the same 464 airports
and the same totals to within 0.0005%: total weight 44,823,463 against
44,823,256, and 19,414,511 path-start passengers against 19,415,369. (Weighted
by itinerary count instead of passengers, the totals are far off.) Still, 6,601
trigrams differ, and restricted to the 183 airports that makes 5,786 of 264,989
`air30k.net` links, moving 0.11% of the weight. Open-jaw gaps are not the cause:
the 2011 Q1–Q3 coupons contain none. The likeliest causes are later BTS
revisions or an unrecorded cleaning step. So `air30k.net` is kept here as the
exact file.

The Infomap columnar benchmark uses the rebuild anyway. It is reproducible from
public data, and on the benchmark's three configurations it gives codelengths
within 0.1% and run times within 4% of `air30k.net`, with partitions as close to
the original's as two seeds of the same network are to each other. The rebuild is
in Infomap's `columnar_wip/fetch-benchmark-networks.py` (mapequation/infomap#1136),
with the 183 airports listed by IATA code in `columnar_wip/air30k-airports.tsv`.
