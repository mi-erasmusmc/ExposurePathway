SELECT DISTINCT *
FROM
  (SELECT
     d1_concept_id   AS CONCEPT_ID,
     d1_concept_name AS CONCEPT_NAME
   FROM @results.@resultsTable
   WHERE d1_concept_id IS NOT NULL
   UNION ALL
   SELECT
     d2_concept_id,
     d2_concept_name
   FROM @results.@resultsTable
   WHERE d2_concept_id IS NOT NULL
   UNION ALL
   SELECT
     d3_concept_id,
     d3_concept_name
   FROM @results.@resultsTable
   WHERE d3_concept_id IS NOT NULL
   UNION ALL
   SELECT
     d4_concept_id,
     d4_concept_name
   FROM @results.@resultsTable
   WHERE d4_concept_id IS NOT NULL
   UNION ALL
   SELECT
     d5_concept_id,
     d5_concept_name
   FROM @results.@resultsTable
   WHERE d5_concept_id IS NOT NULL
   UNION ALL
   SELECT
     d6_concept_id,
     d6_concept_name
   FROM @results.@resultsTable
   WHERE d6_concept_id IS NOT NULL
   UNION ALL
   SELECT
     d7_concept_id,
     d7_concept_name
   FROM @results.@resultsTable
   WHERE d7_concept_id IS NOT NULL
   UNION ALL
   SELECT
     d8_concept_id,
     d8_concept_name
   FROM @results.@resultsTable
   WHERE d8_concept_id IS NOT NULL
   UNION ALL
   SELECT
     d9_concept_id,
     d9_concept_name
   FROM @results.@resultsTable
   WHERE d9_concept_id IS NOT NULL
   UNION ALL
   SELECT
     d10_concept_id,
     d10_concept_name
   FROM @results.@resultsTable
   WHERE d10_concept_id IS NOT NULL
   UNION ALL
   SELECT
     d11_concept_id,
     d11_concept_name
   FROM @results.@resultsTable
   WHERE d11_concept_id IS NOT NULL
   UNION ALL
   SELECT
     d12_concept_id,
     d12_concept_name
   FROM @results.@resultsTable
   WHERE d12_concept_id IS NOT NULL
   UNION ALL
   SELECT
     d13_concept_id,
     d13_concept_name
   FROM @results.@resultsTable
   WHERE d13_concept_id IS NOT NULL
   UNION ALL
   SELECT
     d14_concept_id,
     d14_concept_name
   FROM @results.@resultsTable
   WHERE d14_concept_id IS NOT NULL
   UNION ALL
   SELECT
     d15_concept_id,
     d15_concept_name
   FROM @results.@resultsTable
   WHERE d15_concept_id IS NOT NULL
   UNION ALL
   SELECT
     d16_concept_id,
     d16_concept_name
   FROM @results.@resultsTable
   WHERE d16_concept_id IS NOT NULL
   UNION ALL
   SELECT
     d17_concept_id,
     d17_concept_name
   FROM @results.@resultsTable
   WHERE d17_concept_id IS NOT NULL
   UNION ALL
   SELECT
     d18_concept_id,
     d18_concept_name
   FROM @results.@resultsTable
   WHERE d18_concept_id IS NOT NULL
   UNION ALL
   SELECT
     d19_concept_id,
     d19_concept_name
   FROM @results.@resultsTable
   WHERE d19_concept_id IS NOT NULL
   UNION ALL
   SELECT
     d20_concept_id,
     d20_concept_name
   FROM @results.@resultsTable
   WHERE d20_concept_id IS NOT NULL
  ) AS x;
