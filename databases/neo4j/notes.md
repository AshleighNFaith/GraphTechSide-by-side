# DB Notes/Worksheet — Neo4j


---

## Basic Info

- **Database & version:** Neo4j
- **Model type:** LPG
- **Hosting used:** AuraDB free tier & Neo4j Desktop
- **Video link (once uploaded to Dropbox):**
- ** YTEpisode link (once filmed):**

---

## 1. Provisioning

- **Steps taken:**
1. Formatted the data into separate Node files and Relationship files for each type.
2. Set up the database environment and created an instance
3. Added my csv files to the Import directory
4. Created constraints and loaded each file
5. Double checked node and relationship counts
6. Completed a sanity query
- **Friction / anything that didn't work as documented:**

The most friction I encountered came from learning and using the Python Driver. While the UI Data Model tool is easy to use, it is not as flexible when loading data. To use this tool effectively, the data needs to be formatted into separate Node files and Relationship files for each type of node and relationship being loaded. In the case of the movie graph I did not have a seperate relationship file for `CAST_MEMBER` and `DIRECTOR`. While I could add this with little difficulty I can see the un-flexability being an issue for more compllicapted data models and not as small and organized datasets.


The Python Driver provided more flexibility and control over the data-loading process, but it also had a steeper learning curve. I had to spend additional time understanding the driver, its syntax, and how it interacts with the database. Overall, the setup was manageable once I understood the required data structure, but the documentation and initial learning process created some friction.

---

## 2. Data Model Load

*LPG: node labels, relationship types, constraints/indexes. RDF: import the shared Film/Genre ontology from `/ontology/film-ontology.ttl`.*

- **Method used:** 

To load the contraints into Neo4j, I used the built in query tool for Neo4j desktop and the Python driver for AuraDB. The constraint commands don't create the actual Title, Person, or Genre node labels or their relationships. Neo4j doesn't require you to pre-create labels or relationship types. They are establised when you load the data. The contraints guarantee the uniqueness of each node when we do load them.

- **Code / commands:**

```
CREATE CONSTRAINT tconst IF NOT EXISTS FOR (t:Title) REQUIRE t.id IS UNIQUE;
CREATE CONSTRAINT nconst IF NOT EXISTS FOR (p:Person) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT gconst IF NOT EXISTS FOR (g:Genre) REQUIRE g.id IS UNIQUE;
```

- **Notes:**

Loading the data model is extremley simple as long as you have a thought out model before hand and understand basic Cypher syntax.

---

## 3. Instance Data Load

*Load the curated dataset built by `data-pull/build_dataset.py`.*

- **Method used:**
Cypher query tool and Neo4j Python Driver
- **Load time:**
After research 20-30 minutes for both ways

- **Row / node / triple count loaded:**
437 Person Nodes
69 Title Nodes
19 Genre Nodes
- **Code / commands:**

```
// Load in Person instance data
LOAD CSV WITH HEADERS
FROM 'file:///people.csv'
AS row

MERGE (p:Person {id: row.nconst})
SET
    p.primaryName = row.primaryName,
    p.birthYear = CASE
        WHEN row.birthYear = '\N' THEN null
        ELSE toInteger(row.birthYear)
    END,
    p.deathYear = CASE
        WHEN row.deathYear = '\N' THEN null
        ELSE toInteger(row.deathYear)
    END,
    p.primaryProfession = row.primaryProfession,
    p.knownForTitles = row.knownForTitles;

// Load in Title instance data
LOAD CSV WITH HEADERS
FROM 'file:///titles.csv'
AS row

MERGE (t:Title {id: row.tconst})
SET
  t.titleType = row.titleType,
  t.primaryTitle = row.primaryTitle,
  t.originalTitle = row.originalTitle,  
  t.isAdult = toBoolean(row.isAdult),
  t.startYear = row.startYear,
  t.runtimeMinutes = row.runtimeMinutes,
  t.genres = row.genres,
  t.averageRating = CASE
        WHEN row.averageRataing = '\N' THEN null
        ELSE toInteger(row.averageRating)
  END,
  t.numVotes = CASE
        WHEN row.numVotes = '\N' THEN null
        ELSE toInteger(row.numVotes)
  END;


// Load Genre Nodes
LOAD CSV WITH HEADERS
FROM 'file:///genres.csv'
AS row
MERGE (g:Genre {id: row.gconst})
SET
  g.genre = row.genre;


//Relationships

// role Relationships
LOAD CSV WITH HEADERS FROM 'file:///roles.csv' AS row
MATCH (p:Person {id: row.nconst})
MATCH (t:Title {id: row.tconst})



FOREACH (_ IN CASE WHEN row.category = 'director' THEN [1] ELSE [] END |
    MERGE (p)-[:DIRECTOR]->(t)
)

// If actor/actress, array has 1 element and executes.
FOREACH (_ IN CASE WHEN row.category = 'actor' OR row.category = 'actress' THEN [1] ELSE [] END |
    MERGE (p)-[:CAST_MEMBER]->(t)
)
;


//genre Relationships

LOAD CSV WITH HEADERS FROM 'file:///title_genre.csv' AS row
MATCH (g:Genre {id: row.gconst})
MATCH (t:Title {id: row.tconst})
MERGE (t)-[:GENRE]->(g)
;
```


