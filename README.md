# DotDensityscript
Includes an R script to generate a Dot Density map of a chosen space in the US.  The script projects the map at the County level to include the populous downtown area along with the more sparsely populated urban periphery.

Each map includes the four major racial/ethnic groups, while those identifying as Native American, Hawaiian and Pacific Islander, and two or more races are pooled together in order to create a visualizable total.

The data is aggregated to the block group level within the County boundary and is sourced from the 2020 P2 Census dataset. 

The purpose of these maps is to visualize the social formations of metropolitan areas and to illustrate the general trends in clustering and dispersal of the population.

Can also edit the location of the map, the dot total, the race variables, and various elements of the map.

This project is based on Walker's Tidycensus package for data wrangling and the Ggplot package for vizualisation.


References

Walker, K. (2023). *Analyzing US Census Data: Methods, Maps, and Models in R* (1st ed.). CRC Press.

[![alt text](philly.png)
](https://github.com/github/{BillySouthern}/DotDensityscript/Philly.png)
