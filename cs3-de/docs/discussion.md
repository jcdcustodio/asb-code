# Solution Discussion

### Why did you choose your database, ingestion, transformation, and orchestration tools?

- Setting up the database in a container ensures it could be setup in any system and run in an isolated manner with other databases, if they exist.
- PostgreSQL with dedicated schemas provides clean separation between OLTP and OLAP while keeping local infrastructure simple and enabling fast in-engine transformations.
- For the Python tools, using uv provides convenience in reproducing the environment while delivering fast package installation and dependency management. Then given the usual scale of data being processed, its more practical to use polars than pandas as it generally faster and use less resource (memory).
- For simplicity in this case study implementation, the orchestration was implemented as a single script executing all the relevant query files in sequence.

### How did you translate the normalized OLTP structure into your dimensional model, and what is the grain of each fact table?

`fact_order` – One row per operational customer order line
`fact_sale` – One row per customer invoice line

### Which dimension and attributes use SCD Type 2, which use SCD Type 1, and why?

Customer category and organizational attributes use SCD Type 2 to preserve historical context, ensuring sales attribution remains accurate as accounts evolve. Stock item names and minor descriptions use SCD Type 1 because retroactive reporting on cosmetic rebranding is rarely required by business stakeholders.

### How does your pipeline prevent duplicates and produce consistent results when the same input is processed more than once?

The pipeline achieves idempotency by using `ON CONFLICT DO NOTHING` statements on date dimension generation and `WHERE NOT EXISTS` clauses keyed to source primary keys on fact ingestion. Re-running the pipeline on identical data will not produce duplicate records or split dimension versions.

### What would you change if the source produced millions of records per day and the business required hourly warehouse updates?

If data volumes scale significantly, replace full-table scans with an append-only change data capture (CDC) pipeline, partition the fact tables by date_key (monthly or daily partitions), and run dimensional updates in parallel using an orchestration engine.
