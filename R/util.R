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
buildDatabase <- function(id, name, schema)
{
  dataSource <- {};
  dataSource$id = id;
  dataSource$name = name;
  dataSource$schema = schema;

  return(dataSource);
}

