# The Great American Coffee Taste Test

https://cometeer.com/pages/the-great-american-coffee-taste-test
https://rmckeon.medium.com/great-american-coffee-taste-test-breakdown-7f3fdcc3c41d

Data file: https://bit.ly/gacttCSV+

This is being used to illustrate the following:
- How to think of breaking down your data depending on the unit of analysis
- How to process the data for the purposes of visualization
- How to best visualize different aspects of the data (and units of analysis)
- Being survey data, no attempt is being made to do statistical analysis (i.e. is it a representative sample, statistical tests, etc.)
- Use advanced R programming and other metadata to perform all kinds of tasks
  
Data considerations

1. This data was volunteer data
2. Not everyone who did the tasting filled out every question (this helps define what to do with NA's. In this case, it's missing/unknown/not provided)
3. This is a sample of people who are fans of James Hoffmann and were able to participate in the tasting


## Data

The anonymized data file has 4,042 respondents (rows) and 113 fields with different kinds of information. 

- demographic
    - age
    - gender
    - education level
    - ethnicity and race
    - number of children
    - employment status
    - political affiliation

- coffee preferences and habits
    - single field
        - How many cups of coffee do you typically drink per day?
        - What is your favorite coffee drink?
        - Before today's tasting, which of the following best described what kind of coffee you like?
        - How strong do you like your coffee?
        - What roast level of coffee do you prefer?
        - How much caffeine do you like in your coffee?
        - How would you rate your own coffee expertise?
        - Do you like the taste of coffee?
        - Do you know where your coffee comes from?
        - What is the most you've ever paid for a cup of coffee?
        - What is the most you'd ever be willing to pay for a cup of coffee?
        - Do you feel like you’re getting good value for your money when you buy coffee at a cafe?
        - Approximately how much have you spent on coffee equipment in the past 5 years?
        - Do you feel like you’re getting good value for your money with regards to your coffee equipment?
    - Multi field information (where there are multiple options for each of these preferences )
        - Where do you typically drink coffee?
        - How do you brew coffee at home?
        - On the go, where do you typically purchase coffee?
        - Do you usually add anything to your coffee?
        - What kind of dairy do you add?
        - What kind of sugar or sweetener do you add?
        - Why do you drink coffee?
        - What kind of flavorings do you add?

- Tasting outcomes for each of the four tasted coffees (A, B, C, and D)
    - bitterness
    - acidity
    - personal preference
    - tasting notes
    - preference b/w a, b, c
    - preference b/w a, d
    - overall favorite


## Unit of analysis

There are many potential units of analysis:
    - by respondent
    - by coffee
    - by coffee-attribute
    - by aggregated clusters of preferences and habits

## Data prep

Data pre-processing:

- Original anonymized file was a CSV
- Converted to Excel (.xslx)
- Added separate tab with mapping of the original variable names (which are questions) to software friendly formatting using contextual field names. https://www2.stat.duke.edu/~rcs46/lectures_2015/01-markdown-git/slides/naming-slides/naming-slides.pdf
- Loaded CSV but used the new names as field names
- Tallied up multiple metrics for each of the multi-valued preferences
- Separated the tasting results from demographic data
- Coded certain variables as categorical or ordinal 
- Saved as parquet to keep data type


vis types:
upset plot (in lieu of venn)





Outcomes: each individual coffee rating
- features: all the demographic data




