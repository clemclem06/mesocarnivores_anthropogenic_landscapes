The raw camera-trap data employed in this study can be requested at Snapshot Safari (snapshotsafari.org).

The code was developed on R 4.3. All files must be placed in the same working directory.

1) Diversity analysis: To run the diversity analysis, you need the 'diversity.R' and 'diversity.xlsx' files.

The file diversity.xlsx contains the number of sightings by species for each sub-site. Species are listed in the following order: Caracal, Honey badger, Large grey mongoose, Small grey mongoose, Water mongoose, Yellow mongoose, African clawless otter, Bat-eared fox, Cape fox, Large spotted genet, Aardwolf, Jackal, African wild cat, Leopard. 

Diversity analysis aim to determine the community’s profiles, i.e. the community diversity (Marcon & Hérault 2015). The community profile, or the effective number of species, represents the Hill number of the true diversity (Jost 2006). It is  the number of equally abundant species needed to have the same diversity as our dataset. This number depend on the diversity order, i.e. the importance given to rare species (with 0 meaning all species are considered equal and the infinite meaning only the dominant species is considered). 

The R script generates the diversity plot in PNG format.

2) Temporal analysis: To run the temporal analysis, you will need the temporal.R script, the three detection tables ('GAR_data_meso_30min.xlsx', 'OVE_data_meso_30min.xlsx', and' DHP_data_meso_30min.xlsx'), and the associated metadata files (GAR_metadata_dim_withpop.xlsx and OVE_DHP_habitat_dim.xlsx).

The columns "Setup_date" and "Retrieval_date" correspond to camera deployment and retrieval dates. "ProblemX_from" and "ProblemX_to" indicate malfunction periods. The remaining columns contain site metadata, with "dim1" and "dim2" representing PCA axis.

The R script generates temporal co-occurrence values in Excel format. Co-occurence is calculated  asa coefficient ranging from 0 (no temporal overlap) to 1 (identical activity patterns), by estimating the area under the intersection of two kernel density curves representing the daily activity patterns of the species (Bernard 2023; Ridout & Linkie 2009).

3) Occupancy analysis : To run the occupancy analysis, you will need the detection matrices 'y_gar_all8_2021_05_01_2021_10_31.rds' and 'y_gar_all8_2021_11_01_2022_04_30.rds' (1 = detection, 0 = non-detection, NA = camera malfunction), the occupancy script (e.g., occupancy.R), and the metadata file for the Garden Route ('GAR_metadata_dim_withpop.xlsx').

The columns "Setup_date" and "Retrieval_date" correspond to camera deployment and retrieval dates. "ProblemX_from" and "ProblemX_to" indicate malfunction periods. The remaining columns contain site metadata, with "dim1" and "dim2" representing PCA results.

The R script generates spatial co-occurrence values and occupancy results in Excel format. Both single species and multi-species models are run using the unmarked package. Detection variable is "vision". Occupancy variables are the first two axis of the PCA, the statut (protected or not) and the population density.
