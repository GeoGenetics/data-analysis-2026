## --------------------------------------------------------
## Day 2, morning - Data wrangling
##
## Fundamentals in Computational Analysis of Large-Scale Datasets 2026
## --------------------------------------------------------

# In this tutorial we explore data wrangling: getting data into R and
# transforming it so it can answer a question.

# The workhorse is dplyr (https://dplyr.tidyverse.org/),
# part of the tidyverse (https://www.tidyverse.org/).

# We will cover

# * What one row represents
# * Chaining operations with the pipe `|>`
# * Selecting variables with `select()`
# * Arranging observations with `arrange()`
# * Filtering observations with `filter()`
# * Creating new variables with `mutate()`, and choosing a denominator
# * Grouping and summarising with `group_by()` and `summarise()`


# HOW THE QUESTIONS WORK
#
# Every `## Q` below is labelled with what to do when you reach it:
##
#   TRY IT         Two or three minutes, then compare.


## --------------------------------------------------------
## libraries

library(tidyverse)


## --------------------------------------------------------
## dataset

# Open `data-analysis-2026.Rproj` before running this script. RStudio then
# sets the working directory to the repo root, and the relative path below
# works on every machine, on macOS and on Windows alike.

# If `read_csv()` below fails with "does not exist", you almost certainly
# opened the script instead of the project. Close RStudio and open the
# .Rproj file.

covid <- read_csv("data/covid_day2.csv")

# A snapshot of the Our World in Data COVID-19 dataset:
# https://catalog.ourworldindata.org/garden/covid/latest/compact/compact.csv
# trimmed to 32 countries and 14 variables. See data/README.md for the
# data dictionary, and scripts/make_extracts.R for exactly how it was cut.

covid


## --------------------------------------------------------
## Examine your data

# Three things to establish about any table before transforming it.

# 1. How big is it?

# PREDICT before you run: 32 countries, every day from 1 January 2020 to
# 19 July 2026. Roughly how many rows is that? Say a number.
dim(covid)
nrow(covid)
ncol(covid)

# 2. What is in it?
glimpse(covid)
summary(covid)

# 3. **What does one row represent?**

# This is the question everything else depends on, and it is not answered
# by looking at the column names. Look at actual rows.

covid |>
  filter(country == "Denmark", date >= "2020-03-01") |>
  head(3)
covid |>
  filter(country == "India", date >= "2020-03-01") |>
  head(3)

# One row is one country on one day.

# So a mean taken over rows is a mean over country-days, not over countries.
# India and Denmark contribute one row each per day, which means a country of
# 1.4 billion people is weighted exactly like a country of 5.9 million.

# PREDICT: will every country have the same number of rows? Why might not?
covid |> count(country)


## --------------------------------------------------------
## The pipe

# The pipe `|>` chains operations together, so code
# reads as a sequence of actions rather than a nest of function calls.

# Compare. Without the pipe:

select(
  arrange(
    filter(covid, country == "Sweden"),
    desc(new_cases)
  ),
  country, date, new_cases
)

# With the pipe:

covid |>
  filter(country == "Sweden") |>
  arrange(desc(new_cases)) |>
  select(country, date, new_cases)

# The second version says what happens, in the order it happens.
# Read `|>` as "and then".


## --------------------------------------------------------
## Select variables

# `select()` picks columns.

# by variable name
select(covid, country)
select(covid, country, date, new_cases)

# by column index
select(covid, 1, 4)

# a range of consecutive columns with `:`
select(covid, total_cases:new_deaths)

# drop a column with `-`
select(covid, -stringency_index)


## Helper functions

# pattern matching on names
select(covid, starts_with("new"))
select(covid, contains("case"))
select(covid, ends_with("patients"))

# useful ranges
select(covid, everything())
select(covid, country, date, everything()) # move two columns to the front


## --------------------------------------------------------
## Arrange observations

# `arrange()` sorts rows, ascending by default. `desc()` reverses it.
# Multiple variables sort in sequence.

arrange(covid, new_cases)
arrange(covid, desc(new_cases))
arrange(covid, country, desc(date))

## Q1 | TRY IT.

# What was the most recent day in the dataset on which some country
# recorded 0 new cases?
#
# Then look at how many such days there are. Does "0 new cases" mean
# what you first assumed it meant?


## --------------------------------------------------------
## Filter observations

## Basic filters

# `filter()` keeps rows matching a condition. Use `==`, `!=`, `<`, `>`, `%in%`.

