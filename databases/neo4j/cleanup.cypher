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