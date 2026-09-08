## --------------------------------------------------------
## Day 2, afternoon - Data visualization: solutions
## --------------------------------------------------------

library(tidyverse)

covid <- read_csv("data/covid_day2.csv")

countries <- c(
  "Denmark", "India", "Israel", "Japan",
  "South Africa", "United States", "Brazil", "Nigeria"
)

covid_subset <- covid |>
  filter(country %in% countries) |>
  mutate(
    new_cases_per_million = new_cases / population * 1e6,
    new_cases_smoothed_per_million = new_cases_smoothed / population * 1e6,
    new_deaths_per_million = new_deaths / population * 1e6
  )

denmark <- covid_subset |> filter(country == "Denmark")


## --------------------------------------------------------
## Q1
# Why is every point the same colour, and why is it not blue?

ggplot(covid_subset) +
  geom_point(mapping = aes(
    x = date,
    y = new_cases_smoothed_per_million,
    color = "blue"
  ))

# This is not a bug. ggplot2 is doing exactly what it was asked.
#
# Everything inside `aes()` is interpreted as a VARIABLE. The string
# "blue" is treated as a one-value variable - the same value on every
# row - which is then mapped to the colour scale. A discrete scale with
# one level gets the first colour of the default palette, which is a
# salmon red. The legend gives it away: it is titled `colour` and its
# single entry is labelled "blue".
#
# The fix is to move it outside `aes()`, where it sets a constant:

ggplot(covid_subset) +
  geom_point(
    mapping = aes(x = date, y = new_cases_smoothed_per_million),
    color = "blue"
  )

# THE RULE
#   inside  aes()  ->  map a VARIABLE to a channel
#   outside aes()  ->  set a CONSTANT
#
# If a legend appears that you did not want, you mapped something you
# meant to set.


## --------------------------------------------------------
## Q2
# Construct a case where geom_path() and geom_line() differ.

# `geom_line()` connects points in order of x.
# `geom_path()` connects them in the order the rows appear in the data.
# They agree only when the data is already sorted by x.

shuffled <- denmark |>
  filter(date >= "2021-06-01", date <= "2021-12-31") |>
  slice_sample(prop = 1) # same rows, random order

ggplot(shuffled) +
  geom_line(mapping = aes(x = date, y = new_cases_smoothed_per_million)) +
  labs(title = "geom_line(): sorted by x, looks correct")

ggplot(shuffled) +
  geom_path(mapping = aes(x = date, y = new_cases_smoothed_per_million)) +
  labs(title = "geom_path(): follows row order, scribble")

# `geom_path()` is not broken either - it is the right choice when row
# order IS the information: a trajectory through time in a space where
# neither axis is time. For example, cases against deaths, tracing how a
# country moved through the pandemic:

ggplot(denmark |> filter(!is.na(new_cases), !is.na(new_deaths))) +
  geom_path(mapping = aes(x = new_cases, y = new_deaths), alpha = 0.4) +
  labs(title = "A trajectory - here geom_path() is the correct geom")

# The lesson generalises: a geom encodes an assumption about your data.
# `geom_line()` assumes x is ordered and meaningful to interpolate along.


## --------------------------------------------------------
## Q3
# scale_y_continuous(limits = ) versus coord_cartesian(ylim = )

# limits: data outside the range is REMOVED before anything is drawn.
ggplot(covid_subset) +
  geom_line(mapping = aes(
    x = date, y = new_cases_smoothed_per_million, color = country
  )) +
  scale_y_continuous(limits = c(0, 2000)) +
  labs(title = "scale_y_continuous(limits): lines break")

# coord_cartesian: everything is drawn, then the view is zoomed.
ggplot(covid_subset) +
  geom_line(mapping = aes(
    x = date, y = new_cases_smoothed_per_million, color = country
  )) +
  coord_cartesian(ylim = c(0, 2000)) +
  labs(title = "coord_cartesian(ylim): lines continue off the top")