filter(covid, country == "Denmark")
filter(covid, new_cases > 100000)
filter(covid, date == "2022-01-01")
filter(covid, country %in% c("Denmark", "Sweden", "Norway"))

## YOUR TURN
# Filter for a country you care about, on a date you remember.
# Then filter for two countries at once. Which operator did you need?

# Multiple arguments are combined with logical AND.
# Use `|` for OR.

filter(covid, country == "Denmark", date == "2022-01-01")
filter(covid, country == "Denmark" | country == "Sweden")


## Useful helper functions  -  REFERENCE, we will not walk these

# `slice()`      picks rows by position
# `distinct()`   finds unique combinations of values
# `slice_min()` / `slice_max()` return the N lowest / highest rows

slice(covid, 10)
slice(covid, 1:5)

distinct(covid, country)
distinct(covid, country, population)

# PREDICT: which country will fill the top ten? All the same one, or a mix?
slice_max(covid, new_cases, n = 10)
slice_min(covid, date, n = 5)


## --------------------------------------------------------
## Create variables

# `mutate()` adds new columns, computed from existing ones.

# We work with a smaller table for this section.

covid_small <- covid |>
  select(country, date, total_cases, total_deaths, population) |>
  filter(date == "2022-01-01")

covid_small

# A new variable as a function of existing ones:

mutate(covid_small, cases_per_million = total_cases / population * 1e6)

# Variables created in one `mutate()` call can be used later in the same call:

mutate(covid_small,
  cases_per_million = total_cases / population * 1e6,
  cases_per_hundred = cases_per_million / 1e4
)


## Denominators

# Notice that this dataset gives you counts and a population, and nothing
# else. Every rate you want, you have to build - and building it means
# choosing a denominator.

# The same numerator with three different denominators answers three
# different questions:

covid |>
  filter(country == "Denmark", date == "2022-01-01") |>
  mutate(
    deaths_per_million = total_deaths / population * 1e6, # how much of the population died
    case_fatality = total_deaths / total_cases, # how deadly a detected case was
    detected_per_test = new_cases / new_tests # how hard we were looking
  ) |>
  select(country, date, deaths_per_million, case_fatality, detected_per_test)

# None of these is "the" mortality.

## Q2  |  TRY IT
# Which five countries had the highest number of *cases per million people*
# on 2022-01-01? And which five had the highest *total cases* on that day?
#
# Do the two lists share any countries at all?


## --------------------------------------------------------
## Group and summarise

# Many analysis tasks follow a split-apply-combine strategy:
#   split the data into groups,
#   apply a summary to each group,
#   combine the results into one table.

# In dplyr that is `group_by()` and `summarise()`.

# ungrouped: one number for the whole table
covid |>
  summarise(max_new_cases = max(new_cases, na.rm = TRUE))

# grouped: one number per country
covid |>
  group_by(country) |>
  summarise(max_new_cases = max(new_cases, na.rm = TRUE))

# several summaries at once
covid |>
  group_by(country) |>
  summarise(
    first_day = min(date),
    last_day = max(date),
    total_cases = sum(new_cases, na.rm = TRUE),
    days_without_data = sum(is.na(new_cases))
  )

# `count()` is a shorthand for the common case of counting rows per group
covid |> count(country)

# Grouping by more than one variable
covid |>
  mutate(year = year(date)) |>
  group_by(country, year) |>
  summarise(cases = sum(new_cases, na.rm = TRUE), .groups = "drop")

# Note `.groups = "drop"`: without it the result stays grouped by `country`,
# which quietly changes what the *next* verb in your pipeline does.


## Repeated fixed values in rows

# `population` is repeated on every row of a country. So inside a grouped
# `summarise()`, `sum(population)` adds it up once per day.

covid |>
  filter(date >= "2021-12-01", date <= "2022-02-28") |>
  group_by(country) |>
  summarise(
    deaths = sum(new_deaths, na.rm = TRUE),
    pop_right = first(population),
    pop_wrong = sum(population)
  )

# `first()` (or `mean()`, or `max()`) gives the population.
# `sum()` gives the population times the number of days.

## Q3  |  TRY IT 
##
# For each country, compute the mean number of new cases per million people
# per day, over the whole period. Sort descending.
#
# Which country comes top? On how many days did that country actually
# report a number? Are you comfortable with the comparison?


## --------------------------------------------------------
## Task 1 - build the analysis table
## --------------------------------------------------------

# QUESTION
#   Which of the countries in this dataset had the worst winter of
#   2021-22, and by what measure?


# OUTPUT
#   One table, one row per country, one rate you chose
#   Save it - the afternoon session starts from this table.

