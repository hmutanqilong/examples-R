#' # Protein expression (MDAnderson RPPA)
#' 
#' The goal of this notebook is to introduce you to the Protein expression BigQuery table.
#' This table contains all available TCGA Level-3 protein expression data produced by MD Anderson's RPPA pipeline, as of October 2015. (Actual archive dates range from July 2013 to August 2015.) The most recent archives (eg mdanderson.org_COAD.MDA_RPPA_Core.Level_3.2.0.0) for each of the 32 tumor types was downloaded from the DCC, and data extracted from all files matching the pattern %_RPPA_Core.protein_expression%.txt. Each of these “protein expression” files has two columns: the Composite Element REF and the Protein Expression. In addition, each mage-tab archive contains an antibody_annotation file which is parsed in order to obtain the correct mapping between antibody name, protein name, and gene symbol. During the ETL process, portions of the protein name and the antibody name were extracted into additional columns in the table, including Phospho, antibodySource and validationStatus.
#' 
#' In order to work with BigQuery, you need to import the bigrquery library and you need to know the name(s) of the table(s) you are going to be working with:
#' 
#' 
## ----message=FALSE-------------------------------------------------------
require(bigrquery) || install.packages("bigrquery")
require(ggplot2) || install.packages("ggplot2")

library(ISBCGCExamples)

protTable <- "[isb-cgc:tcga_201510_alpha.Protein_RPPA_data]"

#' 
#' Let's start by taking a look at the table schema:
#' 
## ------------------------------------------------------------------------
querySql <- paste("SELECT * FROM ",protTable," limit 1", sep="")
result <- query_exec(querySql, project=project)
data.frame(Columns=colnames(result))

#' 
#' Let's count up the number of unique patients, samples and aliquots mentioned in this table. We will do this by defining a very simple parameterized query. (Note that when using a variable for the table name in the FROM clause, you should not also use the square brackets that you usually would if you were specifying the table name as a string.)
#' In [3]:
#' 
#' 
## ------------------------------------------------------------------------
for (x in c("ParticipantBarcode", "SampleBarcode", "AliquotBarcode")) {
  querySql <- paste("SELECT COUNT(DISTINCT(",x,"), 25000) AS n ",
                    "FROM ",protTable)
  result <- query_exec(querySql, project=project)
  cat(x, ": ", result[[1]], "\n")
}

#' 
#' We can do the same thing to look at how many unique gene symbols and proteins exist in the table:
#' 
## ------------------------------------------------------------------------
for (x in c("Gene_Name", "Protein_Name", "Protein_Basename")) {
  querySql <- paste("SELECT COUNT(DISTINCT(",x,"), 25000) AS n ",
                    "FROM ",protTable)
  result <- query_exec(querySql, project=project)
  cat(x, ": ", result[[1]], "\n")
}

#' 
#' Based on the counts, we can see that there are several genes for which multiple proteins are assayed, and that overall this dataset is quite small compared to most of the other datasets. Let's look at which genes have multiple proteins assayed:
#' 
## ------------------------------------------------------------------------

querySql <- "
SELECT
  Gene_Name,
  COUNT(*) AS n
FROM (
  SELECT
    Gene_Name,
    Protein_Name,
  FROM
    [isb-cgc:tcga_201510_alpha.Protein_RPPA_data]
  GROUP BY
    Gene_Name,
    Protein_Name )
GROUP BY
  Gene_Name
HAVING
  ( n > 1 )
ORDER BY
  n DESC"

results <- query_exec(querySql, project=project)
head(results[order(results$n, decreasing=T),])

#' 
#' Let's look further in the the EIF4EBP1 gene which has the most different proteins being measured:
#' 
## ------------------------------------------------------------------------

querySql <- "
SELECT
  Gene_Name,
  Protein_Name,
  Phospho,
  antibodySource,
  validationStatus
FROM
  [isb-cgc:tcga_201510_alpha.Protein_RPPA_data]
WHERE
  ( Gene_Name='EIF4EBP1' )
GROUP BY
  Gene_Name,
  Protein_Name,
  Phospho,
  antibodySource,
  validationStatus
ORDER BY
  Gene_Name,
  Protein_Name,
  Phospho,
  antibodySource,
  validationStatus"

results <- query_exec(querySql, project=project)

#' 
#' Some antibodies are non-specific and bind to protein products from multiple genes in a gene family. One example of this is the AKT1, AKT2, AKT3 gene family. This non-specificity is indicated in the antibody-annotation file by a list of gene symbols, but in this table, we duplicate the entries (as well as the data values) on multiple rows:
#' 
## ------------------------------------------------------------------------

querySql <- "
SELECT
  Gene_Name,
  Protein_Name,
  Phospho,
  antibodySource,
  validationStatus
FROM
  [isb-cgc:tcga_201510_alpha.Protein_RPPA_data]
WHERE
  ( Gene_Name CONTAINS 'AKT' )
GROUP BY
  Gene_Name,
  Protein_Name,
  Phospho,
  antibodySource,
  validationStatus
ORDER BY
  Gene_Name,
  Protein_Name,
  Phospho,
  antibodySource,
  validationStatus"

  results <- query_exec(querySql, project=project)
  results

#' 
## ------------------------------------------------------------------------

querySql <- "
SELECT
  SampleBarcode,
  Study,
  Gene_Name,
  Protein_Name,
  Protein_Expression
FROM
  [isb-cgc:tcga_201510_alpha.Protein_RPPA_data]
WHERE
  ( Protein_Name='Akt' )
ORDER BY
  SampleBarcode,
  Gene_Name
LIMIT
  9"

results <- query_exec(querySql, project=project)
results