# THE VISIBLE DIFFERENCE
#   With `limits`, a line vanishes wherever it exceeds 2000 and reappears
#   when it comes back - and ggplot warns "Removed N rows containing
#   missing values". With `coord_cartesian()` the line runs off the top
#   edge, which is what a reader expects a zoom to look like.
#
# It matters more than it looks, because `limits` also removes those rows
# from any statistic the plot computes. A smoother, a boxplot or a mean
# drawn under `limits` is computed on the truncated data and will silently
# report the wrong value.
#
# FOR PUBLICATION: use `coord_cartesian()` to zoom.
# Use `limits` only when you actually intend to exclude data


## --------------------------------------------------------
## Q4
# facet_wrap(scales = "free_y") - what does it reveal and what does it hide?

ggplot(covid_subset) +
  geom_line(mapping = aes(x = date, y = new_cases_smoothed_per_million)) +
  facet_wrap(~country) +
  labs(title = "Shared y axis: magnitudes comparable, small countries flat")

ggplot(covid_subset) +
  geom_line(mapping = aes(x = date, y = new_cases_smoothed_per_million)) +
  facet_wrap(~country, scales = "free_y") +
  labs(title = "Free y axis: shapes comparable, magnitudes not")

# MAKES EASY: the SHAPE of each country's epidemic - when the waves came,
# how many there were, whether they were sharp or broad. On a shared axis
# Nigeria is a flat line at the bottom and you learn nothing about it.
#
# MAKES IMPOSSIBLE: any comparison of magnitude. Every panel is scaled to
# its own maximum, so Nigeria's peak and the United States' peak are drawn
# the same height while differing by orders of magnitude.
#
# USE IT when the question is about timing or shape within each group,
# and label it clearly - "note the differing y axes".
#


## --------------------------------------------------------
## Task 2 - one worked example
## --------------------------------------------------------