---

## 4. Sanity Check

- **Query used:**
Find all horror genre titles. 

```
MATCH(t:Title)-[:GENRE]->(g:Genre) 
WHERE g.genre = "Horror" 
RETURN t.primaryTitle
```
- **Result:**

| Title |
|---|
| The Silence of the Lambs |
| Sleepy Hollow |
| Sweeney Todd: The Demon Barber of Fleet Street |
| Dark Shadows |
| What Happens at Night |
| The Devil in the White City |



---

## 5. Update Instance Data

*Task: correct a known-wrong release year on one movie.* 

We are updating the release year of The Irishman to be 2019.

- **Code / commands:**

```
MATCH (t:Title {primaryTitle: 'The Irishman'})
SET t.startYear = 2019
RETURN t
```

- **Before → after:**

| Title | Start Year |
|---|---:|
| The Irishman | 1978 |


| Title | Start Year |
|---|---:|
| The Irishman | 2019 |



---

## 6. Data Cleanup

*Task: resolve the seeded duplicate Person record (same actor, inconsistent name spelling/casing).*

We will resolve a duplicate Christian Bale node and merge the relationships.

- **Code / commands:**

```
# find the duplicte 
MATCH (p:Person {primaryName: 'Christian Bale'}) RETURN p

# delete node and detatch Relationships
MATCH (correct:Person {id: "nm0000288"})
MATCH (duplicate:Person {id: "duplicate_nm0000288"})

// Duplicate Person → Title
OPTIONAL MATCH (duplicate)-[:CAST_MEMBER]->(t2:Title)
MERGE (correct)-[:CAST_MEMBER]->(t2)

WITH duplicate
DETACH DELETE duplicate;
```

- **Effect on pairing counts if left uncleaned:**
actor-director pairing count before: 4
actor-director pairing count after: 2

---

## 7. Model Update

*Task: add a `Location` type/property, backfill a few instances.*


- **Code / commands:**

```
[paste here]
```

- **Notes:**
While looking at the full graph I noticed the international films were not connected with the rest of the title and person nodes. Although this was not the original goal of the graph, I wanted to look into finding bankable pairs between international actors/directors and american actors/directors. This can be done by finding international directors who create titles in the same genre as american actors. 
Note: I will be testing this using the AI query tool.


---

## 8. Inference / Query — "Bankable Pairs"

*RDF stores: materialize `BankablePair` via a reasoning rule. LPG stores: same answer via an aggregation query.*

- **Query / rule used:**

Any Person–Person and Person–Director pairing with ≥2 shared films AND an average rating greater than 7 rank by the number of votes.

```
MATCH (actor1:Person)-[:CAST_MEMBER]->(m:Title)
MATCH (actor2:Person)-[:CAST_MEMBER]->(m)
WHERE actor1 <> actor2
AND id(actor1) < id(actor2)

WITH actor1, actor2, collect(DISTINCT m) AS sharedFilms
WHERE size(sharedFilms) >= 2

WITH actor1, actor2, sharedFilms,
     reduce(total = 0.0, m IN sharedFilms | total + m.averageRating) / size(sharedFilms) AS avgRating,
     reduce(votes = 0, m IN sharedFilms | votes + m.numVotes) AS totalVotes

WHERE avgRating > 7

RETURN
    actor1.primaryName AS Actor1,
    actor2.primaryName AS Actor2,
    size(sharedFilms) AS sharedFilms,
    round(avgRating, 2) AS avgRating,
    totalVotes
ORDER BY totalVotes DESC;
```

