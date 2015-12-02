# query-graph

Simple query utility parsing utility that will determine if an XML graph
definition is well formed.

## Installation

Requires nodejs + npm

    npm install
    npm test

Must have previously created a postgres database using ../database/schema.sql
Database settings can be configured in config.json

## Usage

    echo '{...}' | ./query-graph.js

Query results will be returned on standard output.
