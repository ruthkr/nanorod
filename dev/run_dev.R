# Set options here
options(golem.app.prod = FALSE) # TRUE = production mode, FALSE = development mode

# Detach all loaded packages and clean your environment
golem::detach_all_attached()
# rm(list=ls(all.names = TRUE))
library(devtools)

# Document and reload your package
golem::document_and_reload()

# Recompile CSS file
source(here::here("inst/app/www/sass", "compile_sass.R"))

# Run the application
run_app()