```
MATCH (director:Person)-[:DIRECTOR]->(t:Title)
MATCH (actor:Person)-[:CAST_MEMBER]->(t)
WHERE director <> actor

WITH director, actor, collect(DISTINCT t) AS sharedFilms
WHERE size(sharedFilms) >= 2

WITH director, actor, sharedFilms,
     reduce(total = 0.0, m IN sharedFilms | total + m.averageRating) / size(sharedFilms) AS avgRating,
     reduce(votes = 0, m IN sharedFilms | votes + m.numVotes) AS totalVotes

WHERE avgRating > 7

RETURN
    director.primaryName AS Director,
    actor.primaryName AS Actor,
    size(sharedFilms) AS sharedFilms,
    round(avgRating, 2) AS avgRating,
    totalVotes
ORDER BY totalVotes DESC;
```

- **Result (pairs returned, film counts, average scores):**

**Actor-Actor Pairings**


| Actor1 | Actor2 | Shared Films | Avg Rating | Total Votes |
|---|---|---:|---:|---:|
| Christian Bale | Michael Caine | 4 | 8.25 | 8,516,010 |
| Gary Oldman | Christian Bale | 3 | 8.33 | 6,916,916 |
| Gary Oldman | Michael Caine | 3 | 8.33 | 6,916,916 |
| Morgan Freeman | Gary Oldman | 2 | 8.5 | 5,192,601 |
| Morgan Freeman | Christian Bale | 2 | 8.5 | 5,192,601 |
| Morgan Freeman | Michael Caine | 2 | 8.5 | 5,192,601 |
| Gary Oldman | Cillian Murphy | 2 | 8.5 | 4,911,500 |
| Christian Bale | Cillian Murphy | 2 | 8.5 | 4,911,500 |
| Michael Caine | Cillian Murphy | 2 | 8.5 | 4,911,500 |
| Robert De Niro | Joe Pesci | 4 | 7.75 | 2,909,338 |
| Robert De Niro | Frank Vincent | 3 | 8.0 | 2,434,042 |
| Joe Pesci | Frank Vincent | 3 | 8.0 | 2,434,042 |
| Leonardo DiCaprio | Alec Baldwin | 2 | 7.5 | 1,972,984 |
| Bill Murray | Edward Norton | 3 | 7.33 | 1,574,134 |
| Bill Murray | Willem Dafoe | 3 | 7.33 | 1,506,552 |
| Jeff Goldblum | Bill Murray | 3 | 7.33 | 1,411,838 |
| Bill Murray | Adrien Brody | 2 | 7.5 | 1,213,959 |
| Jeff Goldblum | Willem Dafoe | 2 | 7.5 | 1,199,112 |
| Jeff Goldblum | Edward Norton | 2 | 7.5 | 1,190,253 |
| Robert De Niro | Diahnne Abbott | 2 | 7.5 | 1,166,172 |
| Robert De Niro | Victor Argo | 2 | 7.5 | 1,160,913 |
| Toshirō Mifune | Takashi Shimura | 14 | 7.5 | 1,040,534 |
| Toshirō Mifune | Daisuke Katō | 3 | 8.0 | 744,429 |
| Daisuke Katō | Takashi Shimura | 3 | 8.0 | 744,429 |
| Toshirō Mifune | Minoru Chiaki | 7 | 7.57 | 726,174 |
| Minoru Chiaki | Takashi Shimura | 6 | 7.67 | 719,701 |
| Minoru Chiaki | Daisuke Katō | 2 | 8.0 | 600,687 |
| Toshirō Mifune | Kamatari Fujiwara | 5 | 7.6 | 514,808 |
| Kamatari Fujiwara | Takashi Shimura | 4 | 7.75 | 508,335 |
| Toshirō Mifune | Isao Kimura | 3 | 7.67 | 496,695 |
| Isao Kimura | Takashi Shimura | 3 | 7.67 | 496,695 |
| Minoru Chiaki | Kamatari Fujiwara | 3 | 7.67 | 455,763 |
| Toshirō Mifune | Seiji Miyaguchi | 2 | 7.5 | 418,874 |
| Kamatari Fujiwara | Seiji Miyaguchi | 2 | 7.5 | 418,874 |
| Seiji Miyaguchi | Takashi Shimura | 2 | 7.5 | 418,874 |
| Toshirō Mifune | Kichijirō Ueda | 3 | 7.67 | 264,133 |
| Minoru Chiaki | Kichijirō Ueda | 3 | 7.67 | 264,133 |
| Takashi Shimura | Kichijirō Ueda | 3 | 7.67 | 264,133 |
| Toshirō Mifune | Tatsuya Nakadai | 3 | 8.0 | 259,603 |
| Tatsuya Nakadai | Takashi Shimura | 3 | 8.0 | 259,603 |
| Toshirō Mifune | Masayuki Mori | 3 | 7.33 | 219,343 |
| Masayuki Mori | Takashi Shimura | 3 | 7.33 | 219,343 |
| Toshirō Mifune | Noriko Honma | 2 | 7.5 | 218,444 |
| Noriko Honma | Takashi Shimura | 2 | 7.5 | 218,444 |
| Toshirō Mifune | Isuzu Yamada | 3 | 7.67 | 210,720 |
| Toshirō Mifune | Hiroshi Tachikawa | 3 | 7.67 | 210,436 |
| Takashi Shimura | Hiroshi Tachikawa | 3 | 7.67 | 210,436 |
| Takashi Shimura | Isuzu Yamada | 2 | 8.0 | 204,247 |
| Hiroshi Tachikawa | Isuzu Yamada | 2 | 8.0 | 204,247 |
| Minoru Chiaki | Masayuki Mori | 2 | 7.5 | 203,717 |
| Toshirō Mifune | Eijirō Tōno | 3 | 7.33 | 171,220 |
| Takashi Shimura | Eijirō Tōno | 2 | 7.5 | 164,747 |
| Eijirō Tōno | Isuzu Yamada | 2 | 7.5 | 150,215 |
| Toshirō Mifune | Kyōko Kagawa | 4 | 7.5 | 118,089 |
| Toshirō Mifune | Takeshi Katō | 2 | 7.5 | 88,068 |
| Kyōko Kagawa | Takeshi Katō | 2 | 7.5 | 88,068 |
| Toshirō Mifune | Tatsuya Mihashi | 2 | 7.5 | 88,068 |
| Kyōko Kagawa | Tatsuya Mihashi | 2 | 7.5 | 88,068 |
| Takeshi Katō | Tatsuya Mihashi | 2 | 7.5 | 88,068 |
| Kyōko Kagawa | Takashi Shimura | 2 | 7.5 | 88,068 |
| Takeshi Katō | Takashi Shimura | 2 | 7.5 | 88,068 |
| Tatsuya Mihashi | Takashi Shimura | 2 | 7.5 | 88,068 |
| Toshirō Mifune | Eiko Miyoshi | 3 | 7.33 | 73,236 |
| Eiko Miyoshi | Takashi Shimura | 3 | 7.33 | 73,236 |
| Minoru Chiaki | Isuzu Yamada | 2 | 7.5 | 66,978 |
| Toshirō Mifune | Reiko Dan | 2 | 8.0 | 66,967 |
| Toshirō Mifune | Yûzô Kayama | 2 | 8.0 | 66,967 |
| Reiko Dan | Yûzô Kayama | 2 | 8.0 | 66,967 |
| Toshirō Mifune | Kokuten Kōdō | 2 | 7.5 | 66,783 |
| Minoru Chiaki | Kokuten Kōdō | 2 | 7.5 | 66,783 |
| Kokuten Kōdō | Takashi Shimura | 2 | 7.5 | 66,783 |
| Minoru Chiaki | Hiroshi Tachikawa | 2 | 7.5 | 66,694 |
| Hiroshi Tachikawa | Kichijirō Ueda | 2 | 7.5 | 66,694 |
| Toshirō Mifune | Masao Shimizu | 3 | 7.33 | 63,608 |
| Masao Shimizu | Takashi Shimura | 3 | 7.33 | 63,608 |
| Minoru Chiaki | Eiko Miyoshi | 2 | 7.5 | 52,231 |
| Toshirō Mifune | Akemi Negishi | 3 | 7.33 | 36,210 |
| Kyōko Kagawa | Akemi Negishi | 2 | 7.5 | 30,021 |

