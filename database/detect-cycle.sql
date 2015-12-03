/*
create table nodes (
  n integer not null
);
delete from nodes;
insert into nodes values (1);
insert into nodes values (2);
insert into nodes values (3);
insert into nodes values (4);
create table edges (
  s integer not null,
  c integer not null,
  d integer not null
);
delete from edges;
insert into edges (s,c,d) values (1,1,2);
insert into edges (s,c,d) values (1,5,3);
insert into edges (s,c,d) values (2,1,3);
--insert into edges (s,c,d) values (2,1,1);
--insert into edges (s,c,d) values (4,1,4);


insert into edges (s,c,d) values (1,1,1);
insert into edges (s,c,d) values (1,1,2);
insert into edges (s,c,d) values (2,5,3);
insert into edges (s,c,d) values (3,1,2);
insert into edges (s,c,d) values (2,1,4);
*/


/* Uses dijkstra's algorithm, but with no root node, instead initializes all nodes
 * with no inbound edges to zero. Terminates any time an edge is encountered that
 * terminates in the set already spanned.
 */
create or replace function detect_cycle_detect_take_2()
returns void AS $$
declare
  vertex record;
  edge record;
  newDistance integer;
begin
  create temp table vertices (
    node integer,
    distance integer,
    previous integer,
    spanned boolean
  ) on commit drop;
  insert into vertices select n, 99999999, null, false from nodes;
  update vertices set distance = 0 where node not in (select d from edges);

  loop
    select * into vertex from vertices where spanned=false order by distance asc limit 1;
    if (vertex is null) then
       exit;
    end if;
    update vertices set spanned=true where node = vertex.node;
    for edge in
      select * from edges inner join vertices on d = vertices.node
      where s=vertex.node
    loop
      if (edge.s = edge.d) then
        raise Exception 'Cycle detected [%..%]', edge.s, edge.d;
      end if;
      if exists (select * from vertices where node = edge.d and spanned=true) then
        raise Exception 'Cycle detected [%..%..%]', edge.d, edge.s, edge.d;
      end if;
      newDistance := vertex.distance + edge.c;
      if (newDistance < edge.distance) then
	update vertices set distance = newDistance, previous=vertex.node
	where node=edge.node;
      end if;
    end loop;
  end loop;
  raise Notice 'No cycles detected.';
end
$$ language plpgsql;

select detect_cycle_detect_take_2();


/*
-- naive solution using dijkstra
-- would need to call once on every potential source node....
create or replace function dijkstra_cycle_detect(src integer)
returns table (id integer, dist integer, prev integer) AS $$
declare
  vertex record;
  edge record;
  newDistance integer;
begin
  create temp table vertices (
    node integer,
    distance integer,
    previous integer,
    spanned boolean
  ) on commit drop;
  insert into vertices select n, 99999999, null, false from nodes;
  update vertices set distance = 0 where node = src;

  loop
    select * into vertex from vertices where spanned=false order by distance asc limit 1;
    if (vertex is null) then
       exit;
    end if;
    update vertices set spanned=true where node = vertex.node;
    for edge in
      select * from edges inner join vertices on d = vertices.node
      where s=vertex.node
    loop
      if (edge.s = edge.d) then
        raise Exception 'Cycle detected [%..%]', edge.s, edge.d;
      end if;
      if exists (select * from vertices where node = edge.d and spanned=true) then
        raise Exception 'Cycle detected [%..%..%]', edge.d, edge.s, edge.d;
      end if;
      newDistance := vertex.distance + edge.c;
      if (newDistance < edge.distance) then
	update vertices set distance = newDistance, previous=vertex.node
	where node=edge.node;
      end if;
    end loop;
  end loop;
  return query select node, distance, previous from vertices;
end
$$ language plpgsql;

select dijkstra_cycle_detect(1);
*/

/*
-- works, but is excessive?
create or replace function dijkstra(src integer)
returns table (id integer, dist integer, prev integer) AS $$
declare
  nextNode integer;
begin
  create temp table vertices (
    node integer,
    distance integer,
    previous integer,
    spanned boolean
  ) on commit drop;
  insert into vertices select n, 99999999, null, false from nodes;
  update vertices set distance = 0 where node = src;

  loop
    select node into nextNode from vertices where spanned=false order by distance asc limit 1;
    if (nextNode is null) then
       exit;
    end if;
    perform dijkstra_process_vertex(nextNode); -- TODO fold the method back in
  end loop;

  return query select node, distance, previous from vertices;
end
$$ language plpgsql;

-- works, does cycle detection
create or replace function dijkstra_process_vertex(nodeId integer)
returns void AS $$
declare
   vertex record;
   edge record;
   newDistance integer;
begin
    select * into vertex from vertices where node=nodeId;
    update vertices set spanned=true where node = vertex.node;
    for edge in
      select * from edges inner join vertices on d = vertices.node
      where s=vertex.node
    loop
      if (edge.s = edge.d) then
        raise Exception 'Cycle detected [%..%]', edge.s, edge.d;
      end if;
      if exists (select * from vertices where node = edge.d and spanned=true) then
        raise Exception 'Cycle detected [%..%..%]', edge.d, edge.s, edge.d;
      end if;
      newDistance := vertex.distance + edge.c;
      if (newDistance < edge.distance) then
	update vertices set distance = newDistance, previous=vertex.node
	where node=edge.node;
      end if;
    end loop;
end
$$ language plpgsql;

-- works, no cycle detection
create or replace function dijkstra_process_vertex(nodeId integer)
returns void AS $$
declare
   vertex record;
   edge record;
   newDistance integer;
begin
    select * into vertex from vertices where node=nodeId;
    update vertices set spanned=true where node = vertex.node;
    for edge in
      select * from edges inner join vertices on d = vertices.node
      where s=vertex.node and d in (select node from vertices where spanned=false)
    loop
      newDistance := vertex.distance + edge.c;
      if (newDistance < edge.distance) then
	update vertices set distance = newDistance, previous=vertex.node
	where node=edge.node;
      end if;
    end loop;
end
$$ language plpgsql;
select dijkstra(1);
*/



