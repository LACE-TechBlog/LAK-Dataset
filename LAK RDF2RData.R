
## This is a slightly modified version of Adam Cooper's RDF to dataframe script to work with the latest LAK dataset

## ***Made available using the The MIT License (MIT)***
# Copyright (c) 2012, Adam Cooper
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
## ************ end licence ***************

#A short piece of code to extract from the LAK Dataset, which is RDF, and to create data.frames for saving as .RData
#See http://www.solaresearch.org/resources/lak-dataset/
#install.packages("rrdf")
#library("rrdf")


#install.packages("rJava") # if not present already
#install.packages("devtools") # if not present already
#library(devtools)
#install_github("rrdf", "egonw", subdir="rrdflibs")
#install_github("rrdf", "egonw", subdir="rrdf")

library(rrdflibs)
library(rrdf)


read.me<-"This is the LAK Challenge Dataset (LAK, JETS and EDM combined). Please see http://www.solaresearch.org/resources/lak-dataset/ for the data from which it was created and for the terms and conditions of use. It has been created using the RDF version using code at http://crunch.kmi.open.ac.uk/people/~acooper/LAK%20RDF2RData.R . Please report issues with the R script and R version of the data to a.r.cooper [at] bolton.ac.uk and consult http://www.solaresearch.org/resources/lak-dataset/ for other queries. There is no warranty of any kind; you use this at your own risk and without any commitment to support."


triples<-new.rdf()
triples<-load.rdf("Data/LAK-DATASET-DUMP.rdf", "RDF/XML")

summarize.rdf(triples)

#these should be the times the source data files were created from the triple store
get.time<-function(f){
  file.info(f)$mtime
}
mtimes<-lapply("Data/LAK-DATASET-DUMP.rdf", get.time)

#these queries use OPTIONAL in case some content is missing. This may be unnecessary.
#people and papers have row.names set to the subject identifier but authorship has no such

#extract the people (but not their authorship)
people.query<- paste("PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>",
                     "PREFIX swrc: <http://swrc.ontoware.org/ontology#>",
                     "PREFIX foaf: <http://xmlns.com/foaf/0.1/>",
                     "SELECT ?person ?name ?location ?affiliation WHERE {",
                     "?person rdf:type foaf:Person;",
                     "foaf:name ?name .",
                     "OPTIONAL{",
                     "?person foaf:based_near ?location;",
                     "swrc:affiliation ?affiliation;",
                     "foaf:firstName ?firstName;",
                     "foaf:lastName ?lastName",
                     "}",
                     "}")
people<-as.data.frame(sparql.rdf(triples,people.query,rowvarname="person"))

#extract the papers
papers.query<-paste("PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>",
                    "PREFIX swrc: <http://swrc.ontoware.org/ontology#>",
                    "PREFIX dc: <http://purl.org/dc/elements/1.1/>",
                    "PREFIX swc: <http://data.semanticweb.org/ns/swc/ontology#>",
                    "PREFIX led: <http://data.linkededucation.org/ns/linked-education.rdf#>",
                    "SELECT ?paper ?origin ?month ?year ?title ?abstract ?content WHERE {",
                    "?paper rdf:type swrc:InProceedings;",
                    "swc:isPartOf ?origin;",
                    "dc:title ?title;",
                    "swrc:abstract ?abstract;",
                    "swrc:month ?month;",
                    "swrc:year ?year .",
                    "OPTIONAL{?paper led:body ?content}",
                    "}")

papers<-as.data.frame(sparql.rdf(triples,papers.query,rowvarname="paper"))

#extract the authorship. a data.frame isn't elegant for doing anything with; should be transformed to a network object of some kind.
#2012-12-18 added ?name for convenience
authorship.query<-paste("PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>",
                        "PREFIX swc: <http://data.semanticweb.org/ns/swc/ontology#>",
                        "PREFIX foaf: <http://xmlns.com/foaf/0.1/>",
                        "SELECT ?person ?name ?paper ?origin WHERE {",
                        "?person rdf:type foaf:Person;",
                        "foaf:name ?name ;",
                        "foaf:made ?paper .",
                        "OPTIONAL{?paper swc:isPartOf ?origin}",
                        "}")

authorship<-as.data.frame(sparql.rdf(triples,authorship.query))

save(read.me, people, papers, authorship, mtimes, file="LAK-Dataset.RData")

#quick view of authorship network
#install.packages('network')
#library(network)
#net<-network(authorship[,c(1,3)])
#plot(net, vertex.cex=0.6, arrowhead.cex=0.5)


