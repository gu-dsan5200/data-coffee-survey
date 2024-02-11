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

# get id and tasting fields, convert to text
# make it long and split the keys
# then add the overall preference from the a_b_c_preference and a_d_preference columns
# tasting_results <-
tasting_subset_wide <- raw |>
    select(id, a_b_c_preference, a_d_preference, all_of(tasting_fields))
    
tasting_subset_wide |>
    select(-id) |>
    group_by(across(everything())) |>
    count()


    |>
    mutate(
        across(
            everything(), as.character
        )
    ) |>
    pivot_longer(-id) |>
    separate(name, into = c("coffee", "measurement"), sep = "_")


all_other_fields <- names(raw)[!names(raw) %in% c(tasting_fields, multi_value_group_prefixes, )]

resp_data <-
    raw |>
    select(all_of(all_other_fields))


skimr::skim(resp_data)


# https://www.r-bloggers.com/2020/08/survey-categorical-variables-with-kableextra/
# https://stackoverflow.com/questions/45696738/tallying-multiple-choice-entries-in-a-single-column-in-a-r-dataframe-programmati
# https://medium.com/@raynamharris/bar-plots-as-venn-diagram-alternatives-d25888369c84
# https://upset.app/implementations/
# https://stackoverflow.com/questions/28873057/sum-across-multiple-columns-with-dplyr

# this uses quasiquotation
summarize_multi_entry <- function(raw, grp) {
    set_prep <-
        raw |>
        select(id, starts_with(!!grp)) |>
        select(!ends_with("_all")) |>
        select(!ends_with("_detail")) |>
        mutate(across(starts_with(!!grp), as.integer),
               across(starts_with(!!grp), replace_na, 0)) 
    

    set_count <-
        set_prep |>
        rowwise() |>
        mutate(
            selection_ct = sum(across(starts_with(!!grp)), na.rm = T)
        ) |>
        ungroup()

    assign(x = glue::glue("{grp}set_count"), value = set_count, envir = .GlobalEnv)

    set_count_histogram <- 
        set_count |>
        count(selection_ct) |>
        mutate(pct = n / sum(n))

    assign(x = glue::glue("{grp}set_count_histogram"), value = set_count_histogram, envir = .GlobalEnv)

    option_count <-
        set_count |>
        select(-selection_ct) |>
        pivot_longer(-id) |>
        mutate(option = gsub(grp, "", name)) |>
        count(option, value)

    assign(x = glue::glue("{grp}option_count"), value = option_count, envir = .GlobalEnv)

    permutation_count <-
        set_count |>
        group_by(across(starts_with(!!grp))) |>
        count()

    assign(x = glue::glue("{grp}permutation_count"), value = permutation_count, envir = .GlobalEnv)
}

summarize_multi_entry(raw, "where_")

for (p in multi_value_group_prefixes) {
    summarize_multi_entry(raw, p)
}
ls()



debug(aggregate_multi_selection)

where_agg <- aggregate_multi_selection(raw, "where_") 
where_agg_ct <- 
    where_agg |>
    summarize_multi_selection()

where_agg_tally <-
    where_agg |> 
    tally_individual_values(grp = "where_")

# where_agg_permutations <-
where_agg |>
    group_by(across(starts_with("where_"))) |>
    count()

where_agg |> 
group_by(across(starts_with("where_"))


count(starts_with("where_"))

|>
    summarize_multi_selection()
