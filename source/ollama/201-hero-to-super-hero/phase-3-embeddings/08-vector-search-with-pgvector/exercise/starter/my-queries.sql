-- Starter for the three exercise queries. Run it with:
--   Windows PowerShell: Get-Content my-queries.sql | docker compose exec -T db psql -U search -d searchdb
--   macOS/Linux: docker compose exec -T db psql -U search -d searchdb < my-queries.sql

-- TODO 1: count the rows in search.chunks (expected: 12 after a first ingest)

-- TODO 2: list embedding_model, the number of chunks and vector_dims(embedding) for each model

-- TODO 3: show the title and distance of the 3 chunks nearest to the chunk whose section is 'Returns',
--         using the inner-product operator <#> instead of <=> (remember it returns the NEGATIVE inner product)
