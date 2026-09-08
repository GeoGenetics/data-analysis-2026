## --------------------------------------------------------
## Day 2, morning - Data wrangling: solutions
##
## --------------------------------------------------------

library(tidyverse)

covid <- read_csv("data/covid_day2.csv")
country_lookup <- read_csv("data/country_lookup.csv")


## --------------------------------------------------------
## Q1
# What was the most recent day on which some country recorded 0 new cases?
# How many such days are there?

covid |>
  filter(new_cases == 0) |>
  arrange(desc(date)) |>
  select(country, date, total_cases, new_cases, new_cases_smoothed)

# The most recent is the last day in the dataset, 2026-07-19 - and it is not
# one country, it is most of them. That is already a strange answer to a
# question about an epidemic.

sum(covid$new_cases == 0, na.rm = TRUE)
nrow(covid)

# 39,008 of 76,544 rows. Over half the dataset is a zero.

# Look along the rows above, at `new_cases` and `new_cases_smoothed`
# together. On 2026-07-19: Brazil reports 0 new cases and a 7-day mean of
# 52.9. Greece 0 and 15. Denmark 0 and 1.
#
# A seven-day mean cannot be positive if all seven days were truly zero.
# Those zeros are not measurements of zero cases.

covid |>
  filter(new_cases == 0, new_cases_smoothed > 0) |>
  nrow()

# 23,799 - that is 61% of every zero in the dataset, across all 32 countries.

covid |>
  filter(new_cases == 0, new_cases_smoothed == 0) |>
  nrow()

# The other 15,050 have a zero smoothed value too. Those are countries that
# stopped reporting altogether, so the whole neighbourhood is zero. A
# different failure, and still not "no cases".


## When did each country last report anything at all?

covid |>
  filter(new_cases > 0) |>
  group_by(country) |>
  summarise(last_real_report = max(date), .groups = "drop") |>
  arrange(last_real_report) |>
  print(n = Inf)

# Two clear groups. Egypt stopped in April 2023, Japan and the United States
# in May 2023, France and Germany that summer. A second group runs to the
# end of the extract.
#
# And look closely at that second group: Denmark, Greece, Norway, Poland,
# Portugal, Romania and the United Kingdom all share a last non-zero date of
# 2026-07-13. Seven countries, one date. That is a weekly reporting day, not
# an epidemiological event.

covid |>
  filter(new_cases > 0, date > max(covid$date) - 30) |>
  distinct(country) |>
  nrow()

# 12 of 32 countries filed anything non-zero in the final month.


## THE TAKE-HOME
#
# 1. A zero in a count column is not necessarily a measurement. Here it is
#    usually the absence of one.
#
# 2. You can establish that without leaving the table. Cross-check a column
#    against another that ought to agree with it. The contradiction is the
#    evidence, and it costs one line of code.
#
# 3. `is.na()` finds none of this. Not one of those 39,008 rows is missing
#    in the sense R understands.
#
# The question asked when cases last hit zero. The answer is that
# this column cannot tell you


## --------------------------------------------------------
## Q2
# Top five countries by cases per million, and by total cases,
# on 2022-01-01. Do the lists overlap?

jan22 <- covid |>
  filter(date == "2022-01-01") |>
  mutate(cases_per_million = total_cases / population * 1e6)

jan22 |>
  slice_max(cases_per_million, n = 5) |>
  select(country, cases_per_million)

#   United Kingdom  200,622
#   United States   158,458
#   Israel          152,412
#   Denmark         135,933
#   France          131,416

jan22 |>
  slice_max(total_cases, n = 5) |>
  select(country, total_cases)

#   United States   54,118,933
#   India           34,861,579
#   Brazil          22,277,239
#   United Kingdom  13,678,283
#   Turkey           9,482,550

# Only the United Kingdom and the United States appear on both.
#
# India is second in the world by count and nowhere near the top by rate.
# Denmark is fourth by rate and does not make the count list at all.
# Both lists are correct, but answer different questions


## --------------------------------------------------------
## Q3
# Mean new cases per million per day, per country, sorted descending.

