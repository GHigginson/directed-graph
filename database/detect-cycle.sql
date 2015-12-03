
/* Uses dijkstra's algorithm, but with no root node, instead initializes all nodes
 * with no inbound edges to zero. Terminates any time an edge is encountered that
 * terminates in the set already spanned.
 */
create or replace function detect_cycle_detect_take_2(graphId integer)
returns void AS $$
declare
  vertex record;
  path record;
  newDistance integer;
begin
  create temp table vertices (
    id integer,
    distance real,
    previous integer,
    spanned boolean
  ) on commit drop;
  insert into vertices select node.id, 99999999, null, false from node where graph_id = graphId;
  update vertices set distance = 0.0 where id not in (select target_node_id from edge inner join node on edge.source_node_id = node.id and graph_id=graphId);

  loop
    select * into vertex from vertices where spanned=false order by distance asc limit 1;
    if (vertex is null) then
       exit;
    end if;
    update vertices set spanned=true where id = vertex.id;
    for path in
      select * from vertices inner join edge on edge.target_node_id = vertices.id
      where edge.source_node_id=vertex.id
    loop
      if (path.source_node_id = path.target_node_id) then
        raise Exception 'Cycle detected [%..%]', path.source_node_id, path.target_node_id;
      end if;
      if exists (select * from vertices where id = path.target_node_id and spanned=true) then
        raise Exception 'Cycle detected [%..%..%]', path.target_node_id, path.source_node_id, path.target_node_id;
      end if;
      newDistance := vertex.distance + path.cost;
      if (newDistance < path.distance) then
	update vertices set distance = newDistance, previous=vertex.id
	where id=path.target_node_id;
      end if;
    end loop;
  end loop;
  raise Notice 'No cycles detected.';
end
$$ language plpgsql;

create or replace function dijkstra(graphId integer, rootNodeId integer)
returns table (source_node varchar(8), dest_node varchar(8)) AS $$
declare
  vertex record;
  path record;
  newDistance real;
  maxDistance real;
begin
  maxDistance := 1e20;
  create temp table vertices (
    id integer,
    distance real,
    previous integer,
    spanned boolean
  ) on commit drop;
  insert into vertices select node.id, maxDistance, null, false from node where graph_id = graphId;
  update vertices set distance = 0.0 where id=rootNodeId;

  loop
    select * into vertex from vertices where spanned=false order by distance asc limit 1;
    if (vertex is null) then
       exit;
    end if;
    update vertices set spanned=true where id = vertex.id;
    for path in
      select * from vertices inner join edge on edge.target_node_id = vertices.id
      where edge.source_node_id=vertex.id
    loop
      newDistance := vertex.distance + path.cost;
      if (newDistance < path.distance) then
	update vertices set distance = newDistance, previous=vertex.id
	where id=path.target_node_id;
      end if;
    end loop;
  end loop;
  delete from vertices where distance=maxDistance;
  return query select a.cid, b.cid from vertices
     inner join node a on vertices.id = a.id
     left outer join node b on vertices.previous = b.id;
end
$$ language plpgsql;


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

select detect_cycle_detect_take_2(1);  -- No Error
select dijkstra(1,1); -- n3->n2->n1
select dijkstra(1,4); -- n4
select dijkstra(2,1); -- nothing (no such graph)
*/

/*
-- SIMPLE LOOP
delete from edge;
delete from node;
delete from graph;
insert into graph values (1, 'g1', 'g1');
insert into node values (1,1,'n1','n1');
insert into edge values (1,'e1',1,1,1);

select detect_cycle_detect_take_2(1);  -- Found cycle
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

select detect_cycle_detect_take_2(1);  -- Found cycle
select detect_cycle_detect_take_2(2);  -- Nothing
*/







