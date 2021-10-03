#' Set Up Python
#'
#' @param python_path Optional path to Python binary.
#'
#' @export
set_up_python <- function(python_path = NULL) {
  # Variables
  virtualenv_dir <- Sys.getenv("VIRTUALENV_NAME")
  python_version <- Sys.getenv("PYTHON_VERSION")

  # Install Python
  if (is.null(python_path)) {
    python_path <- reticulate::install_python(version = python_version)
  }

  if (!reticulate::virtualenv_exists(virtualenv_dir)) {
    # Create virtualenv
    reticulate::use_python(python_path, required = TRUE)
    reticulate::virtualenv_create(envname = virtualenv_dir, python = python_path)
    reticulate::use_virtualenv(virtualenv_dir, required = TRUE)

    # Install dependencies
    py_dependencies <- c("ncempy", "scikit-image", "scipy")
    reticulate::virtualenv_install(virtualenv_dir, packages = py_dependencies, ignore_installed = TRUE)
  }
}
