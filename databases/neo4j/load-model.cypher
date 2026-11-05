
// Contraints 

CREATE CONSTRAINT movie_id IF NOT EXISTS FOR (m:Movie) REQUIRE m.id IS UNIQUE;
CREATE CONSTRAINT person_id IF NOT EXISTS FOR (p:Person) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT genre_name IF NOT EXISTS FOR (g:Genre) REQUIRE g.name IS UNIQUE;


// Nodes will be created with these labels 
// (:Title)
// (:Person)
// (:Genre)


//Relationship Types

// Person -> CAST_MEMBER -> Title
// Person -> DIRECTOR -> Title
// Title -> GENRE -> Genre

// These node types and Relationships will be created when the data is loaded.