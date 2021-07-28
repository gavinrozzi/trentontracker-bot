library(rtweet)
library(jsonlite)

# Read Twitter API credentials
readRenviron(".env")

# Retrieve current legislative data from TrentonTracker API
data <- fromJSON('https://api.trentontracker.com/bills')
categories <- fromJSON('https://api.trentontracker.com/bill-categories')

# Create a token for authenticating to Twitter
trentontracker_token <- create_token(
  app = "trentontracker",
  consumer_key =    Sys.getenv("TWITTER_CONSUMER_API_KEY"),
  consumer_secret = Sys.getenv("TWITTER_CONSUMER_API_SECRET"),
  access_token =    Sys.getenv("TWITTER_ACCESS_TOKEN"),
  access_secret =   Sys.getenv("TWITTER_ACCESS_TOKEN_SECRET")
)

# Get twitter mentions


if (Sys.getenv("last_mention") != "") {
  mentions <- get_mentions(token = trentontracker_token,since_id = )
  Sys.getenv("last_mention")
} else {
  mentions <- get_mentions(token = trentontracker_token)
}

# Loop over mentions
for (i in 1:nrow(mentions))

# Loop over recent Twitter mentions and break up text into works. Check each word to see if it's a bill name.
for (j in 1:length(strsplit(mentions$text[1]," ")[[1]])) {

  # normalize input of bill name so it's always capitalized
  result <- toupper(strsplit(mentions$text[1]," ")[[1]][j])

  # If a match is found in the database, grab that bill's data
  if (result %in% data$slug) {
  billdata <- data %>% dplyr::filter(slug == result)

  # Post a tweet with the bill's current status as a reply
  bill_status = paste("Bill",result, "Current Status:")
  post_tweet(status = "", token = trentontracker_token, in_reply_to_status_id = mentions$status_id[i])
  cat(paste("Replied to Tweet",mentions$status_id[i],"at",Sys.time()))

  }
}

billdata <- data %>% dplyr::filter(slug == "S2656")

# example of replying within a thread

## first post
post_tweet(status="first in a thread")

## post reply
post_tweet("second in the thread",
           in_reply_to_status_id = reply_id)


# Get the last ID of the mentions to only work with tweets newer than this one on the next run
last_mention <- tail(mentions,n=1)
id <- last_mention$status_id