# Starter code:

analysis_table <- covid |>
  filter(date >= "2021-12-01", date <= "2022-02-28")

# ... your pipeline here ...

# When you are happy with it, write it out:

# write_csv(analysis_table, "data/my_analysis_table.csv")

# HINT (only if you are stuck)
#   group_by(country), then summarise() the numerator you care about with
#   sum(..., na.rm = TRUE), and take first(population) as the denominator.

# Post your table and a one-sentence statement of the comparison it
# supports to the Padlet board. 
# Then discuss your choice of denominator with your neighbour


## --------------------------------------------------------
## Checkpoint 
## --------------------------------------------------------

# Before lunch, make sure you have:
#
#   1. an analysis table saved to disk
#   2. one sentence stating the comparison it supports
#   3. both posted to the Padlet board
#
# The afternoon builds a figure from this table.


## --------------------------------------------------------
## Finished early?  Stretch goals
## --------------------------------------------------------

## Q4  |  STRETCH  -  Denmark's worst month
##
# Using the pipe, for Denmark only:
# - compute new deaths per million people
# - keep only days where that exceeds 1
# - sort by descending value
#
# In which month do the worst days fall? Do you believe it?
#
# Then find a way of ranking Denmark's months that does not depend on how
# often Denmark happened to be reporting. Which month is worst now?


## ========================================================
## READING - after the task
## ========================================================
##
## The code for the missing data block 

## --------------------------------------------------------
## Missing data

# Real data is full of missing data, and they are not all the same kind.

## Kind one: NA

# How much is missing, per column?

covid |>
  summarise(across(everything(), ~ sum(is.na(.x)))) |>
  pivot_longer(everything(), names_to = "column", values_to = "n_missing") |>
  arrange(desc(n_missing))

# Most functions return NA if any input is NA. `na.rm = TRUE` skips them.

# PREDICT: what does the first line return?
mean(covid$new_cases)
mean(covid$new_cases, na.rm = TRUE)


## Kind two: a variable a country never collected

# Which countries reported ICU occupancy at all?
covid |>
  group_by(country) |>
  summarise(
    icu_days = sum(!is.na(icu_patients)),
    days = n()
  ) |>
  arrange(icu_days) |>
  print(n = Inf)

# Several countries have zero. For them ICU occupancy is not missing data,
# it is an absent variable, and no amount of cleaning will produce it.


## Kind three: missing disguised as zero

# Denmark reported daily until the end of 2022, then weekly. Days without a
# report are recorded as 0, not NA.

covid |>
  filter(country == "Denmark") |>
  mutate(year = year(date)) |>
  group_by(year) |>
  summarise(
    days = n(),
    n_missing = sum(is.na(new_cases)),
    n_zero = sum(new_cases == 0, na.rm = TRUE)
  )

# `filter(!is.na(new_cases))` keeps every one of those zeros. The only way
# to see this is to plot the variable over time - which you will do after
# lunch. For now, note the shape of the problem.


## `drop_na()` is not a cleaning step 

# `drop_na()` with no arguments drops every row with a missing value
# in *any* column.

# PREDICT before you run: how many of the 76,544 rows survive? 
nrow(covid)
nrow(drop_na(covid))

# Compare the answers:

mean(covid$new_cases, na.rm = TRUE)
mean(drop_na(covid)$new_cases)

# And look at who is left:

drop_na(covid) |> distinct(country)

# The countries that survive are the ones with well-funded reporting
# systems. `drop_na()` did not remove missing data - it removed countries,
# and it removed most of the world's population along with them.

# Name the columns you actually need:

covid |>
  drop_na(new_cases, new_deaths, population) |>
  nrow()


## --------------------------------------------------------
## Combining tables 

# Static facts about each country live in a separate lookup table:
# one row per country.

country_lookup <- read_csv("data/country_lookup.csv")
country_lookup

# `left_join()` keeps every row of the left table and adds matching
# columns from the right one, matched on a key column.

covid_annual <- covid |>
  mutate(year = year(date)) |>
  group_by(country, year) |>
  summarise(
    cases = sum(new_cases, na.rm = TRUE),
    population = first(population),
    .groups = "drop"
  )

covid_annual |>
  left_join(country_lookup, by = "country")

# ALWAYS check the row count before and after a join:

nrow(covid_annual)
nrow(left_join(covid_annual, country_lookup, by = "country"))

# If the number grew, the right-hand table has duplicate keys and the join
# has silently invented rows. This is the single most common way a join
# ruins an analysis without producing any error at all.
