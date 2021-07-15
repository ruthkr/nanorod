is_windows <- function() {
  identical(.Platform$OS.type, "windows")
}

pyenv_root <- function() {
  root <- rappdirs::user_data_dir("r-reticulate")
  dir.create(root, showWarnings = FALSE, recursive = TRUE)
  norm <- normalizePath(root, winslash = "/", mustWork = TRUE)
  file.path(norm, "pyenv")
}

pyenv_python <- function(version) {
  if (is.null(version)) {
    return(NULL)
  }

  # on Windows, Python will be installed as part of the pyenv installation
  prefix <- if (is_windows()) {
    pyenv <- pyenv_find()
    file.path(pyenv, "../../versions", version)
  } else {
    root <- Sys.getenv("PYENV_ROOT", unset = "~/.pyenv")
    file.path(root, "versions", version)
  }

  if (!file.exists(prefix)) {
    fmt <- paste(
      "Python %s does not appear to be installed.",
      "Try installing it with install_python(version = %s).",
      sep = "\n"
    )

    msg <- sprintf(fmt, version, shQuote(version))
    stop(msg)
  }

  stem <- if (is_windows()) "python.exe" else "bin/python"

  normalizePath(
    file.path(prefix, stem),
    winslash = "/",
    mustWork = TRUE
  )
}

pyenv_find <- function() {
  pyenv <- pyenv_find_impl()
  normalizePath(pyenv, winslash = "/", mustWork = TRUE)
}

pyenv_find_impl <- function() {

  # check for pyenv binary specified via option
  pyenv <- getOption("reticulate.pyenv", default = NULL)
  if (!is.null(pyenv) && file.exists(pyenv)) {
    return(pyenv)
  }

  # check for pyenv executable on the PATH
  pyenv <- Sys.which("pyenv")
  if (nzchar(pyenv)) {
    return(pyenv)
  }

  # form stem path to pyenv binary (it differs between pyenv and pyenv-win)
  stem <- if (is_windows()) "pyenv-win/bin/pyenv" else "bin/pyenv"

  # check for a binary in the PYENV_ROOT folder
  root <- Sys.getenv("PYENV_ROOT", unset = "~/.pyenv")
  pyenv <- file.path(root, stem)
  if (file.exists(pyenv)) {
    return(pyenv)
  }

  # check for reticulate's own pyenv
  root <- pyenv_root()
  pyenv <- file.path(root, stem)
  if (file.exists(pyenv)) {
    return(pyenv)
  }

  # all else fails, try to manually install pyenv
  pyenv_bootstrap()
}

#' Set Up Python
#'
#' @param python_path Optional path to Python binary.
#'
#' @export
set_up_python <- function(python_path = NULL) {
  # Variables
  virtualenv_dir <- Sys.getenv("VIRTUALENV_DIR")
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
