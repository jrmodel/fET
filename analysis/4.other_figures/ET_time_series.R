# load libraries
library(tidyverse)
library(lubridate)
library(ggpubr)
library(grid)
library(bigleaf)

### DK-Sor
load("data/output/DK-Sor/data_frames/out_DK-Sor.RData") # load output of ML model
load("data/output/DK-Sor/data_frames/ddf_DK-Sor.RData") # load input of ML model

# merge output and input dataframes
plottin <- out$df_all %>%
  left_join(ddf %>% dplyr::select(date, TA_F, NETRAD), by ="date") %>%
  mutate(NETRAD = LE.to.ET(NETRAD, TA_F)*24*60*60)  # convert NETRAD to mass units (same of ET -- kg/m2*d)

# get coeff to scale netrad
lm_model = lm(nn_pot ~ NETRAD + 0, plottin)
coeff = lm_model[["coefficients"]][["NETRAD"]]

# calculate scaled netrad
plottin <- plottin %>%
  mutate(NETRAD_coeff = NETRAD*coeff)

# rename df and create column for long format
site_1 <- plottin
site_1$site <- "DK-Sor"


### US-Ton
load("data/output/US-Ton/data_frames/out_US-Ton.RData") # load output of ML model
load("data/output/US-Ton/data_frames/ddf_US-Ton.RData") # load input of ML model

# merge output and input dataframes
plottin <- out$df_all %>%
  left_join(ddf %>% dplyr::select(date, TA_F, NETRAD), by ="date") %>%
  mutate(NETRAD = LE.to.ET(NETRAD, TA_F)*24*60*60)  # convert NETRAD in same units of ET (kg/m2*d)

# get coeff to scale netrad
lm_model = lm(nn_pot ~ NETRAD + 0, plottin)
coeff = lm_model[["coefficients"]][["NETRAD"]]

# calculate scaled netrad
plottin <- plottin %>%
  mutate(NETRAD_coeff = NETRAD*coeff)

# rename df and create column for long format
site_2 <- plottin
site_2$site <- "US-Ton"

# combine both sites, with a site column
df_raw <- bind_rows(site_1, site_2)

# calculate seasonality
df <- df_raw %>%
  mutate(
    day_of_the_year = lubridate::yday(date)
  ) %>%
  group_by(site, day_of_the_year) %>%
  summarise(
    nn_pot = mean(nn_pot, na.rm = TRUE),
    nn_act = mean(nn_act, na.rm = TRUE),
    fvar = mean(fvar, na.rm = TRUE),
    obs = mean(obs, na.rm = TRUE),
    netrad = mean(NETRAD_coeff, na.rm = TRUE),
    moist = mean(moist, na.rm = TRUE)
  ) %>%
  mutate(
    date = as.Date(paste(2000, day_of_the_year), "%Y %j"),
    month = format(date, "%b")
  ) %>%
  group_by(site) %>%
  # pivot wide data to long data with the names
  # of the columns assigned to "names" and the
  # values to "value"
  pivot_longer(
    cols = c(nn_pot, nn_act, obs, netrad),
    names_to = "names",
    values_to = "value"
  ) %>%
  ungroup() %>%
  mutate(moist = as.logical(moist)) %>%
  mutate(dry = !moist)

# annotation
grob_a <- grobTree(textGrob("DK-Sor", x=0.01,  y=0.95, hjust=0,
                          gp=gpar(col="black", fontsize=14, fontface="bold")))


# plot
a <- ggplot(data = df %>% dplyr::filter(site == "DK-Sor")) +
  geom_path(
    aes(
      date,
      value,
      color = names,
      group = names,
      linetype = names,
    ),
    size=0.6
  ) +
  labs(
    x = "Month",
    y = expression(paste("ET (mm ", d^-1, ")"))
  ) +
  theme_classic() +
  theme(legend.title=element_blank()) +
  scale_color_manual(  # set line colors
    values = c(obs = "#333333",
               nn_act = "#0072B2", # blue
               nn_pot = "#D81B60", # red
               netrad = "#BBCC33"), # green
    labels = c(obs = expression(paste(ET[obs])), # set labels for legend
               nn_act = expression(paste(ET[NN])),
               nn_pot = expression(paste(PET[NN])),
               netrad = "Net Radiation"
               )
  ) +
  scale_linetype_manual(  # set line types
    values = c(obs = "solid",
               nn_act = "solid",
               nn_pot = "solid",
               netrad = "dashed"
              ),
    guide = "none" # hide legend for lines
  ) +
  scale_x_date(date_breaks="1 month", date_labels = "%b") + # set correct x axis
  annotation_custom(grob_a) +
  theme( # set legend position and orientation, as well as text size
    legend.position = "top",
    legend.direction = "horizontal",
    legend.justification = "left",
    axis.text=element_text(size = 12),
    axis.title=element_text(size = 14),
    legend.text=element_text(size = 12)
  ) +
  ylim(0,4.3) # set limits of y axis
plot(a)

grob_b <- grobTree(textGrob("US-Ton", x=0.01,  y=0.95, hjust=0,
                          gp=gpar(col="black", fontsize=14, fontface="bold")))
b <- ggplot(data = df %>% dplyr::filter(site == "US-Ton")) +
  geom_path(
    aes(
      date,
      value,
      color = names,
      group = names,
      linetype = names,
    ),
    size=0.6
  ) +
  labs(
    x = "Month",
    y = expression(paste("ET (mm ", d^-1, ")"))
  ) +
  theme_classic() +
  theme(legend.title=element_blank()) +
  scale_color_manual(  # set line colors
    values = c(obs = "#333333",
               nn_act = "#0072B2", # blue
               nn_pot = "#D81B60", # red
               netrad = "#BBCC33"), # green
    labels = c(obs = expression(paste(ET[obs])), # set labels for legend
               nn_act = expression(paste(ET[NN])),
               nn_pot = expression(paste(PET[NN])),
               netrad = "Net Radiation"
    )
  ) +
  scale_linetype_manual(
    values = c(obs = "solid",
               nn_act = "solid",
               nn_pot = "solid",
               netrad = "dashed"
    ),
    guide = "none"
  ) +
  scale_x_date(date_breaks="1 month", date_labels = "%b") +
  annotation_custom(grob_b) +
  theme(
    legend.position = "top",
    legend.direction = "horizontal",
    legend.justification = "left",
    axis.text=element_text(size = 12),
    axis.title=element_text(size = 14),
    legend.text=element_text(size = 12)
  ) +
  ylim(0,4.3)
plot(b)

# create combined figure with subpanels
ggarrange(a, b,
          labels = c("a", "b"),
          ncol = 1, nrow = 2,
          common.legend = TRUE, # have just one common legend
          legend="top") # and place it in the bottom

# save
ggsave("ET_time_series.png", path = "./", width = 9, height = 8)





