# query-graph

Simple query utility parsing utility that will determine if an XML graph
definition is well formed.

## Installation

Requires nodejs + npm

    npm install
    npm test

Must have previously created a postgres database using [query-graph.sql](sql/query-graph.sql)
Database settings can be configured in config.json.

## Usage

    node query-graph.js < query.json
    echo '{...}' | node query-graph.js

Query results will be returned on standard output.

## Query Format

```
{
  "queries" : [
    {
      "type" : "paths"
      "start" : "id1",
      "end" : "idN"
    },
    ...
    {
      "type" : "cheapest",
      "start" : "id1",
      "end" : "idN"
    },
    ...
  ]
}
```
