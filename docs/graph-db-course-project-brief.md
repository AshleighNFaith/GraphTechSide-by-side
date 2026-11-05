# Graph Database Bake-Off — Course Project Brief

**Purpose:** Internal working brief for a YouTube course comparing graph databases (RDF + LPG) using one consistent scenario, dataset, and exercise list across every tool. This is the document the internship uses for every episode.

---

## 1. The Scenario: "Bankable Lineups" — Casting Intelligence for a New Studio

**Narrative for viewers:** *You've just been hired as the first data engineer at a new film studio. Before the studio greenlights a project, leadership wants a data-backed answer to one question: "can we predict which combinations of actors and directors actually tend to produce well-reviewed films for proposed cast/director lineup for projects?" Your job is to build a knowledge graph of people, movies, and critic scores that can surface repeat collaborators, measure how well their pairings score, and flag which lineups look "bankable." You will build the same graph eight times (or however we can get through), once per database, to see how each one handles trend-detection and prediction-flavored queries.*

### Example entity model (same logical model, expressed natively in each tool)

- **Person** (actor, director, producer) — name, birth year, country
- **Movie** — title, release year, runtime, critic score, vote/review count, budget (optional)
- **Genre** — name (light taxonomy: e.g. `Documentary ⊑ Film`, `Anime ⊑ Film`)
- **Studio** — name, country
- Relationships: `ACTED_IN`, `DIRECTED`, `PRODUCED`, `HAS_GENRE`, `RELEASED_BY` (studio)
- **Derived/analytical concept — "Pairing":** any Actor–Director (or Actor–Actor) combination that has shared 2+ films.

### RDF/OWL layer (for GraphDB, TopQuadrant, Stardog, RDFox)
A small ontology + rule set sits on top of the same data:
- Class hierarchy: `Film` → `Documentary`, `Feature`, `Short`
- Inverse properties: `hasActor` / `actedIn`
- **Headline inference rule:** a derived class `BankablePair` — any Person–Person or Person–Director pairing with ≥2 shared films AND an average critic score above a threshold gets classified as `BankablePair` via a reasoning rule (RDFox datalog rule, GraphDB rule file, Stardog/SWRL-style rule).

### LPG layer (ArangoDB, Memgraph, TigerGraph, Neo4j)
Same entities as labeled nodes + typed relationships. The equivalent of the inference step is an aggregation query: group shared films by pairing, compute average score and film count, filter for the "bankable" threshold. The RDF stores derive the classification via reasoning; the LPG stores compute it via query: a distinction between the two paradigms worth demonstrating side by side as we go through these.

---

## 2. Datasets (open & free)

**[IMDb non-commercial datasets](https://developer.imdb.com/non-commercial-datasets/)** officially free for non-commercial/educational use, includes `title.ratings` (average rating + vote count, your critic-score proxy) and `title.principals`/`name.basics` (full cast & crew per title) — everything you need for the pairing analysis, cleanly licensed.

I wanted to use something like Rotten Tomatos for their scores but RT has no public data API, so we will need to create a generic "critic score" instead and just be careful not to name it RT since we can't use that. We can brainstorm how we want to gather data like this if IMBD doesn't work out.

**Optional enrichment (bigger dataset, more metadata, license terms require confirmation):** TMDB's API/dataset (e.g. via Kaggle's "The Movies Dataset," built from TMDB) has cast, crew, and a critic-adjacent `vote_average`. TMDB's terms require attribution, and commercial use requires a separate agreement with TMDB so I have reached otu to them to see if we can use this or not, so for now, its nice to have but we wont use. 

