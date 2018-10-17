
# Writing custom panels for the _iSEE_ package

The [_iSEE_](https://github.com/csoneson/iSEE) package provides an interactive user interface for exploring data stored in `SummarizedExperiment` objects ([Rue-Albrecht _et al._ (2018)](http://dx.doi.org/10.12688/f1000research.14966.1)).
This repository hosts the source code for minimal iSEE applications that each demonstrate a custom plot or table panel for the _iSEE_ package.

Custom plot and table panels are described in the vignettes of the _iSEE_ package. Briefly, custom panels allow users to add an arbitrary number of functions that process a `SummarizedExperiment` object, a selection of rows, and a selection of columns to produce a `ggplot` object or a `data.frame` from dynamically computed data, unlike predefined plot and table panels.

## Repository organization

Each example is stored in a separate subfolder. Folder names should start with `table_` or `plot_`, to indicate the type of custom panel and facilitate browsing.

Each example must be comprised of four files:

- `custom.R`: a script that defines the function(s) underlying the custom panel.
- `app.R`: a script that prepares a small data set, configures the _iSEE_ application, and launches the tour.
- `tour.txt`: a set of step-wise instructions attached to various UI elements in the _iSEE_ user interface.
- `Screenshot.png`: a screen capture or illustration of the custom panel that will be shown as a thumbnail in this README file. The image should not include more than 1 row of 3 panels, to be displayed in a `width="450px" height="150px"` format.

To launch an application, simply set your working directory to the appropriate subdirectory, and execute `app.R`.

## Examples available

Click on the the image to access the source code.

Screenshot    | Description  
------------- | -------------
<a href="https://github.com/kevinrue/iSEE_custom/tree/master/table_cachedFoldChange"><img src="table_cachedFoldChange/Screenshot.png" alt="Custom cached log fold-change table" width="450px" height="150px"></a> | **Table of log fold-change with cache.**<br/><ul><li>Compute the log fold-change between a selection of samples and all other samples. Restrict the result table to a selection of features.<li>Cache log fold-change values for all features. Only recompute them when the selection of samples changes.<li>Changing the selection of features simply restrict which rows of the cached results are displayed.</ul>
