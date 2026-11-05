//Finding director-actor bankable pairs

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


//Finding actor-actor bankable pairs
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