--- 

**Director-Actor Pairings**


| Director          | Actor             | Shared Films | Avg Rating | Total Votes |
| ----------------- | ----------------- | -----------: | ---------: | ----------: |
| Christopher Nolan | Christian Bale    |            4 |       8.25 |   8,516,010 |
| Christopher Nolan | Michael Caine     |            4 |       8.25 |   8,516,010 |
| Christopher Nolan | Gary Oldman       |            3 |       8.33 |   6,916,916 |
| Christopher Nolan | Morgan Freeman    |            2 |        8.5 |   5,192,601 |
| Christopher Nolan | Cillian Murphy    |            2 |        8.5 |   4,911,500 |
| Martin Scorsese   | Robert De Niro    |           10 |        7.3 |   4,784,532 |
| Martin Scorsese   | Joe Pesci         |            4 |       7.75 |   2,909,338 |
| Wes Anderson      | Bill Murray       |            8 |       7.13 |   2,885,060 |
| Martin Scorsese   | Frank Vincent     |            3 |        8.0 |   2,434,042 |
| Martin Scorsese   | Alec Baldwin      |            2 |        7.5 |   1,972,984 |
| Wes Anderson      | Edward Norton     |            3 |       7.33 |   1,574,134 |
| Wes Anderson      | Willem Dafoe      |            3 |       7.33 |   1,506,552 |
| Wes Anderson      | Jeff Goldblum     |            3 |       7.33 |   1,411,838 |
| Wes Anderson      | Adrien Brody      |            2 |        7.5 |   1,213,959 |
| Martin Scorsese   | Diahnne Abbott    |            2 |        7.5 |   1,166,172 |
| Martin Scorsese   | Victor Argo       |            2 |        7.5 |   1,160,913 |
| Akira Kurosawa    | Toshirō Mifune    |           16 |        7.5 |   1,070,555 |
| Akira Kurosawa    | Takashi Shimura   |           14 |        7.5 |   1,040,534 |
| Akira Kurosawa    | Daisuke Katō      |            3 |        8.0 |     744,429 |
| Akira Kurosawa    | Minoru Chiaki     |            7 |       7.57 |     726,174 |
| Akira Kurosawa    | Kamatari Fujiwara |            5 |        7.6 |     514,808 |
| Akira Kurosawa    | Isao Kimura       |            3 |       7.67 |     496,695 |
| Akira Kurosawa    | Seiji Miyaguchi   |            2 |        7.5 |     418,874 |
| Akira Kurosawa    | Kichijirō Ueda    |            3 |       7.67 |     264,133 |
| Akira Kurosawa    | Tatsuya Nakadai   |            3 |        8.0 |     259,603 |
| Akira Kurosawa    | Masayuki Mori     |            3 |       7.33 |     219,343 |
| Akira Kurosawa    | Noriko Honma      |            2 |        7.5 |     218,444 |
| Akira Kurosawa    | Isuzu Yamada      |            3 |       7.67 |     210,720 |
| Akira Kurosawa    | Hiroshi Tachikawa |            3 |       7.67 |     210,436 |
| Akira Kurosawa    | Eijirō Tōno       |            3 |       7.33 |     171,220 |
| Akira Kurosawa    | Kyōko Kagawa      |            4 |        7.5 |     118,089 |
| Akira Kurosawa    | Takeshi Katō      |            2 |        7.5 |      88,068 |
| Akira Kurosawa    | Tatsuya Mihashi   |            2 |        7.5 |      88,068 |
| Akira Kurosawa    | Eiko Miyoshi      |            3 |       7.33 |      73,236 |
| Akira Kurosawa    | Reiko Dan         |            2 |        8.0 |      66,967 |
| Akira Kurosawa    | Yûzô Kayama       |            2 |        8.0 |      66,967 |
| Akira Kurosawa    | Kokuten Kōdō      |            2 |        7.5 |      66,783 |
| Akira Kurosawa    | Masao Shimizu     |            3 |       7.33 |      63,608 |
| Akira Kurosawa    | Akemi Negishi     |            3 |       7.33 |      36,210 |


