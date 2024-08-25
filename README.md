# Dot Density maps
Includes an R script to generate a dot density map using ACS and census data.  

The two variables of interest include race/ethnicity counted in the 2020 decennial census and income counts using ACS 2016-2020 data. Both variables are aggregated to a second level, and projected at the block-group level. The location of the map, dot total, and variables of interest can be edited and amended.

The project uses Walker's Tidycensus package for data and the ggplot package for vizualisation.

Income count for Washington DC.
<p align="center">
  <img width="498" alt="image" align="center" src="https://raw.githubusercontent.com/BillySouthern/Dot-Density/b339a58a231e01b047bef59d57da91b5ef450a0d/DC.png">
</p>


Race and ethnicity across Philadelphia County.
<p align="center">
  <img width="498" alt="image" align="center" src="https://user-images.githubusercontent.com/91633301/190879950-24f82d78-284b-4816-8a64-928166278f2e.png">
</p>


References

Walker, K. (2023). *Analyzing US Census Data: Methods, Maps, and Models in R* (1st ed.). CRC Press.