analysis_table <- covid |>
  filter(date >= "2021-12-01", date <= "2022-02-28") |>
  group_by(country) |>
  summarise(
    deaths = sum(new_deaths, na.rm = TRUE),
    population = first(population),
    days_with_report = sum(new_deaths > 0, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(deaths_per_million = deaths / population * 1e6)

# The comparison, stated first:
#   "This figure should make it easy to compare reported COVID-19 deaths
#    per million residents across countries, over one winter."

# TASK 2 - the first simple figure

p1 <- ggplot(analysis_table) +
  geom_col(mapping = aes(x = deaths_per_million, y = country))

p1


p2 <- analysis_table |>
  mutate(country = fct_reorder(country, deaths_per_million)) |>
  ggplot() +
  geom_col(
    mapping = aes(x = deaths_per_million, y = country),
    fill = "steelblue"
  ) +
  labs(
    x = "Reported deaths per million residents",
    y = NULL,
    title = "Reported winter mortality varied hundredfold",
    subtitle = "COVID-19 deaths, 1 Dec 2021 - 28 Feb 2022",
    caption = paste(
      "Our World in Data COVID-19 dataset.",
      "Denominator: national population.",
      "Reported deaths only; surveillance coverage differs by country."
    )
  ) +
  theme_minimal()

p2

# ggsave("figures/example.png", p2, width = 7, height = 5, dpi = 150)


## --------------------------------------------------------
## Extension 1 - hospital versus ICU patients
## --------------------------------------------------------

hosp <- covid |> filter(hosp_patients > 0, icu_patients > 0)

# Which countries can appear at all?
hosp |> count(country, sort = TRUE)

# Roughly half the dataset's countries are simply absent: they never
# reported ICU occupancy. Before drawing anything, notice that the plot
# is a picture of health-system reporting as much as of disease.

ggplot(hosp) +
  geom_point(
    mapping = aes(x = hosp_patients, y = icu_patients, color = country),
    size = 0.6, alpha = 0.4
  ) +
  scale_x_log10() +
  scale_y_log10() +
  labs(
    x = "Hospital patients (log scale)",
    y = "ICU patients (log scale)",
    title = "ICU occupancy tracks hospital occupancy, at country-specific ratios",
    caption = "Only countries that reported both. Log scales on both axes."
  ) +
  theme_minimal()

# The log transform is justified here: the values span four orders of
# magnitude, and on a linear scale every country except the largest
# collapses into the corner. Say so in the caption - a reader who misses
# a log axis misreads the whole figure.


## --------------------------------------------------------
## Extension 2 - raw versus smoothed
## --------------------------------------------------------

ggplot(denmark |> filter(date >= "2021-09-01", date <= "2022-06-01")) +
  geom_line(
    mapping = aes(x = date, y = new_cases),
    color = "grey70"
  ) +
  geom_line(
    mapping = aes(x = date, y = new_cases_smoothed),
    color = "steelblue", linewidth = 1
  ) +
  labs(
    x = NULL, y = "New cases",
    title = "Denmark: daily reports (grey) and 7-day mean (blue)",
    caption = "The weekly sawtooth in the raw series is reporting rhythm, not transmission."
  ) +
  theme_minimal()

# The raw series hides the trend inside a weekly sawtooth caused by
# reporting rhythm - fewer reports at weekends.
#
# The smoothed series hides that rhythm, which is exactly what you want
# when reading the trend, and exactly what you must NOT hide when the
# question is about data quality. It also hides genuine single-day spikes,
# and it hides the transition to weekly reporting by averaging the zeros
# into the neighbouring peaks.
#
# Neither is the honest one. The honest figure is the one whose caption
# says which you used.


## --------------------------------------------------------
## Extension 3 - distribution, summary, and change over time
## --------------------------------------------------------

# Three things in one figure: the distribution of daily case rates, a
# summary of it, and how it changed over time. One geometry does all
# three: a boxplot per year, per country. The box is the distribution,
# the median line is the summary, the x-axis is time.

# First decision: what is a "daily case rate" when reporting went weekly?
# From 2023 most countries report once a week: six days in seven are zero
# and the seventh carries a  whole week, so it is seven times too high.
# Neither is a daily rate. Stop at the end of 2022, and say so in the caption.
# Within 2020-2022, drop the remaining zero days too - they are mostly weekends without a report.

daily_rates <- covid_subset |>
  filter(date <= "2022-12-31", new_cases > 0) |>
  mutate(year = factor(year(date)))

# Check the claim before it goes in the title: which year holds each
# country's worst day?
daily_rates |>
  group_by(country) |>
  summarise(worst_year = year[which.max(new_cases_per_million)])

ggplot(daily_rates) +
  geom_boxplot(
    mapping = aes(x = year, y = new_cases_per_million),
    outlier.size = 0.4, outlier.alpha = 0.3
  ) +
  scale_y_log10() +
  facet_wrap(~country, ncol = 4) +
  labs(
    x = NULL,
    y = "New cases per million per day (log scale)",
    title = "The worst year was 2021 in India, Nigeria and South Africa - 2022 everywhere else",
    subtitle = "Distribution of daily reported case rates, days with a report only",
    caption = paste(
      "Our World in Data COVID-19 dataset, extract of 2026-07-19. Eight countries, 2020-2022;",
      "2023 onwards excluded because reporting went weekly. Days with zero reported cases excluded",
      "(no report, not no cases). Box = middle 50% of days; line = median; points = outliers.",
      sep = "\n"
    )
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(size = 7))

# The log scale earns its place: Nigeria's median day and Denmark's peak
# day differ by four orders of magnitude, and on a linear axis six of the
# eight panels would be flat lines. Same axis in every panel, so the
# countries can be compared - free_y would hide exactly the difference
# the title is about.
#
# What the figure hides: the within-year shape. A year is a coarse bin -
# Omicron in January 2022 and the quiet summer of 2022 sit in the same box.
# And the title is about peaks (the top outlier), not medians: by median
# day Brazil's and India's busiest year was 2021 too.
# Replace `year` with a quarter (floor_date(date, "quarter")) for a
# closer look, at the cost of readability. And the exclusion of zero days
# is a real decision: it removes reporting rhythm, but it also removes
# genuine zero-case days in early 2020, which raises those medians.

# A common alternative: a ridgeline or violin per year gives the shape of
# the distribution rather than five numbers. geom_violin() is a drop-in
# replacement for geom_boxplot() above
