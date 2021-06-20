# Setup ----
usethis::use_package("reticulate")

# curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
# python3 get-pip.py

# pip install virtualenv
# pip install numpy

usethis::edit_r_profile(scope = "project")
# Copy https://raw.githubusercontent.com/ranikay/shiny-reticulate-app/master/.Rprofile
# Change VIRTUALENV_NAME
# Change Sys.setenv(PYTHON_PATH = "/usr/local/bin/python3") when running locally
# NEVER USE PYTHON SHIPPED BY XCODE!
# Debug using
reticulate::py_discover_config()

reticulate::virtualenv_create(envname = "shiny_nanorod_env", python = "/usr/local/bin/python3")

# Move python code to /src


# Run on terminal ----
# source ~/.virtualenvs/shiny_nanorod_env/bin/activate

# Dependencies
c("ncempy", "scikit-image", "scipy")
