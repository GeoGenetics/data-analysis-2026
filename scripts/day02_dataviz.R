## --------------------------------------------------------
## Day 2, afternoon - Data visualization
##
## Fundamentals in Computational Analysis of Large-Scale Datasets 2026
## --------------------------------------------------------

# We build visualizations with ggplot2 (https://ggplot2.tidyverse.org/),
# part of the tidyverse, which implements a *grammar of graphics*: a small
# set of components that combine to describe any statistical graphic.

# We will cover

# * ggplot2 basics: data, geoms, mappings
# * Aesthetics, and the difference between mapping and setting
# * Geometric shapes, and what a plot shows that a summary hides
# * Two things about scales: viridis, and zooming versus limiting
# * Ordering categories
# * Labels, titles and captions
# * Facets
# * Saving a figure
#
# Themes, more scales, and multi-geom plots are at the end of the
# file under "READING". 

# HOW THE QUESTIONS WORK
#
# Every `## Q` below is labelled with what to do when you reach it:
#
#   TRY IT         Two or three minutes, then compare.


## --------------------------------------------------------
## libraries

library(tidyverse)
theme_set(theme_minimal())

## --------------------------------------------------------
## datasets

# As this morning: open the .Rproj first, so relative paths work.

covid <- read_csv("data/covid_day2.csv")

# We also use a smaller subset of eight countries for readable figures.
# Thirty-two lines on one plot is a spaghetti diagram, not a figure.

countries <- c(
  "Denmark", "India", "Israel", "Japan",
  "South Africa", "United States", "Brazil", "Nigeria"
)

covid_subset <- covid |> filter(country %in% countries)

covid_subset


## --------------------------------------------------------
## ggplot2 basics

# The most basic ggplot2 visualization uses this minimal syntax:

# ggplot(data = <DATA>) +
#   <GEOM_FUNCTION>(mapping = aes(<MAPPINGS>))

# `ggplot()` sets up the plot and the data. A geom draws something.
# `aes()` says which variable controls which visual property.

# new cases over time
ggplot(covid_subset) +
  geom_point(mapping = aes(
    x = date,
    y = new_cases
  ))

# Notice this dataset has counts and a population, and no rate columns.
# Compute your own rates as in this morning.

covid_subset <- covid_subset |>
  mutate(
    new_cases_per_million = new_cases / population * 1e6,
    new_cases_smoothed_per_million = new_cases_smoothed / population * 1e6,
    new_deaths_per_million = new_deaths / population * 1e6
  )

ggplot(covid_subset) +
  geom_point(mapping = aes(
    x = date,
    y = new_cases_per_million
  ))

# Compare the two plots. The counts plot is dominated by the largest
# countries. The rate plot is a different claim.


## --------------------------------------------------------
## Aesthetics

## Mapping variables to aesthetics

# Aesthetics are visual properties of the plotted objects, onto which
# variables can be mapped. Above we mapped `date` and a rate onto the two
# position aesthetics, x and y.

# Other variables can be shown by mapping them onto colour, shape, size
# or transparency.

# map colour to country
ggplot(covid_subset) +
  geom_point(mapping = aes(
    x = date,
    y = new_cases_smoothed_per_million,
    color = country
  ))

# map size and transparency to a continuous variable
ggplot(covid_subset) +
  geom_point(mapping = aes(
    x = date,
    y = new_cases_smoothed_per_million,
    size = new_deaths,
    alpha = new_deaths
  ))


## Mapping versus setting

# *Mapping* an aesthetic to a variable happens inside `aes()`.
# *Setting* an aesthetic to a constant happens outside it.

# set colour to blue - outside aes()
ggplot(covid_subset) +
  geom_point(
    mapping = aes(
      x = date,
      y = new_cases_smoothed_per_million
    ),
    color = "blue"
  )

## Q1  |  TRY IT

# The code below is a common pitfall with ggplot2.
# Why is every point the same colour, and why is that colour
# not blue?

ggplot(covid_subset) +
  geom_point(mapping = aes(
    x = date,
    y = new_cases_smoothed_per_million,
    color = "blue"
  ))

# Try experimenting with other variables and other aesthetics.


## --------------------------------------------------------
## Geometric shapes

## Points

# A *geom* is the geometrical object used to represent the data.
# `geom_point()` uses points.

ggplot(covid_subset) +
  geom_point(mapping = aes(
    x = date,
    y = new_cases_smoothed_per_million,
    color = country
  ))

# Points have several aesthetics. This shows the available shapes:

ggplot(tibble(x = factor(0:25), y = 1)) +
  geom_point(
    mapping = aes(x = x, y = y),
    shape = 0:25,
    color = "black",
    fill = "grey",
    stroke = 1,
    size = 4
  )


## Lines

# For a value changing over time, a line is usually the right geom.

ggplot(covid_subset) +
  geom_line(mapping = aes(
    x = date,
    y = new_cases_smoothed_per_million,
    color = country
  ))

# `geom_path()` connects points in the order they appear in the data.
# `geom_line()` connects them in order of the x variable.

denmark <- covid_subset |> filter(country == "Denmark")

