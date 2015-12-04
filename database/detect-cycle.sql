-- REQUIRES: ./schema.sql

/**
 * Cycle detection method that will immediately halt and raise an error if
 * a cycle is detected anywhere in the target graph.
 *
 * Uses dijkstras algorithm to build a minimum spanning set of the graph,
 * with an additional check for edges linking back into the spanned set.
 */
CREATE OR REPLACE FUNCTION detect_cycle(
  graphCId VARCHAR(8)
) RETURNS VOID AS $$
DECLARE
  graphId INTEGER;
  vertex RECORD;
  path RECORD;
  newDistance REAL;
  maxDistance REAL;
BEGIN
  maxDistance := 1e37;
  graphId := (SELECT id FROM graph WHERE cid=graphCId);

  -- Initialize vertices with all edges in this graph, with no parent and max distance
  CREATE TEMP TABLE IF NOT EXISTS vertices (
    id INTEGER,
    distance REAL,
    previous INTEGER,
    spanned BOOLEAN
  ) ON COMMIT DROP;
  INSERT INTO vertices SELECT node.id, maxDistance, null, false FROM node WHERE graph_id = graphId;

  -- Zero out distance for all root nodes
  UPDATE vertices SET distance = 0.0;

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

      -- Cycle detection (if enabled)
      IF (path.source_node_id = path.target_node_id) THEN
        RAISE EXCEPTION 'Cycle detected [%..%]',
            path.source_node_id, path.target_node_id;
      END IF;
      IF (EXISTS (SELECT * FROM vertices WHERE id = path.target_node_id AND spanned=true)) THEN
        RAISE EXCEPTION 'Cycle detected [%..%..%]',
            path.target_node_id, path.source_node_id, path.target_node_id;
      END IF;

      -- Recalculate minimum distance
      newDistance := vertex.distance + path.cost;
      IF (newDistance < path.distance) THEN
        UPDATE vertices SET distance = newDistance, previous=vertex.id WHERE id=path.target_node_id;
      END IF;
    END LOOP;
  END LOOP;
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
insert into graph values (1, 'g1', 'g1');
insert into node values (1,1,'n1','n1');
insert into node values (2,1,'n2','n2');
insert into node values (3,1,'n3','n3');
insert into node values (4,1,'n4','n4');
insert into edge values (1,'e1',1,2,1);
insert into edge values (2,'e2',1,3,5);
insert into edge values (3,'e3',2,3,1);

select detect_cycle('g1');  -- No Error
*/

/*
-- SIMPLE LOOP
delete from edge;
delete from node;
delete from graph;
insert into graph values (1, 'g1', 'g1');
insert into node values (1,1,'n1','n1');
insert into edge values (1,'e1',1,1,1);

select detect_cycle('g1');  -- Found cycle
*/

/*
-- COMPLEX LOOP
delete from edge;
delete from node;
delete from graph;
insert into graph values (1, 'g1', 'g1');
insert into node values (1,1,'n1','n1');
insert into node values (2,1,'n2','n2');
insert into node values (3,1,'n3','n3');
insert into node values (4,1,'n4','n4');
insert into edge values (1,'e1',1,2,1);
insert into edge values (2,'e2',1,3,5);
insert into edge values (3,'e3',2,3,1);
insert into edge values (4,'e4',2,1,1);
insert into edge values (5,'e5',4,4,1);

select detect_cycle('g1');  -- Found cycle
select detect_cycle('g2');  -- Nothing
*/







