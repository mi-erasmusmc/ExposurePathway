#' @export
buildServer <- function(name, dbms, hostname, port, databases, user = NULL, password = NULL)
{
  server <- {};
  server$name = name;
  server$dbms = dbms;
  server$hostname = hostname;
  if (!missing(port) && !is.null(port))
  {
    server$port = port;
  }
  server$databases = databases;

  server$user = user;
  server$password = password;

  return (server)
}

#' @export
buildDatabase <- function(id, name, cdmSchema, resultsSchema = NULL, resultsTable = NULL)
{
  dataSource <- {};
  dataSource$id = id;
  dataSource$name = name;
  dataSource$schema = cdmSchema;
  dataSource$resultsSchema = resultsSchema;
  dataSource$resultsTable = resultsTable;
  return(dataSource);
}

#' @export
createGraphsFromStudy <- function(servers) {

  outputFolder <- "output"
  for (server in servers)
  {
    serverFolder <- paste(outputFolder, server$name, sep="/");

    if (!file.exists(serverFolder))
      dir.create(serverFolder);


    connectionDetails <- DatabaseConnector::createConnectionDetails(dbms=server$dbms, server=server$hostname, port=server$port, user = server$user, password = server$password);

    conn <- DatabaseConnector::connect(connectionDetails);

    for (database in server$databases)
    {

      databaseOutputFolder <- paste(serverFolder, database$name, sep="/");
      if (!file.exists(databaseOutputFolder))
        dir.create(databaseOutputFolder)

      # copy .css and .js depedencies to output folder
      file.copy(system.file(from="template","sequences.js", package="ExposurePathway"), to=databaseOutputFolder);
      file.copy(system.file(from="template","sequences.css", package="ExposurePathway"), to=databaseOutputFolder);


      cdmDatabaseSchema <- database$schema;
      if (nchar(database$name) > 0)
        cdmDatabaseSchema <- paste(database$name, cdmDatabaseSchema, sep=".");

      resultsDatabaseSchema <- database$resultsSchema;
      resultsTable <- database$resultsTable;

      # Generate exposure sequence
      exposureNamesSql <- SqlRender::readSql(system.file("sql","getConceptNamesFromStudy.sql", package="ExposurePathway"));
      renderedSql <- SqlRender::renderSql(exposureNamesSql,
                                          cdm_database_schema = cdmDatabaseSchema,
                                          results = resultsDatabaseSchema,
                                          resultsTable = resultsTable
      )$sql;
      translatedSql <- SqlRender::translateSql(renderedSql, targetDialect = connectionDetails$dbms, oracleTempSchema = database$tempSchema)$sql;
      conceptNamesDF <- DatabaseConnector::querySql(conn, translatedSql);
      write.table(conceptNamesDF, file=paste(databaseOutputFolder, "conceptNames.txt", sep="/"), row.names=FALSE, col.names=TRUE, quote=FALSE, sep="\t");

      # Create exposure paths

      # init #EXPOSURE_PATH with people from first exposure
      exposurePathsSql <- SqlRender::readSql(system.file("sql","getPathsFromStudy.sql", package="ExposurePathway"));
      renderedSql <- SqlRender::renderSql(exposurePathsSql,
                                          cdm_database_schema = cdmDatabaseSchema,
                                          indexYear = 9999,
                                          results = resultsDatabaseSchema,
                                          resultsTable = resultsTable
      )$sql;
      # TODO concat SQL Server
      # translatedSql <- SqlRender::translateSql(renderedSql, targetDialect = connectionDetails$dbms, oracleTempSchema = database$tempSchema)$sql;
      # pathsDF <- DatabaseConnector::querySql(conn, translatedSql);
      pathsDF <- DatabaseConnector::querySql(conn, renderedSql);
      temp<-matrix(apply(pathsDF[pathsDF$INDEX_YEAR==9999,2:(ncol(pathsDF)-1)], 1, paste, collapse='-'), ncol=1);
      temp<-gsub("-NA","",temp);
      temp<-gsub(" ","",temp);

      temp= data.frame(DRUG_PATH=paste0(temp,"-end"),MEMBERS=pathsDF[pathsDF$INDEX_YEAR==9999,ncol(pathsDF)]);
      write.table(temp, file=paste(databaseOutputFolder, "exposurePaths.txt", sep="/"), row.names=FALSE, col.names=TRUE, quote=FALSE, sep="\t");

      # Create sunburst plot
      htmlTemplate <- readLines(system.file("template","sunburstPath.html", package="ExposurePathway"));
      exposurePathsTSV <- readLines(paste(databaseOutputFolder, "exposurePaths.txt", sep="/"));
      conceptNamesTSV <- readLines(paste(databaseOutputFolder, "conceptNames.txt", sep="/"));

      htmlTemplate <- gsub("@pathways",paste(exposurePathsTSV, collapse="\n"), htmlTemplate);
      htmlTemplate <- gsub("@conceptNames",paste(conceptNamesTSV, collapse="\n"), htmlTemplate);

      cat(htmlTemplate, file=paste(databaseOutputFolder, paste(database$id, "html", sep="."), sep="/"));

    }

    closed <- DBI::dbDisconnect(conn)
  }
}