ggplot(denmark) +
  geom_path(mapping = aes(x = date, y = new_cases_smoothed_per_million))

ggplot(denmark) +
  geom_line(mapping = aes(x = date, y = new_cases_smoothed_per_million))

## Q2  |  TRY IT 
# These two look identical here. Construct a case where they differ.
# (Hint: what does `arrange()` do to the row order?)


## Bars and columns

# `geom_col()` draws bars whose height is a value in the data.
# `geom_bar()` counts rows for you instead.

winter <- covid_subset |>
  filter(date >= "2021-12-01", date <= "2022-02-28") |>
  group_by(country) |>
  summarise(
    deaths = sum(new_deaths, na.rm = TRUE),
    cases = sum(new_cases, na.rm = TRUE),
    population = first(population),
    .groups = "drop"
  ) |>
  mutate(
    deaths_per_million = deaths / population * 1e6,
    case_fatality = deaths / cases
  )

ggplot(winter) +
  geom_col(mapping = aes(x = deaths_per_million, y = country))


## Seeing what a summary hides

# In the morning we saw that days without a report are recorded as zero.
# A plot shows it instantly, and no summary statistic will.

ggplot(denmark |> filter(date >= "2022-06-01")) +
  geom_line(mapping = aes(x = date, y = new_cases))

# The comb of weekly spikes with zeros between them is the reporting
# change, not the epidemic. Plot a variable before you summarise it.


## --------------------------------------------------------
## Scales

# Scales control how values are translated into visual properties.
# ggplot2 picks a default depending on whether the variable is discrete
# or continuous; you can always override it.

# viridis is perceptually uniform and colour-blind safe, and built into
# ggplot2 - no extra package needed.

ggplot(covid_subset) +
  geom_point(mapping = aes(
    x = date,
    y = new_cases_smoothed_per_million,
    color = new_deaths_per_million
  )) +
  scale_color_viridis_c()

# Gradients, ColorBrewer palettes and manual colours are in the
# READING section at the end of this script, and on the cheat sheet.


## Limiting a scale versus zooming the view

# `limits =` REMOVES data outside the range before anything is drawn
ggplot(covid_subset) +
  geom_line(mapping = aes(
    x = date,
    y = new_cases_smoothed_per_million,
    color = country
  )) +
  scale_y_continuous(limits = c(0, 2000))

# `coord_cartesian()` zooms without removing anything
ggplot(covid_subset) +
  geom_line(mapping = aes(
    x = date,
    y = new_cases_smoothed_per_million,
    color = country
  )) +
  coord_cartesian(ylim = c(0, 2000))

## Q3  |  TRY IT. 
# Run both, then read the console.
# They are not the same. What is the visible difference, and which would
# you use to zoom in on a figure for publication?


## --------------------------------------------------------
## Ordering categories

# Categorical variables plot in alphabetical order by default.
# Alphabetical order is a choice, and it is almost never the useful one.

ggplot(winter) +
  geom_col(mapping = aes(x = deaths_per_million, y = country))

# `fct_reorder()` orders one variable by the values of another.

ggplot(winter) +
  geom_col(mapping = aes(
    x = deaths_per_million,
    y = fct_reorder(country, deaths_per_million)
  ))

# Nothing about the data changed. The second plot does the sorting for the
# reader instead of making them do it in their head.

# Reordering is not always right: a natural order - time, dose, severity -
# beats sorting by value. But leaving it alphabetical should be a decision,
# not an accident.


## --------------------------------------------------------
## Labels, titles and captions

# A figure with the right geometry can still be unreadable, or misleading.

# Same table, a different column: deaths per detected case. The ranking
# is not the one above - South Africa first, Denmark last - because the
# denominator is a different measurement (this morning's three claims).

# `labs()` sets every text element at once.

ggplot(winter) +
  geom_col(
    mapping = aes(
      x = case_fatality * 100,
      y = fct_reorder(country, case_fatality)
    ),
    fill = "steelblue"
  ) +
  labs(
    x = "Reported deaths per 100 reported cases (%)",
    y = NULL,
    title = "One infection in 75 was fatal in South Africa - one in 1,300 in Denmark",
    subtitle = "Case fatality ratio of reported cases, 1 Dec 2021 - 28 Feb 2022",
    caption = paste(
      "Our World in Data COVID-19 dataset, extract of 2026-07-19.",
      "Denominator: reported cases - which depends on how much a country tested.",
      "Days without a report counted as zero.",
      sep = "\n"
    )
  )

# The caption's denominator line is doing real work here: South Africa is
# not where an infection was most dangerous, it is where the fewest
# infections were detected per death. Every number on the figure is true.
# Keep this one in mind for the peer review.

# Four things worth checking on any figure you publish:
#
#   1. Axes    - what, and in what units.
#   2. Title   - state the finding, not the variable names.
#   3. Caption - source, extract date, and the denominator.
#   4. Excluded - the period you filtered to, the rows you dropped.
#


## --------------------------------------------------------
## Facets

# Facets split one plot into panels, one per group. Often clearer than
# eight overlapping lines.

