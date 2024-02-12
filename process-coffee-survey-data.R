# Data prep code for the coffee survey data
# The original CSV was read into Excel
# The field names were changed to be code_friendly
# Removed any column with no values
# Removed the true/false columns that can
# be created from the certain columns with
# more than one value separated by comma
# Author: Prof. Marck Vaisman


library(tidyverse)
library(readxl)
library(glue)
library(arrow)


data_output <- "data/analytical/"
if (!dir.exists(data_output)) dir.create(data_output)

# read in field mapping
field_mapping <- read_excel("data/coffee-survey-modified.xlsx", sheet = "original-headers")

# the data has the original field names (which are not r or python friendly) use the names
raw <- read_excel("data/coffee-survey-modified.xlsx", sheet = "data", skip = 1, col_names = field_mapping$friendly_name)


# two units of analysis
# 1) the respondent
# 2) the results by respondent by coffee

tasting_fields <-
    do.call(
        paste0,
        expand.grid(c("a_", "b_", "c_", "d_"), c("bitterness", "acidity", "preference", "notes"))
    )

tasting_subset_wide <- raw |>
    select(id, a_b_c_preferred, a_d_preferred, overall_favorite, all_of(tasting_fields)) |>
    mutate(
        across(contains(c("acidity", "bitterness", "preference")), ~ factor(.x, levels = 1:5)),
        across(contains(c("preferred", "favorite")), ~ factor(gsub("Coffee ", "", .x)))
    )

arrow::write_parquet(tasting_subset_wide, glue("{data_output}tasting_subset_wide.parquet"))


multi_value_group_prefixes <- c(
    "where_",
    "brew_",
    "purchase_",
    "add_",
    "dairy_",
    "sweetener_",
    "flavoring_",
    "why_"
)

(ordinal_vars_no_taste <-
    field_mapping |>
    filter(
        attribute_type == "ordinal",
        !(friendly_name %in% names(tasting_subset_wide)),
        create_factor == "y"
    ) |>
    pull(friendly_name))

(categorical_variables_no_taste <-
    field_mapping |>
    filter(
        attribute_type == "categorical", create_factor == "y",
        !(friendly_name %in% names(tasting_subset_wide))
    ) |>
    pull(friendly_name))

tasting_subset_long <-
    tasting_subset_wide |>
    select(id, contains(c("acidity", "bitterness", "preferemce"))) |>
    pivot_longer(-id) |>
    separate(name, into = c("coffee", "measurement"), sep = "_") |>
    mutate(coffee = toupper(coffee))

arrow::write_parquet(tasting_subset_long, glue("{data_output}tasting_subset_long.parquet"))

all_other_fields <-
    names(raw)[
        !names(raw) %in% c(
            names(tasting_subset_wide),
            grep(paste(multi_value_group_prefixes, collapse = "|"), names(raw), value = T),
            field_mapping |> filter(remove_from_demo == "y") |> pull(friendly_name)
        )
    ]

# get rest of data and convert to factors

# manually ordered ordinal factors using
(age_group_levels <- unique(raw$age_group)[c(6, 1, 2, 3, 8, 4, 7)])
(cups_per_day_levels <- unique(raw$cups_per_day)[c(2, 4, 3, 5, 7, 6)])
(preference_strength_levels <- unique(raw$preference_strength)[c(6, 2, 4, 3, 5)])
(preference_roast_levels <- unique(raw$preference_roast)[c(2, 3, 4, 5, 6, 7, 8)])
(preference_caffeine_levels <- unique(raw$preference_caffeine)[c(4, 3, 2)])
(monthly_spend_levels <- unique(raw$monthly_spend)[c(6, 4, 3, 5, 7, 2)])
(most_spent_per_cup_levels <- unique(raw$most_spent_per_cup)[c(9, 3, 2, 5, 6, 4, 8, 7)])
(most_willing_to_pay_levels <- unique(raw$most_willing_to_pay)[c(9, 8, 5, 6, 2, 7, 4, 3)])
(equipment_spent_levels <- unique(raw$equipment_spent)[c(8, 7, 3, 4, 5, 2, 6)])
(education_level_levels <- unique(raw$education_level)[c(4, 7, 5, 2, 3, 6)])
(number_of_children_levels <- unique(raw$number_of_children)[c(3, 6, 4, 5, 2)])


