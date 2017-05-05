database="IPCI-EEYORE_20170309"

server = ExposurePathway::buildServer(name="IPCI2",
                                      dbms="postgresql",
                                      hostname=paste0("localhost/",database),
                                      port="5432",
                                      databases = list(
                                        ExposurePathway::buildDatabase("ICPI-EEYORE",'depression', "cdm", "results",
                                                                       "depression_ipci_eeyore_20170309_seq_cnt"),
                                        ExposurePathway::buildDatabase("ICPI-EEYORE",'htn', "cdm", "results",
                                                                       "htn_ipci_eeyore_20170309_seq_cnt"),
                                        ExposurePathway::buildDatabase("ICPI-EEYORE",'t2dm', "cdm", "results",
                                                                       "t2dm_ipci_eeyore_20170309_seq_cnt")
                                      ),
                                      user="postgres",
                                      password="pjotter1");




ExposurePathway::createGraphsFromStudy(servers=list(server))

# test to run all JnJ drugs
ExposurePathway::execute(servers=list(server), maxPathSize = 4)

