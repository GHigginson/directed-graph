-- REQUIRES: ./schema.sql

/**
 * Returns true if a cycle is detected anywhere in the target graph, else false
 *
 * Since all of the nodes in the graph are known in advance, can simply recurse
 * all children, and conclude if the depth ever exceeds the total node count.
 */
CREATE OR REPLACE FUNCTION contains_cycle(
  graphCId VARCHAR(8)
) RETURNS BOOLEAN AS $$
DECLARE
  graphId INTEGER;
  nodeId INTEGER;
  nodeCount INTEGER;
  cycle BOOLEAN;
BEGIN
  graphId := (SELECT id FROM graph WHERE cid=graphCId);
  nodeCount := (SELECT count(1) FROM node WHERE graph_id=graphId);

  FOR nodeId IN
    SELECT id FROM node WHERE graph_id=graphId
  LOOP
    IF (_contains_cycle(nodeId, nodeCount, 0)) THEN
      RETURN TRUE;
    END IF;
  END LOOP;

  RETURN FALSE;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _contains_cycle(
  nodeId INTEGER,
  maxDepth INTEGER,
  currentDepth INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
  nextNodeId INTEGER;
BEGIN

  IF (maxDepth < currentDepth) THEN
    RETURN TRUE;
  END IF;

  FOR nextNodeId IN
    SELECT target_node_id FROM edge WHERE source_node_id=nodeId
  LOOP
    IF (_contains_cycle(nextNodeId, maxDepth, currentDepth + 1)) THEN
      RETURN TRUE;
    END IF;
  END LOOP;

  RETURN FALSE;
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

select contains_cycle('g1');  -- false
*/

/*
-- SIMPLE LOOP
delete from edge;
delete from node;
delete from graph;
insert into graph values (1, 'g1', 'g1');
insert into node values (1,1,'n1','n1');
insert into edge values (1,'e1',1,1,1);

select contains_cycle('g1');  -- true
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

select contains_cycle('g1');  -- true
select contains_cycle('g2');  -- false
*/

/*
-- BUG IN ORIGINAL SOLUTION
delete from edge;
delete from node;
delete from graph;
insert into graph values (1, 'g1', 'g1');
insert into node values (1,1,'n1','n1');
insert into node values (2,1,'n2','n2');
insert into node values (3,1,'n3','n3');
insert into node values (4,1,'n4','n4');
insert into edge values (1,'e1',1,2,1);
insert into edge values (2,'e2',1,3,1);
insert into edge values (3,'e3',2,3,1);
insert into edge values (4,'e4',4,1,1);

select contains_cycle('g1');  -- false
*/







