library(rtweet)
library(jsonlite)
library(dplyr)
library(lubridate)

# Read Twitter API credentials- LOCAL MACHINE ONLY
# readRenviron(".env")

# Get last mention ID from the previous run
prev_mention_id <- readLines("last_mention.txt")

# Retrieve current legislative data from TrentonTracker API
data <- fromJSON("https://api.trentontracker.com/bills")
categories <- fromJSON("https://api.trentontracker.com/bill-categories")
status_date <- as.Date(fromJSON("https://api.trentontracker.com")$updated_at[1])

acronyms <- read.csv("acronyms.csv") %>%
  rename("bill_state" = FullText)

# Log to console
cat(paste("Legislative data retrieved.", "TrentonTracker data current as of", status_date, "\n"))

# Create a token for authenticating to Twitter
trentontracker_token <- create_token(
  app = "trentontracker",
  consumer_key = Sys.getenv("TWITTER_CONSUMER_API_KEY"),
  consumer_secret = Sys.getenv("TWITTER_CONSUMER_API_SECRET"),
  access_token = Sys.getenv("TWITTER_ACCESS_TOKEN"),
  access_secret = Sys.getenv("TWITTER_ACCESS_TOKEN_SECRET")
)

# Get twitter mentions
mentions <- get_mentions(token = trentontracker_token, since_id = prev_mention_id)

# Loop over mentions
for (i in 1:nrow(mentions)) {

  # Break up text of each mentions into words. Check each word to see if it's a bill name.
  for (j in 1:length(strsplit(mentions$text[i], " ")[[1]])) {

    # normalize input of bill name so it's always capitalized
    result <- toupper(strsplit(mentions$text[i], " ")[[1]][j])

    # If a match is found in the database, grab that bill's data
    if (result %in% data$slug) {
      billdata <- data %>%
        filter(slug == result) %>%
        left_join(acronyms, by = c("CurrentStatus" = "Acronym"))

      # Handle Bills in committee
      if (is.na(billdata$bill_state)) {
        bill_status <- paste(result, "-", billdata$Abstract, "\n", "Current Status:", "In Commitee", "\n", "Commitee:", billdata$FullText, "\n", "Last Action:", billdata$LDOA)
      } else {
        bill_status <- paste(result, "-", billdata$Abstract, "\n", "Current Status:", billdata$bill_state, "\n", "Commitee:", billdata$FullText, "\n", "Last Action:", billdata$LDOA)
      }
      # Post a tweet with the bill's current status as a reply
      post_tweet(status = bill_status, token = trentontracker_token, in_reply_to_status_id = mentions$status_id[i], auto_populate_reply_metadata = TRUE)
      cat(paste("Replied to Tweet", mentions$status_id[i], "at", Sys.time()))
    }
  }
}

# Save the last mention ID so the bot can resume later.
if(nrow(mentions) > 0) {

# Get the last ID of the mentions to only work with tweets newer than this one on the next run
last_mention_id <- mentions$status_id[i]

# Write out the ID to a text file
writeLines(last_mention_id, file("last_mention.txt"))
} else {
  cat("No new mentions to reply to.")
}
