# Datasets

All data here is a **local, versioned snapshot**. Nothing is downloaded during
teaching. To refresh it, see `scripts/make_extracts.R`.

## Source

Our World in Data COVID-19 dataset, cut from
`https://catalog.ourworldindata.org/garden/covid/latest/compact/compact.csv`.

Note that the older distribution route is dead: the `owid/covid-19-data` GitHub
repository was archived on 24 March 2026 and its data stops at 19 August 2024.

Extract taken September 2026, covering 2020-01-01 to 2026-07-19.

## `covid_day2.csv`

32 countries, 76,544 rows, 14 columns. **One row is one country on one day.**

| Column | Meaning |
|---|---|
| `country` | Country name |
| `date` | Calendar date |
| `total_cases` | Cumulative confirmed cases |
| `new_cases` | Confirmed cases reported that day |
| `new_cases_smoothed` | 7-day rolling mean of `new_cases` |
| `total_deaths` | Cumulative confirmed deaths |
| `new_deaths` | Confirmed deaths reported that day |
| `icu_patients` | Patients in intensive care that day |
| `hosp_patients` | Patients in hospital that day |
| `new_tests` | Tests performed that day |
| `positive_rate` | Share of tests returning positive (7-day mean) |
| `people_vaccinated` | Cumulative people with at least one dose |
| `stringency_index` | Government response stringency, 0-100 |
| `population` | National population (constant per country) |

### Two things to know before you use it

**There are no rate columns.** The source publishes `*_per_million` and
`*_per_hundred` variants; they are deliberately not included here. Compute the
rate you need from `population`, and be explicit about the denominator you chose.

**The missingness is not noise, it is structure.** `icu_patients`,
`hosp_patients`, `new_tests` and `positive_rate` are kept precisely *because*
they are badly missing:

- roughly fourteen of the 32 countries never reported ICU occupancy at all;
- several countries reported for a period and then stopped;
- from 2023 most countries switched to weekly reporting, and days without a
  report are recorded as **`0`, not `NA`** — over half the rows in the file are
  zeros, and `filter(!is.na(...))` will not find any of them.

A bare `drop_na()` on this table keeps under a tenth of the rows and deletes
eighteen countries, including India, Brazil, Nigeria and Germany. Name the
columns you need instead.

## `country_lookup.csv`

One row per country: static attributes, for joining onto the analysis table.

`country`, `code`, `continent`, `population`, `population_density`,
`median_age`, `gdp_per_capita`, `life_expectancy`, `hospital_beds_per_thousand`,
`human_development_index`, `diabetes_prevalence`, `extreme_poverty`.

Because there is exactly one row per country, a `left_join()` on `country`
cannot duplicate rows. Check `nrow()` before and after anyway.