covid |>
  group_by(country) |>
  summarise(
    mean_per_million = mean(new_cases / population * 1e6, na.rm = TRUE),
    days_in_mean = sum(!is.na(new_cases)),
    days_with_report = sum(new_cases > 0, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(mean_per_million))

#                   mean   days_in_mean   days_with_report
#   France          461.5      1,275            167
#   Germany         356.3      1,283            181
#   South Korea     279.5      2,389          1,235
#   United States   245.6      1,233          1,017
#   Denmark         244.9      2,389          1,360

# Two different counts, and both matter.
#
# `days_in_mean` is the number of non-NA days - the denominator of the
# mean. France stopped reporting in 2023, so its mean is taken over its
# epidemic years; South Korea reported to the end, so its mean includes
# hundreds of quiet days that pull the average down. The countries are
# not being compared on the same period, and nothing in the output says so.
#
# `days_with_report` is the number of days with a positive value. France
# has 167 of 1,275: it reported weekly from the start, and the other days
# are zeros - no report, not no cases (Q1). The mean survives that, because
# the zeros are in the denominator; a median would not, and neither would
# anything computed per reporting day.
#
# Any grouped summary should carry a count like this next to the number.
# A fairer version also fixes the window for everyone:

covid |>
  filter(date >= "2020-03-01", date <= "2021-12-31") |>
  group_by(country) |>
  summarise(
    mean_per_million = mean(new_cases / population * 1e6, na.rm = TRUE),
    days_in_mean = sum(!is.na(new_cases)),
    days_with_report = sum(new_cases > 0, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(mean_per_million))


## --------------------------------------------------------
## Q4  (stretch)

# Denmark: days where new deaths per million exceeds 1, sorted descending.
# In which month do the worst days fall? Do you believe it?

covid |>
  filter(country == "Denmark") |>
  mutate(deaths_per_million = new_deaths / population * 1e6) |>
  filter(deaths_per_million > 1) |>
  arrange(desc(deaths_per_million)) |>
  select(date, new_deaths, deaths_per_million)

# The worst individual days are 2023-12-11, 2023-12-18, 2023-12-04 -
# 120, 100 and 98 deaths "in a day".
#
# You should not believe it, and by now you know why. By December 2023
# Denmark reported weekly, so each of those figures is seven days of deaths
# stamped on one date, with six zeros around it. Same defect as Q1


## First attempt at a fix 
# A natural repair: stop ranking days, count them. How many days per month
# exceeded 1 per million?

covid |>
  filter(country == "Denmark") |>
  mutate(deaths_per_million = new_deaths / population * 1e6) |>
  filter(deaths_per_million > 1) |>
  mutate(month = floor_date(date, "month")) |>
  count(month, sort = TRUE)

# January 2021 (31 days), December 2020 (30), December 2021 (29) ... and
# March 2022 down in eighth place with 28. December 2023 nowhere.
#
# This looks sensible and it is a second artefact, pointing the other way:
#
#   - A weekly-reported month has at most four or five non-zero days, so
#     it can never rank, however bad it was. December 2023 is structurally
#     invisible to this method.
#   - Counting days above a threshold throws away magnitude. A day at
#     2 per million and a day at 10 per million both score one.
#
# Two methods, two distortions, each hiding something different.


## The robust version: aggregate coarser than the reporting cadence

# If deaths are stamped daily in one period and weekly in another, sum
# them over a unit that is longer than either. A monthly total does not
# care whether it was built from thirty daily reports or four weekly ones.

covid |>
  filter(country == "Denmark") |>
  mutate(month = floor_date(date, "month")) |>
  group_by(month) |>
  summarise(
    deaths = sum(new_deaths, na.rm = TRUE),
    deaths_per_million = deaths / first(population) * 1e6,
    days_with_report = sum(new_deaths > 0, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(deaths_per_million))

#   2022-03   1,084 deaths   183.6 per million   29 reporting days
#   2021-01     850          144.0                31
#   2022-02     846          143.3                28
#   2022-01     482           81.7                31
#   2022-04     481           81.5                29
#   2020-12     421           71.3                31
#   2023-12     393           66.6                 4   <- weekly, and real
#   2021-12     373           63.2                31
#
# March 2022 is the deadliest month in the whole series. The day-count
# method had it eighth. And December 2023 - which the day-ranking inflated
# and the day-count erased - was a genuinely bad month, seventh overall,
# worse than December 2021, on four reports.
#
# Note `days_with_report` sitting next to the number. It is what tells the
# reader that 2023-12 was built from four values and 2021-01 from
# thirty-one, so they can decide how much to trust each.


## THE TAKE-HOME
#
# A reporting-cadence artefact is not fixed by a threshold, and it is not
# fixed by counting. It is fixed by aggregating to a unit coarser than the
# reporting frequency.  
#
# The general form: whenever you suspect the granularity of the data
# changed partway through, summarise at a granularity it never fell below.


## --------------------------------------------------------
## Task 1 - one possible answer
## --------------------------------------------------------

# There is no single right answer. This one computes total deaths
# over the winter, divided by the population, with the reporting coverage
# carried alongside so the reader can judge it.

analysis_table <- covid |>
  filter(date >= "2021-12-01", date <= "2022-02-28") |>
  group_by(country) |>
  summarise(
    deaths = sum(new_deaths, na.rm = TRUE),
    cases = sum(new_cases, na.rm = TRUE),
    population = first(population),
    days_with_report = sum(new_deaths > 0, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    deaths_per_million = deaths / population * 1e6,
    case_fatality = deaths / cases
  ) |>
  arrange(desc(deaths_per_million))

# `days_with_report` counts days with a positive value, not days with a
# number - every country has 90 of those, because a day without a report
# is a zero here, not an NA. Greece tops the table on 13 reporting days:
# its winter total is credible (weekly totals survive weekly reporting),
# its daily series is not.

analysis_table

write_csv(analysis_table, "data/my_analysis_table.csv")

# The comparison it supports, in one sentence:
#   "Reported COVID-19 deaths per million residents, by country,
#    1 December 2021 to 28 February 2022."
#
# Note what it does NOT support: a claim about how many people died.
# These are reported deaths, and reporting quality differs between these
# countries - `days_with_report` is the first hint of how much.
