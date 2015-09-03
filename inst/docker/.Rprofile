# Turn off caching of credentials in this docker image.
options("google_auth_cache_httr"=FALSE)
options("httr_oauth_cache"=FALSE)

# Use an out-of-band OAuth flow since the redirect will not work in this dockerized environment.
options(httr_oob_default = TRUE)

# Place the Google Cloud Platform projectId in a variable so that we can pass it to bigrquery via our helper code.
require(stringr)
project <- str_trim(system("gcloud -q config list project --format yaml | grep project | cut -d : -f 2", intern=TRUE))

# Remind users about the API_KEY option for accessing public data.
setHook(packageEvent("GoogleGenomics", "attach"),
        function(...) {
          if(!GoogleGenomics:::authenticated()) {
            message(paste("\nIf you are only accessing public data, you can",
                          "authenticate to GoogleGenomics via:",
                          "authenticate(apiKey='YOUR_PUBLIC_API_KEY')", sep="\n"))
          }
        })

