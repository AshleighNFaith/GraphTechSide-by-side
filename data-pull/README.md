# Build the Dataset

When starting this series, one of the tasks I spent the most time researching was how to pull a dataset, what to keep, how to understand it, and how to prepare it for a graph database.

This directory contains the final Python script used to pull the IMDb dataset, along with notes to help you understand the process.



## Accompanying YouTube Video

_Soon to be linked here._

## Prerequisites

- Basic Python knowledge
- Basic understanding of Pandas


## Seed Pairs File

The seed pairs file contains the initial IMDb title pairs used to pull and prepare the dataset for the graph database. The seed pairs will help us narrow down our dataset and guarentee bankable pair results.

- **The prolific, consistently strong pair** — many shared films, high scores across the board. This is the clean, obvious "yes, this is a `BankablePair`" case.
- **The prolific but uneven pair** — several shared films, mixed scores. Confirms the model is scoring quality, not just counting collaborations.
- **The small-sample high scorer** — only 2 films together, both scored well. A borderline case for wherever the "minimum shared films" threshold gets set.
- **The one-and-done outlier** — a single strong film together, never repeated. Deliberately excluded by the ≥2-films rule, and a useful example for explaining why frequency matters, not just quality.
- **A trend-over-time pair** — quality rises or falls across a career (strong early films, weaker later ones, or the reverse). This is the case where a simple average hides an interesting pattern.
- **At least one Actor–Actor pair**, not just Actor–Director — confirms the pairing logic generalizes rather than being hardcoded to one relationship type.



These mixed types will help us test the hypothosis since we can work backwards fro stated claims already made. This also can help show how a KG helps ground AI claims at a future date.
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

## Dependencies 

The required Python packages are listed in the repository's [`requirements.txt`](../requirements.txt) file.

## Setup

Before running the script, create and activate a virtual environment, then install the required packages.

### macOS / Linux

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```
