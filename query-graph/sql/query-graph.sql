/* Database setup script for the query-graph.js application.
 *
 * Uses a simplified version of the database schema where the string-ids are
 * used instead of an integer primary key. This has the downside of making
 * ids globally unique whereas they could previously be re-used by different
 * graphs, but it cuts down on a lot of excess conversion logic in this script
 * and the query-model for the application has no concept of a graph-id anyway.
 *
 * Also provides two stored procedures used by the application:
 *
 *  - dijkstra() for the "cheapest" query
 *  - recursive_path_search() for the "paths" query
 */

DROP TABLE IF EXISTS edge;
DROP TABLE IF EXISTS node;
DROP TABLE IF EXISTS graph;

CREATE TABLE graph (
  "id" VARCHAR(8) NOT NULL,
  "name" VARCHAR(80) NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE node (
  "id" VARCHAR(8) NOT NULL,
  "graph_id" VARCHAR(8) NOT NULL,
  "name" VARCHAR(80) NOT NULL,
  PRIMARY KEY ("id"),
  FOREIGN KEY ("graph_id") REFERENCES graph("id")
);

CREATE TABLE edge (
  "id" VARCHAR(8) NOT NULL,
  "source_node_id" VARCHAR(8) NOT NULL,
  "target_node_id" VARCHAR(8) NOT NULL,
  "cost" REAL NOT NULL DEFAULT 0.0,
  PRIMARY KEY ("id"),
  FOREIGN KEY ("source_node_id") REFERENCES node("id"),
  FOREIGN KEY ("target_node_id") REFERENCES node("id")
);


/* Implementation of Didkstra's Algorithm for use by the query-graph utility
 * when finding cheapest path.
 *
 * Returns the path as a null-terminated array of nodes ids
 *
 * eg:
 *       a--->b--->c
 * as:
 *       {'a','b','c',null}
 */
CREATE OR REPLACE FUNCTION dijkstra(
  graphId VARCHAR(8),
  fromNodeId VARCHAR(8),
  toNodeId VARCHAR(8)
) RETURNS text[] AS $$
DECLARE
  vertex RECORD;
  path RECORD;
  newDistance REAL;
  maxDistance REAL;
BEGIN
    maxDistance := 1e37;

  -- Initialize vertices with all edges in this graph, with no parent and max distance
  CREATE TEMP TABLE IF NOT EXISTS vertices (
    id VARCHAR(8),
    distance REAL,
    previous VARCHAR(8),
    spanned BOOLEAN
  ) ON COMMIT DROP;
  DELETE FROM vertices;
  INSERT INTO vertices SELECT node.id, maxDistance, null, false FROM node WHERE graphId IS NULL OR graph_id = graphId;

  -- Zero out distance for all root nodes
  UPDATE vertices SET distance = 0.0 WHERE id=fromNodeId;

  -- Loop until all nodes have been spanned
  LOOP

    -- Find vertex closest to the spanned set, or exit
    SELECT * INTO vertex FROM vertices WHERE spanned=false ORDER BY distance ASC LIMIT 1;
    IF (vertex IS NULL) THEN
       EXIT;
    END IF;

    -- Add to spanned set and adjust distance of all neighbors
    UPDATE vertices SET spanned=true WHERE id = vertex.id;
    FOR path IN
      SELECT * FROM vertices INNER JOIN edge ON edge.target_node_id = vertices.id
      WHERE edge.source_node_id=vertex.id
    LOOP

      -- Recalculate minimum distance
      newDistance := vertex.distance + path.cost;
      IF (newDistance < path.distance) THEN
        UPDATE vertices SET distance = newDistance, previous=vertex.id WHERE id=path.target_node_id;
      END IF;
    END LOOP;
  END LOOP;
  return _assemble_path(fromNodeId, toNodeId);
END
$$ LANGUAGE plpgsql;


/* Recursive reverse search from leaf to root, 
 *
 * Returns a single array containing multiple paths, each of which is null terminated.
 * This is a workaround for absense of jagged array suppoort in array methods.
 *
 * eg:
 *       a--->b--->c
 *         \---->c
 * as:
 *       {'a','c',null,'a','b','c',null}
 */
CREATE OR REPLACE FUNCTION recursive_path_search(
  graphId VARCHAR(8),
  fromNodeId VARCHAR(8),
  toNodeId VARCHAR(8)
) RETURNS text[][] AS $$
DECLARE
  vertex RECORD;
  path RECORD;
  newDistance REAL;
  maxDistance REAL;
BEGIN

  CREATE TEMP TABLE IF NOT EXISTS vertices (
    id VARCHAR(8),
    previous VARCHAR(8),
    distance INTEGER
  ) ON COMMIT DROP;
  DELETE FROM vertices;

  RETURN _recursive_search(graphId, fromNodeId, toNodeId, toNodeId);
END
$$ LANGUAGE plpgsql;

/* Inner method for the recursive path search that pushes a path if nextNode is
 * the root of our search, recurses all neighbors, and returns the concatenation
 * of all paths found.
 */
CREATE OR REPLACE FUNCTION _recursive_search(
  graphId VARCHAR(8),
  fromNode VARCHAR(8),
  toNode VARCHAR(8),
  nextNode VARCHAR(8)
) RETURNS text[] AS $$
DECLARE
  node VARCHAR(8);
  paths text[];
BEGIN
  paths := ARRAY[]::text[];
  UPDATE vertices SET distance = distance + 1;

  IF (fromNode = nextNode) THEN
    paths := array_cat(paths, _assemble_path(fromNode, toNode));
  ELSE
    FOR node IN
      SELECT source_node_id FROM edge INNER JOIN node ON edge.source_node_id = node.id
      WHERE target_node_id=nextNode AND source_node_id NOT IN (SELECT id FROM vertices)
      AND (graphId IS NULL OR node.graph_id = graphId)
    LOOP
      INSERT INTO vertices VALUES (nextNode, node, 0);
      paths := array_cat(paths, _recursive_search(graphId, fromNode, toNode, node));
      DELETE FROM vertices WHERE id = nextNode and previous = node;
    END LOOP;
  END IF;
  RETURN paths;
END
$$ LANGUAGE plpgsql;

/* Traces a path back from the toNode record in the vertex set (which is cycle
 * free and guaranteed to contain at most one path at the point this is called).
 * Returns as a null-terminated array of node ids.
 */
CREATE OR REPLACE FUNCTION _assemble_path(
  fromNode VARCHAR(8),
  toNode VARCHAR(8)
) RETURNS text[] AS $$
DECLARE
  vertex RECORD;
  path TEXT[];
BEGIN
  path := ARRAY[]::TEXT[];
  FOR vertex IN
    SELECT a.id idA, b.id idB FROM vertices
    LEFT OUTER JOIN node a ON vertices.previous = a.id
    INNER JOIN node b ON vertices.id = b.id
    ORDER BY distance DESC
  LOOP
    IF (toNode = vertex.idB and vertex.idA IS NOT NULL) THEN
      path := array_prepend(vertex.idB::text, path);
      toNode = vertex.idA;
    END IF;
    IF (fromNode = vertex.idA and toNode = vertex.idA) THEN
      path := array_prepend(vertex.idA::text, path);
    END IF;
  END LOOP;
  path := array_append(path, null);
  RETURN path;
END
$$ LANGUAGE plpgsql;

/*************
* Test Cases *
*************/

/* 
-- NO CYCLE
delete from edge;
delete from node;
delete from graph;
insert into graph values ('g1', 'g1-name');
insert into node values ('n1','g1','n1-name');
insert into node values ('n2','g1','n2-name');
insert into node values ('n3','g1','n3-name');
insert into node values ('n4','g1','n4-name');
insert into edge values ('e1','n1','n2',1);
insert into edge values ('e2','n1','n3',5);
insert into edge values ('e3','n2','n3',1);

select dijkstra('g1','n1','n3'); -- {n1,n2,n3,null}
select dijkstra(null,'n1','n3'); -- {n1,n2,n3,null}
select dijkstra('g1','n4','n3'); -- {null}
select dijkstra('g2','n1', 'n2'); -- {null}
--select unnest(dijkstra('g1','n1','n3'));
select recursive_path_search('g1', 'n1', 'n3') -- {n1,n3,null,n1,n2,n3,null}}
*/

/*
-- SIMPLE LOOP
delete from edge;
delete from node;
delete from graph;
insert into graph values ('g1','g1-name');
insert into node values ('n1','g1','n1-name');
insert into edge values ('e1','n1','n1',1);

select recursive_path_search('g1', 'n1', 'n1') -- {null} (cycles ignored, so not a route)
*/

/*
-- COMPLEX LOOP
delete from edge;
delete from node;
delete from graph;
insert into graph values ('g1', 'g1-name');
insert into node values ('n1','g1','n1-name');
insert into node values ('n2','g1','n2-name');
insert into node values ('n3','g1','n3-name');
insert into node values ('n4','g1','n4-name');
insert into edge values ('e1','n1','n2',1);
insert into edge values ('e2','n1','n3',5);
insert into edge values ('e3','n2','n3',1);
insert into edge values ('e4','n2','n1',1);
insert into edge values ('e5','n4','n4',1);

select recursive_path_search('g1', 'n2', 'n3') -- {n2,n1,n3,NULL,n2,n3,NULL}
select recursive_path_search(null, 'n2', 'n3') -- {n2,n1,n3,NULL,n2,n3,NULL}
select recursive_path_search('g2', 'n2', 'n3') -- {NULL}
*/






