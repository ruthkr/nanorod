.onLoad <- function(libname, pkgname) {
  Sys.setenv(VIRTUALENV_NAME = "shiny_nanorod_env")
  Sys.setenv(PYTHON_VERSION = "3.9.6")
}
