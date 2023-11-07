# experiment-pluto-in-duckdb
experimenting building pluto in duckdb instead of postgis

## Configurations
1. the two notebooks are executed on github codespaces, with 2 cores, 8 GB RAM
2. we are using PostgreSQL 16.0 + postgis 3.4
3. we are using duckdb 0.9.1

## Findings
### Scenario 1
if there's no projection change on files. postgis would do the join in around 5 minutes, ducdb would do the join in around 6 minutes. 
the performance is on par with each other. 

### Scenario 2
two CTEs to project geom of both tables from EPSG:2263 to EPSG:4326, postgis wouldn't finish the join after 30 minutes (killed). duckdb 
can finish the job in around 8 minutes. This is probably because when loading shapefile to postgres, there's spatial index created automatically. 
so the no projection scenario is much faster. 

> in both scenarios, we observed high CPU usage for both duckdb and postgres