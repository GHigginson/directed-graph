# database

This folder contains scripts for setting up a PostgreSQL database suitable for the data model validated by the parse-query application. Nothing actually relies on these scripts, they are provided as an excercise.

**schema.sql**: database schema, run as a precondition to detect-cycle.sql

**detect-cycle.sql**: stored procedure for detecting cycles in a directed graph.
