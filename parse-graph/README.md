# parse-graph

Simple graph parsing utility that will determine if an XML graph definition
is well formed.

## Installation

Requires nodejs + npm

    npm install
    npm test

## Usage

    node parse-graph.js <path-or-url>

Will return with status 0 on success and 1 on failure. Details will be provided
on standard output when validation fails.
