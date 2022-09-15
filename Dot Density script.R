#Dot density mapping of block groups by County
#Load packages
library(tidycensus)
library(tidyverse)
library(tigris)
options(tigris_use_cache = TRUE)
library(ggplot2)
library(sf)
library(ggsn)

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


#Export the plot
ggsave("Philly.png",
       path = "~/desktop",
       width = 6,
       height = 8,
       units = "in",
       dpi = 300)