ggplot(covid_subset) +
  geom_line(mapping = aes(x = date, y = new_cases_smoothed_per_million)) +
  facet_wrap(~country)

# `scales = "free_y"` lets each panel set its own y axis.
ggplot(covid_subset) +
  geom_line(mapping = aes(x = date, y = new_cases_smoothed_per_million)) +
  facet_wrap(~country, scales = "free_y")

## Q4 | TRY IT 
##
# The second plot lets every country use its own y axis. What does that
# make easy to see, and what does it make impossible to see?
# When would you use it?


## --------------------------------------------------------
## Saving a figure

# `ggsave()` writes the last plot, or a named one, to a file.
# ALWAYS set width, height and dpi. A screenshot of the plot pane is
# whatever size your window happened to be, and it will be unreadable
# on the Padlet board.

dir.create("figures", showWarnings = FALSE)

ggsave("figures/example.png", width = 7, height = 5, dpi = 150)


## --------------------------------------------------------
## Task 2 - Design your analysis figure
## --------------------------------------------------------

# Load the analysis table you saved this morning 

analysis_table <- read_csv("data/my_analysis_table.csv")

# Make ONE figure that answers the question your table was built for.
# Keep it simple. A single geom is fine.

# Before you open ggplot, write the comparison down in one sentence:
#
#   "This figure should make it easy to compare ______ across ______."
#

# Save it and post it:

ggsave("figures/<yourname>.png", width = 7, height = 5, dpi = 150)

# Post the figure to the Padlet board


## --------------------------------------------------------
## Peer review
## --------------------------------------------------------

# Comment on your neighbour's post against
# these questions:
#
#   1. Does it answer a stated question?
#   2. Is the figure easy to read and interpret?
#   3. Are units, denominators and axes labelled accordingly?
#   4. What does it hide?
#   5. What would you change to make it clearer?
#


## --------------------------------------------------------
## Optional extensions
## --------------------------------------------------------

## Extension 1
# Plot hospital patients against ICU patients, with aesthetic mappings
# that distinguish countries. Both axes span several orders of magnitude -
# decide whether to transform them, and be able to justify the choice.
# Which countries can appear on this plot at all, and why?

## Extension 2
# For one country, show daily new cases and the 7-day smoothed series on
# the same plot, in a way that makes clear which is which.
# What does the smoothed series hide? What does the raw series hide?

## Extension 3
# Build a figure showing, for each country: the distribution of daily case
# rates, a summary of that distribution, and how it changed over time.
# Polish it to publication standard and post it for discussion.


## --------------------------------------------------------
## READING - after the task
## --------------------------------------------------------

## Themes

# Themes control everything that is not data. `theme_minimal()` is a good
# default for slides and papers; we set it once at the top of a script and
# every later plot inherits it

# Customising a theme

p <- ggplot(covid_subset) +
  geom_line(mapping = aes(
    x = date, y = new_cases_smoothed_per_million, color = country
  )) +
  labs(x = NULL, y = "New cases per million (7-day mean)", color = "Country")

p + theme_bw()
p + theme_classic()
p + theme_minimal() +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )


## Several geoms in one plot  (each geom can take its own data)

# Each geom can take its own `data =` argument.

last_day <- covid_subset |>
  filter(!is.na(new_cases_smoothed_per_million)) |>
  group_by(country) |>
  slice_max(date, n = 1)

ggplot(covid_subset) +
  geom_line(mapping = aes(
    x = date,
    y = new_cases_smoothed_per_million,
    color = country
  )) +
  geom_point(
    mapping = aes(
      x = date,
      y = new_cases_smoothed_per_million,
      color = country
    ),
    size = 3,
    shape = 17,
    data = last_day
  )


## More colour scales

# a two-colour gradient
ggplot(covid_subset) +
  geom_point(mapping = aes(
    x = date, y = new_cases_smoothed_per_million, color = new_deaths_per_million
  )) +
  scale_color_gradient(low = "blue", high = "red")

# ColorBrewer, for discrete variables
ggplot(covid_subset) +
  geom_point(mapping = aes(
    x = date, y = new_cases_smoothed_per_million, color = country
  )) +
  scale_color_brewer(palette = "Set2")

# manual colours, one per level
colors <- c(
  "Denmark" = "steelblue", "India" = "tomato", "Israel" = "gold",
  "Japan" = "mediumseagreen", "South Africa" = "burlywood",
  "United States" = "grey30", "Brazil" = "orchid", "Nigeria" = "darkcyan"
)
ggplot(covid_subset) +
  geom_line(mapping = aes(
    x = date, y = new_cases_smoothed_per_million, color = country
  )) +
  scale_color_manual(values = colors)

# a logarithmic y axis
ggplot(covid_subset |> filter(new_cases_smoothed_per_million > 0)) +
  geom_line(mapping = aes(
    x = date, y = new_cases_smoothed_per_million, color = country
  )) +
  scale_y_log10()



## More facets

# `facet_grid()` arranges panels on a grid defined by rows ~ columns.
ggplot(covid_subset) +
  geom_line(mapping = aes(x = date, y = new_cases_smoothed_per_million)) +
  facet_grid(country ~ .)
