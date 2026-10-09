# [ASB Case Study 3 – Building an End-to-End Data Engineering Pipeline](https://github.com/imjbmkz/analytics-solutions-bootcamp/blob/main/03_case_study/03_cs_data_engineering.md)

[Answers to solution questions](docs/discussion.md)

## Directory Layout

```markdown
cs3-de/
├── analytics
│   ├── results
├── data
│   └── raw
├── docs
├── query
│   └── sc2-demo
├── .env
├── .env-example
├── check_quality.py
├── compose.yaml
├── db_util.py
├── ingest_oltp.py
├── inspect_data.ipynb
└── pipeline.py
```

## Diagrams

### Pipeline Architecture

```mermaid
flowchart LR
    subgraph INGESTION ["Ingestion Layer"]
        CSV["Raw CSV Extracts<br/><b>(Kaggle WWI)</b>"]
        BATCH["Python<br/><b>(Batch Ingest)</b>"]
        CSV --> BATCH
    end

    subgraph CONTAINER ["PostgreSQL Container (WWI)"]
        direction TB
        
        subgraph SCHEMAS ["Database Engine"]
            direction LR
            OLTP[("OLTP Schema (3NF Normalized)</i>")]
            OLAP[("OLAP Schema (Star Schema / SCD2)</i>")]
            OLTP -->|ELT| OLAP
        end
    end

    DQ["Quality Checks"]
    BI["Analytics / BI Platform"]

    BATCH -->|Load| OLTP
    OLAP --> DQ
    OLAP --> BI

    classDef store fill:#e1f5fe,stroke:#0288d1,stroke-width:2px,color:#01579b;
    classDef process fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#4a148c;
    classDef target fill:#e8f5e9,stroke:#388e3c,stroke-width:2px,color:#1b5e20;
    
    class OLTP,OLAP store;
    class CSV,BATCH,DQ process;
    class BI target;
```

### Schemas

- [View OLTP Schema](docs/diagram-oltp.md)
- [View OLAP Schema](docs/diagram-olap.md)