respondent_data <-
    raw |>
    select(id, all_of(all_other_fields)) |>
    mutate(across(all_of(categorical_variables_no_taste), ~ factor(.x))) |>
    mutate( # ideally replace all next lines with a function
        age_group = factor(age_group, levels = age_group_levels, ordered = T),
        cups_per_day = factor(cups_per_day, levels = cups_per_day_levels, ordered = T),
        preference_strength = factor(preference_strength, levels = preference_strength_levels, ordered = T),
        preference_roast = factor(preference_roast, levels = preference_roast_levels, ordered = T),
        preference_caffeine = factor(preference_caffeine, levels = preference_caffeine_levels, ordered = T),
        coffee_expertise = factor(coffee_expertise, levels = 1:10, ordered = T),
        monthly_spend = factor(monthly_spend, levels = monthly_spend_levels, ordered = T),
        most_spent_per_cup = factor(most_spent_per_cup, levels = most_spent_per_cup_levels, ordered = T),
        most_willing_to_pay = factor(most_willing_to_pay, levels = most_willing_to_pay_levels, ordered = T),
        equipment_spent = factor(equipment_spent, levels = equipment_spent_levels, ordered = T),
        education_level = factor(education_level, levels = education_level_levels, ordered = T),
        number_of_children = factor(number_of_children, levels = number_of_children_levels, ordered = T)
    )

skimr::skim(respondent_data)

write_parquet(respondent_data, glue("{data_output}respondent_data.parquet"))

# https://www.r-bloggers.com/2020/08/survey-categorical-variables-with-kableextra/
# https://stackoverflow.com/questions/45696738/tallying-multiple-choice-entries-in-a-single-column-in-a-r-dataframe-programmati
# https://medium.com/@raynamharris/bar-plots-as-venn-diagram-alternatives-d25888369c84
# https://upset.app/implementations/
# https://stackoverflow.com/questions/28873057/sum-across-multiple-columns-with-dplyr

# this uses quasiquotation
summarize_multi_entry <- function(raw, grp, data_output = data_output) {
    set_prep <-
        raw |>
        select(id, starts_with(!!grp)) |>
        select(!ends_with("_all")) |>
        select(!ends_with("_detail")) |>
        mutate(across(starts_with(!!grp), as.integer)) |>
        rename_with(~ str_replace(.x, pattern = grp, replacement = ""))

    # ideally reaplace with function
    # assign_and_save <- function(df, grp, path = "./data/analytical") {
    #    if !dir.exists(path) dir.create(path)
    #    nm <- glue::glue("{grp}")
    # }

    set_count <-
        set_prep |>
        rowwise() |>
        mutate(
            selection_ct = sum(across(!id), na.rm = T)
        ) |>
        ungroup()

    fname <- glue::glue("{grp}set_count")
    write_csv(set_count, glue("{data_output}{fname}.csv"), na = "")
    assign(x = fname, value = set_count, envir = .GlobalEnv)

    set_count_histogram <-
        set_count |>
        count(selection_ct) |>
        mutate(pct = n / sum(n)) |>
        ungroup()

    fname <- glue::glue("{grp}set_count_histogram")
    write_csv(set_count_histogram, glue("{data_output}{fname}.csv"), na = "")
    assign(x = fname, value = set_count_histogram, envir = .GlobalEnv)

    option_long <-
        set_count |>
        select(-selection_ct) |>
        pivot_longer(-c(id)) |>
        rename(option = name)

    fname <- glue::glue("{grp}option_long")
    write_csv(option_long, glue("{data_output}{fname}.csv"), na = "")
    assign(x = fname, value = option_long, envir = .GlobalEnv)

    option_count <-
        option_long |>
        count(option, value) |>
        ungroup()

    fname <- glue::glue("{grp}option_count")
    write_csv(option_count, glue("{data_output}{fname}.csv"), na = "")
    assign(x = fname, value = option_count, envir = .GlobalEnv)

    permutation_count <-
        set_count |>
        select(-c(id, selection_ct)) |>
        group_by(across(everything())) |>
        count() |>
        ungroup() |>
        mutate(pct = n / sum(n))

    fname <- glue::glue("{grp}permutation_count")
    write_csv(permutation_count, glue("{data_output}{fname}.csv"), na = "")
    assign(x = fname, value = permutation_count, envir = .GlobalEnv)
}

# debug(summarize_multi_entry)

# summarize_multi_entry(raw, "where_")

walk(
    multi_value_group_prefixes,
    \(x) summarize_multi_entry(raw, x, data_output)
)


all_multi_response <-
    raw |>
    select(id, starts_with(multi_value_group_prefixes)) |>
    select(!ends_with("_all")) |>
    select(!ends_with("_detail")) |>
    mutate(across(!id, ~ factor(.x)))

write_parquet(all_multi_response, glue("{data_output}all_multi_response.parquet"))
