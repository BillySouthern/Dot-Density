#Dot density mapping of block groups by County
#Load packages
library(tidycensus)
library(tidyverse)
library(tigris)
options(tigris_use_cache = TRUE)

library(sf)
library(ggsn)
library(ggspatial)

#-------------------------------------------------------------------------------
#MAPPING BY RACE AND ETHNICITY
#Creating dot density for block groups by county
#Create geographies and values
GEOG = "block group"
ST = "PA"
COUNTY = c("Philadelphia")
DOTS = 50

race_groups = c(Total = "P2_001N",
                Hispanic = "P2_002N",
                White = "P2_005N",
                Black = "P2_006N",
                Asian = "P2_008N")

# Get data from tidycensus
Race <- get_decennial(
  geography = GEOG,
  variables = race_groups,
  state = ST,
  county = COUNTY,
  geometry = TRUE,
  year = 2020,
  output = "wide"
)   
sf::sf_use_s2(FALSE)

#Erase water from the chosen geography
Race <- erase_water(Race)

#Mutate multiple groups to small groups
Race <- Race %>%
  mutate(Race, "Small Group" = Total - Hispanic - White - Black - Asian) %>%
  select(GEOID, NAME, Hispanic, White, Black, Asian, "Small Group") %>%
  pivot_longer((Hispanic:"Small Group")) 

#Create sf object and shift geometry (shift geometry is simple way to change the projection to Albers)
Race <- Race %>% 
  st_as_sf(coords = c('lonCust', 'latCust')) %>%
  shift_geometry()

# Convert data to project the dots
Dots <- as_dot_density(
  Race,
  value = "value",
  values_per_dot = DOTS,
  group = "name"
)

# Use one set of polygon geometries as a base layer
BlockGroup <- Race[Race$name == "Hispanic", ]

#Create the plot.  Change the title, number of dots, and scale
ggplot() +
  geom_sf(data = BlockGroup,
          fill = "#505050",
          color = "black",
          alpha = 50) +
  geom_sf(data = Dots,
          aes(color = name),
          size = 0.02) +
  ggtitle(label = "P  H  I  L  A  D  E  L  P  H  I  A") +
  scale_color_manual(values=c("#80ff80","#00ffff", "#ffff00", "#ff00ff","#ff0000")) +
  scalebar(Race, 
           location = "bottomright",
           dist = 2.5,
           st.dist = 0.02,
           border.size = 0.3,
           st.size = 3,
           height = 0.01,
           box.fill = "#704214",
           transform = FALSE,
           model = "International",
           dist_unit = "km") +
  theme_void() +
  theme(panel.background = element_rect(fill = "#ffeacb", size = 6, color = "#545454"),
        plot.background = element_blank()) +
  theme(legend.position = c(0.85, 0.17),
        plot.title = element_text(hjust = 0.5, size = 26),
        plot.subtitle = element_text(hjust = 0.5, size = 12),
        legend.text = element_text(size = 6),
        legend.key.size = unit(0.8, 'lines'),
        legend.title=element_text(size = 7)) +
  guides(color = guide_legend(override.aes = list(size = 2.0), 
                              title = "1 dot = 50 persons"))


#-------------------------------------------------------------------------------
#MAPPING INCOME
#download data
Income_Data <- map_dfr(state_codes, ~{
  get_acs(geography = GEOG,
          state = "CA",
          variables = c(
            Less_than_10000 = "B19001_002",
            Between_10000_and_14999 = "B19001_003",
            Between_15000_and_19999 = "B19001_004",
            Between_20000_and_24999 = "B19001_005",
            Between_25000_and_29999 = "B19001_006",
            Between_30000_and_34999 = "B19001_007",
            Between_35000_and_39999 = "B19001_008",
            Between_40000_and_44999 = "B19001_009",
            Between_45000_and_49999 = "B19001_010",
            Between_50000_and_59999 = "B19001_011",
            Between_60000_and_74999 = "B19001_012",
            Between_75000_and_99999 = "B19001_013",
            Between_100000_and_124999 = "B19001_014",
            Between_125000_and_149999 = "B19001_015",
            Between_150000_and_199999 = "B19001_016",
            Above_200000 = "B19001_017"
          ),
          year = YR) %>%
    summarize(n = sum(estimate, na.rm = TRUE), 
              .by = c(GEOID, variable)) %>%
    rename(group = variable)
})  %>%
  group_by(GEOID) %>%
  mutate(
    group = ifelse(group %in% c("Less_than_10000", "Between_10000_and_14999", 
                                "Between_15000_and_19999", "Between_20000_and_24999"), 
                   "Less_than_$25,000", group),
    group = ifelse(group %in% c("Between_25000_and_29999", "Between_30000_and_34999", 
                                "Between_35000_and_39999", "Between_40000_and_44999", "Between_45000_and_49999"), 
                   "Between_25000_and_49999", group),
    group = ifelse(group %in% c("Between_50000_and_59999", "Between_60000_and_74999", 
                                "Between_75000_and_99999"), 
                   "Between_50000_and_99999", group),
    group = ifelse(group %in% c("Between_100000_and_124999", "Between_125000_and_149999"), 
                   "Between_100000_and_149999", group)
  ) %>%
  group_by(GEOID, group) %>%
  summarise(n = sum(n)) %>%
  ungroup() 

