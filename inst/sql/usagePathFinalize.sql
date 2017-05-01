UPDATE #USAGE_PATH SET DRUG_PATH = CONCAT(DRUG_PATH, '-truncated')
WHERE PERSON_ID in (
  select e.person_id from #EXPOSURE_SEQUENCE e
  where e.ORDINAL = @sequence
);
