# Survey Documentation

This folder stores public documentation used to construct consumption measures
from POF and ELSI.

## Sources

- POF 2017-2018 microdata documentation:
  https://ftp.ibge.gov.br/Orcamentos_Familiares/Pesquisa_de_Orcamentos_Familiares_2017_2018/Microdados/
- ELSI-Brasil data access notes:
  https://elsi.cpqrr.fiocruz.br/data-access/
- ELSI-Brasil questionnaires:
  https://elsi.cpqrr.fiocruz.br/questionario/

## Contents

- `pof_documentacao/`: extracted POF dictionaries, product registries,
  strata files, and survey documentation.
- `pof_questionarios/`: extracted POF questionnaire PDFs.
- `pof_leiame_microdados.pdf`: POF microdata readme.
- `elsi_entrevista_domiciliar_2015_16.pdf`: ELSI wave 1 household
  questionnaire.
- `elsi_entrevista_individual_2015_16.pdf`: ELSI wave 1 individual
  questionnaire.
- `pof_documentacao_20230713.zip` and `pof_questionarios_20210423.zip`:
  original downloaded POF archives.

## Consumption Measurement Notes

POF should be used for absolute consumption levels because it is the detailed
household budget survey. Consumption should be computed at the `NUM_UC`
consumption-unit level and divided by the number of residents in that unit,
rather than by total household size when a household contains multiple
consumption units.

ELSI should mainly be used for profiles across elderly or pension-related
cells. Its documentation defines per-capita household income as household
income divided by the number of household residents. Any ELSI expenditure or
consumption proxy should apply the same household-resident denominator and use
the complex survey design variables described in the data access notes.