---

## 9. AI Feature

- **Available for this tool?** Yes
- **What it does:** automated text to cypher
- **Cypher Query Generated**

```
[paste here]
```

- **Result:**

---

## 10. Comparison Ratings

*For the final cross-tool comparison matrix.*

| Metric                 | Rating (1–5) | Notes                                                                                                                                                                                                                                                                      |
| ---------------------- | -----------: | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Setup friction         |        **3** | Setup was fairly simple, but working through the Python Driver setup took a lot more research and trial and error. The UI Data Model tool was easier to start with but less flexible. The entire UI is very easy to navigate and there is endless documentation directly from neo4j for just about any issue you may run into.                                      |
| Query syntax verbosity |        **2** | Cypher queries were very easy to pick up and write. They can be quite verbose, but this does help you understand them when reading. Again, there is a ton of documentation from Neo4j to learn the syntax.                       |
| Documentation quality  |        **3** | The Neo4j documentation was extremly useful and beginner friendly. I found their knowledge graph academcy courses to be helpful as well as their documenation and Youtube channel. Since Neo4j is widly used there are also great tutorials from unassociated channels. |
| Learning curve         |        **3** | The basic Neo4j/Cypher concepts were fairly easy to learn, especially node/relationship matching in the UI. Using the Python Driver was the biggest learning curve, along with finding useful Cypher functions.    |


- **Gotchas / rough edges:**
Using the UI tools with a more complex model or not as standardized dataset is difficult and may not be an option.
- **One-line — who this tool is really for:**
Those getting started with graphs who want a multitude of creation options and need access to support material.

