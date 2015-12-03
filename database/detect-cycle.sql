
/* Cycle detection method that will immediately halt and raise an error if
 * a cycle is detected anywhere in the target graph.
 */
CREATE OR REPLACE FUNCTION detect_cycle(
  graphId VARCHAR(8)
) RETURNS VOID AS $$
BEGIN
  PERFORM _build_spanning_tree(
    (SELECT id FROM graph WHERE cid=graphId),
    null,  -- no root node
    true   -- halt on cycle
  );
  RAISE NOTICE 'No cycles detected.';
END
$$ LANGUAGE plpgsql;

/* Implementation of Didkstra's Algorithm for use by the query-graph utility
 * when finding lowest cost path.
 *
 * Returns a table of node cid pairs ordered by cost.
 *
 * eg:
 *       a--->b--->c
 *         \---->d
 * as:
 *       [(a,b),(a,d),(b,c)]
 */
CREATE OR REPLACE FUNCTION dijkstra(
  graphId VARCHAR(8),
  rootNodeId VARCHAR(8)
) RETURNS TABLE (source_node VARCHAR(8), dest_node VARCHAR(8)) AS $$
DECLARE
  maxDistance real;
BEGIN
  maxDistance := 1e37;

  PERFORM _build_spanning_tree(
    (SELECT id FROM graph WHERE cid=graphId),
    (SELECT id FROM node WHERE cid=rootNodeId),
    true   -- halt on cycle
  );

  -- Prune any nodes that are not reachable from the root
  DELETE FROM vertices WHERE distance=maxDistance;

  -- Join back to the node table to return cid values
  RETURN QUERY SELECT a.cid, b.cid FROM vertices
    LEFT_OUTER JOIN node a ON vertices.previous = a.id
    INNER JOIN node b ON vertices.id = b.id
    ORDER BY distance DESC;
END
$$ LANGUAGE plpgsql;


/* Common pathway for the dijkstra and detect_cycle methods.
 * Attempts to process the target graph into a spanning tree/graph depending
 * on whether a root node was selected. If haltOnCycle is true an error will
 * be raised anytime an edge is detected leading back to the spanned set.
 */
CREATE OR REPLACE FUNCTION _build_spanning_tree(graphId integer, rootNodeId integer, haltOnCycle boolean)
RETURNS VOID AS $$
DECLARE
  vertex RECORD;
  path RECORD;
  newDistance REAL;
  maxDistance REAL;
BEGIN
  maxDistance := 1e37;

  -- Initialize vertices with all edges in this graph, with no parent and max distance
  CREATE TEMP TABLE IF NOT EXISTS vertices (
    id INTEGER,
    distance REAL,
    previous INTEGER,
    spanned BOOLEAN
  ) ON COMMIT DROP;
  DELETE FROM vertices;
  INSERT INTO vertices SELECT node.id, maxDistance, null, false FROM node WHERE graph_id = graphId;

  -- Zero out distance for all root nodes
  UPDATE vertices SET distance = 0.0 WHERE rootNodeId IS NULL OR id=rootNodeId;

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
      IF (haltOnCycle AND path.source_node_id = path.target_node_id) THEN
        RAISE EXCEPTION 'Cycle detected [%..%]',
            path.source_node_id, path.target_node_id;
      END IF;
      IF (haltOnCycle AND EXISTS (SELECT * FROM vertices WHERE id = path.target_node_id AND spanned=true)) THEN
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
select dijkstra('g1','n1'); -- n3->n2->n1
select dijkstra('g1','n4'); -- n4
select dijkstra('g2','n1'); -- nothing (no such graph)
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