**For the RDF ontology layer:** build the small Film/Genre class hierarchy by hand (it's only a handful of classes) or we can show how you can use AI to make one. I would rather not use AI yet in the series, but we can if you feel that will be a big improvment. 

---

## 3. Targeting the Data Pull

IMDb's non-commercial dataset is enormous (millions of titles and names). The curation task is to select a small, connected subset that contains the collaboration patterns the analysis needs to demonstrate, so every query in Section 6 returns a meaningful result rather than an empty set.

The method: start from the kinds of answers the "bankable lineup" analysis needs to produce, then identify real people/titles that produce each answer shape. Community discussions of frequent actor-director collaborations (Reddit, film forums, "actors and directors who've worked together" lists) are a useful source for identifying real-world names that fit each pattern below that we can use to narrow the scope. I have done this in the Seed-Pair section below.

- **The prolific, consistently strong pair** — many shared films, high scores across the board. This is the clean, obvious "yes, this is a `BankablePair`" case.
- **The prolific but uneven pair** — several shared films, mixed scores. Confirms the model is scoring quality, not just counting collaborations.
- **The small-sample high scorer** — only 2 films together, both scored well. A borderline case for wherever the "minimum shared films" threshold gets set.
- **The one-and-done outlier** — a single strong film together, never repeated. Deliberately excluded by the ≥2-films rule, and a useful example for explaining why frequency matters, not just quality.
- **A trend-over-time pair** — quality rises or falls across a career (strong early films, weaker later ones, or the reverse). This is the case where a simple average hides an interesting pattern.
- **At least one Actor–Actor pair**, not just Actor–Director — confirms the pairing logic generalizes rather than being hardcoded to one relationship type.

These mixed types will help us test the hypothosis sicne we can work backwards fro stated claims already made. This also can help show how a KG helps ground AI claims at a future date.

### Seed Pairs

Real-world pairs to anchor the pull around, one per category (exact scores/counts should be pulled fresh from IMDb rather than assumed. The below are directional, not final numbers):

| # | Pair | Category | Why it fits |
|---|---|---|---|
| 1 | Martin Scorsese & Leonardo DiCaprio | Prolific, consistently strong | Multiple films together, generally well-reviewed |
| 2 | Akira Kurosawa & Toshiro Mifune | Prolific, consistently strong | Large body of shared, highly regarded work |
| 3 | Christopher Nolan & Michael Caine | Prolific, consistently strong | Many films across different genres, generally well-reviewed |
| 4 | Tim Burton & Johnny Depp | Prolific but uneven | Large number of shared films with noticeably mixed reception |
| 5 | Denis Villeneuve & Timothée Chalamet | Small-sample high scorer | Two films together so far (Dune, Dune Part Two), both well-reviewed |
| 6 | Jonathan Demme & Anthony Hopkins | One-and-done outlier | Single acclaimed film (The Silence of the Lambs), no repeat collaboration |
| 7 | The Wachowskis & Keanu Reeves | Trend-over-time | The Matrix franchise starts strong and declines in reception across sequels |
| 8 | David O. Russell & Jennifer Lawrence | Trend-over-time / borderline | Several shared films with reception that varies noticeably by title |
| 9 | Robert De Niro & Al Pacino | Actor–Actor | Multiple shared films (Heat, The Irishman, Righteous Kill) with mixed reception |
| 10 | Wes Anderson & Bill Murray | Prolific, consistently strong (alternate) | Very large number of shared films, mostly well-reviewed |

This set of 10 covers every category at least once, with two alternates for "prolific, consistently strong" and "trend-over-time" in case one pair turns up thin or messy once actually pulled from IMDb.

**Practical pull procedure using the IMDb files:**

1. **Resolve each person in the seed list to an IMDb ID (`nconst`)** via `name.basics.tsv.gz`.
2. **Pull every title connecting each pair** via `title.principals.tsv.gz` (filter to rows where both people's `nconst` appear against the same `tconst`) —this is the join that finds "movies where both worked together." We can discuss if we want to show this on-camera or not. I am thinking maybe and we can decide to use it later if we like it. This simulates how someone looking to start a KG would need to look at their existing data and decide what to grab or not.
3. **Join in metadata and scores** via `title.basics.tsv.gz` (title, year, genre, type — filter to `movie`/`documentary` so the genre taxonomy has real examples) and `title.ratings.tsv.gz` (average rating + vote count, i.e the critic-score proxy).
4. **Expand one hop out**: for each pulled title, pull its other principal cast/crew too. This turns 10 isolated pairs into a connected web, which is needed for the "hypothetical lineup" and multi-hop queries later, and produces a natural pool of background people/titles not part of any seed pair, which are useful as negative examples ("why wasn't this flagged as bankable?").
5. **Seed 2–3 data-quality issues** for the cleanup exercise: introduce a duplicate Person and/or title row with a name variant (all-caps, extra middle initial, alt spelling) for one seed actor, so every tool works from identical dirty data. ALternative is to have a person with different roles (actor and director) or a title with different genres. We may want to try a few different "errors" for different videos so it stays interesting.
6. **Target size:** roughly 150–300 titles and 75–150 people. Large enough to feel real and produce genuine results.

Deliverable for this step: a single curated CSV/TSV bundle (people, titles, ratings, principal-cast join table) that every one of the 8 databases loads from.

---

## 4. Databases & Hosting Plan

| # | Database | Model | Hosting for this course | Free-tiers or tests |
|---|---|---|---|---|
| 1 | ArangoDB | LPG (multi-model) | ArangoGraph (Oasis) | Free trial credit, time-limited |
| 2 | Memgraph | LPG | Memgraph Cloud | Free trial, time-limited |
| 3 | GraphDB | RDF | Docker + free edition | No real free cloud tier so we can use a demo, I can ask them for an account since they know me, or we can choose a different DB since this one has changed a lot of the last year|
| 4 | TopQuadrant (TopBraid) | RDF/OWL | Docker/trial license | 30-day enterprise trial |
| 5 | TigerGraph | LPG | TigerGraph Cloud | Free small instance, largely persistent |
| 6 | Stardog | RDF (+ Virtual Graphs) | Stardog Cloud | Trial, time-limited |
| 7 | Neo4j | LPG | AuraDB Free | Free forever (small instance) |
| 8 | RDFox | RDF | Docker + eval license | License-gated trial |

**Later- not for Internship: Virtual graph module** Stardog/Neo4j/PuppyGraph Virtual Graphs (query external relational data as RDF/LPG, no ETL) as a seperate mini-series since there are a lot of these now. Alternative: TopQuadrant's data-virtualization layer, not the same, but sort of.

---

## 5. The Standard Lab Workflow (same 12 steps, every database)

1. **Provision** — spin up the instance, time it, note friction
2. **Connect** — native browser/workbench/CLI/driver
3. **Load the data model** — LPG: labels, relationship types, constraints. RDF: import the OWL/RDFS ontology
4. **Load instance data** — bulk import the IMDb subset (titles + cast/crew + ratings)
5. **Sanity check** — counts + one basic query
6. **Update instance data** — same targeted edit everywhere (e.g., correct a movie's release year)
7. **Data cleanup** — same messy-data fix everywhere (see exercise 3 below)
8. **Update the model** — add `Award` entity/class + `WON_AWARD` relationship, reconcile existing data
9. **Run the same inference/query** — see exercise 6 below
10. **AI feature spotlight** — if the tool has one (see exercise 7 below)
11. **Fill out comparison worksheet** — setup time, syntax sample, learning curve, gotchas
12. **Record** — cheat-sheet + screen capture

---

## 6. The Seven Exercises, Made Concrete

| Exercise | Concrete task in "Bankable Lineups" |
|---|---|
| Load instance data | Import an IMDb subset — a curated few thousand titles + their full cast/crew + ratings |
| Update instance data | Correct a known-wrong critic score or release year on 1 movie; add a missing `ACTED_IN` edge |
| Data cleanup | Resolve 2–3 duplicate Person records -or whichever errors we added in to show this (i.e. same actor, inconsistent name spelling/casing) — same duplicate pair used in every tool. An uncleaned duplicate splits a real pairing's film count and skews the "bankable" calculation |
| Load a data model | LPG: constraints/indexes. RDF: import the small Film/Genre OWL ontology |
| Update a model | Add a `CriticReview` or `BoxOffice` type/property set, backfill a few instances — simulates the studio deciding it wants a richer success signal than one score |
| Run the same inference/query | "Which Actor–Director pairs have ≥2 shared films, and what's their average score vs. each person's solo average?" RDF stores: materialize `BankablePair` via a reasoning rule. LPG stores: same answer via an aggregation query. Bonus round: "given hypothetical Actor X + Director Y, do they have any shared history, and what would a lineup with them likely score?" |
| AI ability (if present) | Vector similarity: "find historical pairings similar in profile to this proposed lineup" using each tool's native vector/embedding or GenAI feature (Neo4j vector index, Memgraph MAGE, GraphDB/Stardog GenAI query assistants, TigerGraph CoPilot, etc.) |

---

## 7. Per-Tool Worksheet Template (these are here to help guide your notes for each database. We can add these at the end fo the video, similar to how I add notes on-screen in the honest review series)

- Database & version
- Hosting type used (free-forever / trial — note expiry date if trial)
- Setup time (start to first successful query)
- Data model load — syntax sample + screenshot
- Instance data load — method + time + row/triple count
- Update exercise — syntax sample
- Cleanup exercise — syntax sample + before/after
- Model update — syntax sample
- Inference/query — syntax sample + result count
- AI feature — yes/no, what it does, syntax/UI sample
- Gotchas / rough edges
- One-line "what you see were the perks for this specific tool over the other ones, without namiming others in the comparison"

---

## 8. Course Repository & Output Specification

All course materials are published to a public GitHub repository so viewers can reproduce the setup for each database themselves.

### Licensing constraint that shapes the repo structure

IMDb's non-commercial dataset terms prohibit altering, republishing, or repurposing the data to create another database of movie information, and IMDb's own support guidance treats a monetized publication as commercial use regardless of intent. This means **the curated IMDb-derived dataset itself should not be committed to the public repo.**

Instead, **commit the code that builds the dataset, not the dataset.** The repo ships a script that downloads the official IMDb files directly from `https://datasets.imdbws.com/`, applies the seed-pair filtering and one-hop expansion described in Section 3, and writes the curated CSV/TSV bundle to a local, git-ignored folder. Each viewer runs the script themselves and accepts IMDb's terms directly, the same way anyone using the raw dataset does. The same approach applies if TMDB data is ever added later.

Two related requirements that this workaround doesn't automatically cover, so they need to be handled separately:

- **Attribution.** IMDb's terms require the acknowledgment "Information courtesy of IMDb (https://www.imdb.com)" wherever the data is used, independent of whether the raw files are redistributed. This belongs in the repo README and in video descriptions.
- **Illustrative examples only.** Sample rows or query-result screenshots in the README or worksheets should stay small enough to explain a pattern, not large enough to function as a stand-in for the dataset itself.

### Repository structure

```
graph-db-bakeoff/
├── README.md                     — project overview, scenario summary, how to reproduce
├── LICENSE                        — license for the repo's own code (e.g. MIT)
├── docs/
│   ├── project-brief.md          — this document
│   └── comparison-matrix.md      — aggregated results across all 8 databases
├── data-pull/
│   ├── seed_pairs.csv            — the 10 seed pairs and their category (Section 3)
│   ├── build_dataset.py          — downloads official IMDb files, filters/expands, writes curated bundle locally
│   └── README.md                 — how to run it, and a note on IMDb's terms
├── ontology/
│   └── film-ontology.ttl         — shared OWL/RDFS class hierarchy used by all RDF stores
├── schema/
│   └── lpg-schema.md             — shared node labels / relationship types / constraints used by all LPG stores
└── databases/
    ├── arangodb/
    ├── memgraph/
    ├── graphdb/
    ├── topquadrant/
    ├── tigergraph/
    ├── stardog/
    ├── neo4j/
    └── rdfox/
```

Each folder under `databases/` follows the same internal layout, so a viewer can compare the same step across tools by opening the same filename in a different folder:

```
databases/<name>/
├── setup.md              — provisioning steps, hosting type used, link/instructions
├── load-model.*           — data model / ontology load script or commands
├── load-data.*            — instance data load script or commands
├── update.*               — the update-instance-data exercise
├── cleanup.*              — the data cleanup exercise
├── update-model.*         — the model update exercise
├── inference-query.*      — the shared inference/query exercise
├── ai-example.*           — the AI feature exercise, if applicable
└── notes.md           — the filled-in notes worksheet from Section 7
```

File extensions vary by tool (`.cypher`, `.gsql`, `.rq`/`.sparql`, `.sh`, etc.) but the filenames stay identical across folders, which is what makes the repo itself a side-by-side comparison.

---

## 9. Open Items



- [ ] Confirm where the critic ratings will come from
- [ ] Confirm same errors per DB (same dataset for all), or different ones?
- [ ] Decide which DBs we will use (graphDB still?)
- [ ] Set the "bankable" thresholds (min shared films, min average score) that define a `BankablePair` — pick numbers that actually produce a handful of interesting hits in your curated subset so we may need to do a few runs to see what we like
- [ ] Confirm the GitHub repo name/org and whether it's public from day one or made public per-episode as each database module is finished (I vote publish as we go)
