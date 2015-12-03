/* Directed Graph Schema */

CREATE TABLE graph (
  "id" INTEGER NOT NULL,        -- is graph/id globally unique? assuming no.
  "cid" VARCHAR(8) NOT NULL,    -- unsure of <id/> maxlen, picked 8
  "name" VARCHAR(80) NOT NULL,  -- unsure of <name/> maxlen, TEXT might be better
  PRIMARY KEY ("id")
);

-- graph has many nodes
CREATE TABLE node (
  "id" INTEGER NOT NULL,        -- primary key
  "graph_id" INTEGER NOT NULL,  -- foreign key
  "cid" VARCHAR(8) NOT NULL,
  "name" VARCHAR(80) NOT NULL,
  PRIMARY KEY ("id"),
  FOREIGN KEY ("graph_id") REFERENCES graph("id")
);

-- graph has many edges, but the edges reference nodes. I might be inclined to
-- have graph_id here to better match the model if using a DAO system
CREATE TABLE edge (
  "id" INTEGER NOT NULL,              -- primary key
  "cid" VARCHAR(8) NOT NULL,
  "source_node_id" INTEGER NOT NULL,  -- foreign key
  "target_node_id" INTEGER NOT NULL,  -- foreign key
  "cost" REAL NOT NULL DEFAULT 0.0,
  PRIMARY KEY ("id"),
  FOREIGN KEY ("source_node_id") REFERENCES node("id"),
  FOREIGN KEY ("target_node_id") REFERENCES node("id")
);