#Working the geographies
CBSA = "San Francisco"
# COUNTIES = c("Multnomah", "Clackamas", "Washington", "Yamhill", "Columbia")

#Load Geographies
#Download geographies of interest (in this case, the Richmond CBSA boundary
CBSA_2020 <- core_based_statistical_areas(resolution = "500k", year = YR4) %>%
  filter(str_detect(NAMELSAD, CBSA)) 

#Download Counties
# Counties <- counties("OR", year = YR4, cb = T) %>%
#   filter(NAME %in% COUNTIES) 

#Acquiring the cities within VA
# CentralCities_2020 <- places(state = "GA", year = YR4) #%>%

#Download tracts of for VA, prior to a clip
Block_Groups_2020 <- map_dfr(c("CA"), ~{
  block_groups(.x, year = YR4)}) %>%
  select(GEOID, geometry) %>%
  filter(lengths(st_within(., CBSA_2020)) > 0) 
  
#Join block group geometries to income data
Income_Data <- Block_Groups_2020 %>%
  left_join(Income_Data, by ="GEOID") 

#Switch spherical off
sf::sf_use_s2(FALSE)

#Erase water from the chosen geography
CBSA_2020 <- erase_water(CBSA_2020)
Block_Groups_2020 <- erase_water(Income_Data)

# Convert data to project the dots
Dots <- as_dot_density(
  Block_Groups_2020,
  value = "n",
  values_per_dot = 50,
  group = "group"
)

#Create the plot.  Change the title, number of dots, and scale
ggplot() +
  geom_sf(data = CBSA_2020,
          fill = "#140719",
          color = "black",
          alpha = 50) +
  geom_sf(data = Dots,
          aes(color = group),
          size = 0.015) +
  ggtitle(label = "San Francisco") +
  scale_color_manual(values=c("Less_than_$25,000" = "#ffffb2",
                              "Between_25000_and_49999" = "#fed976", 
                              "Between_50000_and_99999" = "#feb24c", 
                              "Between_100000_and_149999" = "#fd8d3c",
                              "Between_150000_and_199999" = "#f03b20", 
                              "Above_200000" = "#bd0026"),
                     labels = c("Less_than_$25,000" = "Less than $25,000",
                                "Between_25000_and_49999" = "$25,000 to $49,999", 
                                "Between_50000_and_99999" = "$50,000 to $99,999", 
                                "Between_100000_and_149999" = "$100,000 to $149,999",
                                "Between_150000_and_199999" = "$150,000 to $199,999", 
                                "Above_200000" = "More than $200,000"),
                     limits = c(
                       "Less_than_$25,000", 
                       "Between_25000_and_49999", 
                       "Between_50000_and_99999", 
                       "Between_100000_and_149999", 
                       "Between_150000_and_199999", 
                       "Above_200000"
                     )) +
  theme_void() +
  theme(
    panel.background = element_rect(fill = alpha("#383838", 1), size = 4, color = "black"),
    plot.background = element_blank(),
    legend.background = element_rect(fill = "transparent", color = NA),
    legend.position = c(0.85, 0.2),
    legend.key = element_rect(fill = "transparent", color = NA),  # Removes grey background from legend symbols
    plot.title = element_text(size = 20, hjust = 0.975, vjust = -6, colour = "white"),  # Adjust title position
    plot.subtitle = element_text(hjust = 0.5, size = 12),
    legend.text = element_text(size = 8, colour = "white"),
    legend.title = element_text(color = "white", size = 12, face = "bold")
  ) +
  guides(color = guide_legend(override.aes = list(size = 1.75), 
                              title = "1 dot = 50 Households"))
