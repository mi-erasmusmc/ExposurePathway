#' @export
execute <- function(servers, cdmDatabaseSchema, smallCellCount = 100, maxPathSize=5, sequenceSql) {

  if (missing(sequenceSql)) {
    exposureSequenceSql <- SqlRender::readSql(system.file("sql","exposureSequence.sql", package="JnJExposurePathway"));
  }
  else {
    exposureSequenceSql <- SqlRender::readSql(sequenceSql);
  }

  outputFolder <- "output"
  if (!file.exists(outputFolder))
    dir.create(outputFolder);

  for (server in servers)
  {
    serverFolder <- paste(outputFolder, server$name, sep="/");

    if (!file.exists(serverFolder))
      dir.create(serverFolder);

    # copy .css and .js depedencies to output folder
    file.copy(system.file(from="template","sequences.js", package="JnJExposurePathway"), to=serverFolder);
    file.copy(system.file(from="template","sequences.css", package="JnJExposurePathway"), to=serverFolder);

    connectionDetails <- DatabaseConnector::createConnectionDetails(dbms=server$dbms, server=server$hostname, port=server$port, user = server$user, password = server$password);

    conn <- DatabaseConnector::connect(connectionDetails);

    for (database in server$databases)
    {

      databaseOutputFolder <- paste(serverFolder, database$name, sep="/");
      if (!file.exists(databaseOutputFolder))
        dir.create(databaseOutputFolder)

      cdmDatabaseSchema <- database$schema;
      if (nchar(database$name) > 0)
        cdmDatabaseSchema <- paste(database$name, cdmDatabaseSchema, sep=".");

      # Generate exposure sequence
      exposureSequenceSql <- SqlRender::readSql(system.file("sql","exposureSequence.sql", package="JnJExposurePathway"));
      renderedSql <- SqlRender::renderSql(exposureSequenceSql,
                               cdm_database_schema = cdmDatabaseSchema
                              )$sql;
      translatedSql <- SqlRender::translateSql(renderedSql, targetDialect = connectionDetails$dbms, oracleTempSchema = database$tempSchema)$sql;
      SqlRender::writeSql(translatedSql,paste(databaseOutputFolder, "exposureSequence.sql", sep="/"));
      DatabaseConnector::executeSql(conn,translatedSql);

      # Create exposure paths

      # init #EXPOSURE_PATH with people from first exposure
      # concat -end to people who don't have a second exposure
      initPathSql <- SqlRender::readSql(system.file("sql","initUsagePath.sql", package="JnJExposurePathway"));
      translatedSql <- SqlRender::translateSql(initPathSql, targetDialect = connectionDetails$dbms, oracleTempSchema = database$tempSchema)$sql;
      SqlRender::writeSql(translatedSql,paste(databaseOutputFolder, "initUsagePath.sql", sep="/"));
      DatabaseConnector::executeSql(conn,translatedSql);


      usagePathIterationSql <- SqlRender::readSql(system.file("sql","usagePathIteration.sql", package="JnJExposurePathway"));
      i <- 2;
      while (i <= maxPathSize) {
        remainingPeopleCountSql <- "SELECT COUNT(*) as REMAINING from #EXPOSURE_SEQUENCE where ORDINAL = @i";
        renderedSql <- SqlRender::renderSql(remainingPeopleCountSql,
                                 i = i
        )$sql;
        translatedSql <- SqlRender::translateSql(renderedSql, targetDialect = connectionDetails$dbms, oracleTempSchema = database$tempSchema)$sql;
        remainingCount <- DatabaseConnector::querySql(conn, translatedSql);
        if (remainingCount$REMAINING == 0) break;
        # iterate for current sequence (i)
        renderedSql <- SqlRender::renderSql(usagePathIterationSql, sequence=i)$sql;
        translatedSql <- SqlRender::translateSql(renderedSql, targetDialect = connectionDetails$dbms, oracleTempSchema = database$tempSchema)$sql;
        SqlRender::writeSql(translatedSql,paste(databaseOutputFolder, paste("usagePathIteration", "_", i, ".sql", sep=""), sep="/"));
        DatabaseConnector::executeSql(conn,translatedSql);
        i <- i + 1;
      }

      # add truncate markers
      usagePathFinalizeSql <- SqlRender::readSql(system.file("sql","usagePathFinalize.sql", package="JnJExposurePathway"));
      renderedSql <- SqlRender::renderSql(usagePathFinalizeSql, sequence=i)$sql;
      translatedSql <- SqlRender::translateSql(renderedSql, targetDialect = connectionDetails$dbms, oracleTempSchema = database$tempSchema)$sql;
      SqlRender::writeSql(translatedSql,paste(databaseOutputFolder, "usagePathFinalize.sql", sep="/"));
      DatabaseConnector::executeSql(conn,translatedSql);


      # export paths to TSV
      exportPathsSql <- "SELECT DRUG_PATH, COUNT(*) as MEMBERS from #USAGE_PATH GROUP BY DRUG_PATH HAVING COUNT(*) > @smallcellcount ORDER BY COUNT(*) DESC";
      renderedSql <- SqlRender::renderSql(exportPathsSql, smallcellcount=smallCellCount)$sql;
      translatedSql <- SqlRender::translateSql(renderedSql, targetDialect = connectionDetails$dbms, oracleTempSchema = database$tempSchema)$sql;
      exportPathsDF <- DatabaseConnector::querySql(conn, translatedSql);
      write.table(exportPathsDF, file=paste(databaseOutputFolder, "exposurePaths.txt", sep="/"), row.names=FALSE, col.names=TRUE, quote=FALSE, sep="\t");

      # export id->name map to TSV
      conceptNamesSql <- "select distinct c.concept_id, c.concept_name from @cdm_database_schema.CONCEPT c JOIN #EXPOSURE_SEQUENCE es on c.concept_id = es.drug_concept_id WHERE ORDINAL <= @maxpathsize ORDER BY c.concept_name"
      renderedSql <- SqlRender::renderSql(conceptNamesSql, cdm_database_schema=cdmDatabaseSchema, maxpathsize = maxPathSize)$sql;
      translatedSql <- SqlRender::translateSql(renderedSql, targetDialect = connectionDetails$dbms, oracleTempSchema = database$tempSchema)$sql;
      conceptNamesDF <- DatabaseConnector::querySql(conn, translatedSql);
      write.table(conceptNamesDF, file=paste(databaseOutputFolder, "conceptNames.txt", sep="/"), row.names=FALSE, col.names=TRUE, quote=FALSE, sep="\t");

      # cleanupTempTables
      cleanupSql <- SqlRender::readSql(system.file("sql","cleanupTables.sql", package="JnJExposurePathway"));
      translatedSql <- SqlRender::translateSql(cleanupSql, targetDialect = connectionDetails$dbms, oracleTempSchema = database$tempSchema)$sql;
      SqlRender::writeSql(translatedSql,paste(databaseOutputFolder, "cleanupTables.sql", sep="/"));
      DatabaseConnector::executeSql(conn,translatedSql);

      # generate HTML?

      htmlTemplate <- readLines(system.file("template","sunburstPath.html", package="JnJExposurePathway"));
      exposurePathsTSV <- readLines(paste(databaseOutputFolder, "exposurePaths.txt", sep="/"));
      conceptNamesTSV <- readLines(paste(databaseOutputFolder, "conceptNames.txt", sep="/"));

      htmlTemplate <- gsub("@pathways",paste(exposurePathsTSV, collapse="\n"), htmlTemplate);
      htmlTemplate <- gsub("@conceptNames",paste(conceptNamesTSV, collapse="\n"), htmlTemplate);

      cat(htmlTemplate, file=paste(serverFolder, paste(database$id, "html", sep="."), sep="/"));

    }

    closed <- DBI::dbDisconnect(conn)
  }

  print("Exposure Pathways Generated.")

}
