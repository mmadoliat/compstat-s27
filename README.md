# compstat-s27

Course webpage for MATH 4750 / MSSC 5750 - Computational Statistics, Spring 2027
Site: https://mmadoliat.github.io/compstat-s27/

## Structure
- `_quarto.yml` - website configuration (style follows RegAna-f26)
- `index.qmd` - schedule, read from the Google Sheet "MATH 4750 - Spring 2027 - Schedule"
- `slides/` - Quarto revealjs decks (RegAna-f26 format: 1800x1000, `simple` + `slides.scss`)
  - multi-lecture decks have anchors `#/part-a`, `#/part-b`, `#/part-c` used by the schedule
  - `slides/data/` data used by the decks; `slides/apps/` Shiny apps (`shiny::runApp("slides/apps/knn-explorer")`)
- `hw/` - homework assignments (no solutions are posted in this repository)
- `_freeze/` - cached execution results so CI does not need to re-run every deck

## First local render
```r
renv::restore()
renv::install(c("glmnet", "cluster"))   # used by decks 04 and 07
renv::snapshot()
```
Optional packages (code runs only if installed): microbenchmark, S7, sloop, protoclust, Lahman, testthat, fastICA, energy, keras3.
Then `quarto render` (or Render in RStudio/Positron), commit, and push; GitHub Actions publishes `_site` to gh-pages.
