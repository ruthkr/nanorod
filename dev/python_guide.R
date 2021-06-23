# Setup ----
usethis::use_package("reticulate")

# cd dev
# curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
# python3 get-pip.py

# python3 -m pip install virtualenv
# python3 -m pip install numpy

usethis::edit_r_profile(scope = "project")
# Copy https://raw.githubusercontent.com/ranikay/shiny-reticulate-app/master/.Rprofile
# Change VIRTUALENV_NAME
# Change Sys.setenv(PYTHON_PATH = "/usr/local/bin/python3") when running locally
# NEVER USE PYTHON SHIPPED BY XCODE!
# Debug using
reticulate::py_discover_config()

# Create virtualenv
virtualenv_dir <- Sys.getenv("VIRTUALENV_NAME")
python_path <- Sys.getenv("PYTHON_PATH")

reticulate::use_python(python_path, required = TRUE)
reticulate::virtualenv_create(envname = virtualenv_dir, python = python_path)
reticulate::use_virtualenv(virtualenv_dir, required = TRUE)

# Install dependencies
PYTHON_DEPENDENCIES <- c("ncempy", "scikit-image", "scipy")
reticulate::virtualenv_install(virtualenv_dir, packages = PYTHON_DEPENDENCIES, ignore_installed = TRUE)

# Move python code to /src


# Run on terminal ----
# source ~/.virtualenvs/shiny_nanorod_env/bin/activate
