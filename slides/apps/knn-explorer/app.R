# k-NN Regression Explorer
# Adapted from STAR-DS (Maadooliat, Choi, Cirkovic) for MATH 4750 / MSSC 5750.
# Run with: shiny::runApp("slides/apps/knn-explorer")
library(shiny)
library(ggplot2)

knn_pred <- function(train_x, train_y, test_x, k) {
  train_x <- scale(as.matrix(train_x))
  test_x  <- scale(as.matrix(test_x),
                   center = attr(train_x, "scaled:center"),
                   scale  = attr(train_x, "scaled:scale"))
  m <- nrow(test_x)
  preds <- numeric(m); ids <- integer(m * k)
  for (j in seq_len(m)) {
    d <- colSums((t(train_x) - test_x[j, ])^2)
    idx <- order(d)[seq_len(k)]
    preds[j] <- mean(train_y[idx])
    ids[((j - 1) * k + 1):(j * k)] <- idx
  }
  list(preds = preds, ids = ids)
}

segment_df <- function(train_x, test_x, ids, k) {
  train_x <- as.matrix(train_x); test_x <- as.matrix(test_x)
  out <- as.data.frame(cbind(test_x[rep(seq_len(nrow(test_x)), each = k), , drop = FALSE],
                             train_x[ids, , drop = FALSE]))
  names(out) <- c(paste0("test_", colnames(train_x)), paste0("train_", colnames(train_x)))
  out
}

make_split <- function(data, prop = 0.7) {
  idx <- sample(nrow(data), size = floor(prop * nrow(data)))
  list(train = data[idx, ], test = data[-idx, ])
}

ui <- fluidPage(
  titlePanel("k-NN Regression Explorer"),
  sidebarLayout(
    sidebarPanel(
      sliderInput("k", "Number of neighbors (k):", min = 1, max = 20, value = 5, step = 1),
      actionButton("resample", "New train/test split"),
      hr(),
      h4("Performance"),
      verbatimTextOutput("trainPerf"),
      verbatimTextOutput("testPerf")
    ),
    mainPanel(
      plotOutput("predPlot", height = "400px"),
      tableOutput("predTable")
    )
  )
)

server <- function(input, output, session) {
  split <- eventReactive(input$resample, make_split(mtcars, prop = 0.8), ignoreNULL = FALSE)
  vars <- c("wt", "qsec")
  fitted_vals <- reactive({
    tr <- split()$train
    knn_pred(tr[, vars], tr$mpg, tr[, vars], input$k)
  })
  predicted <- reactive({
    knn_pred(split()$train[, vars], split()$train$mpg, split()$test[, vars], input$k)
  })
  mse <- function(obs, pred) mean((obs - pred)^2)
  r2  <- function(obs, pred) 1 - sum((obs - pred)^2) / sum((obs - mean(obs))^2)
  output$trainPerf <- renderPrint({
    obs <- split()$train$mpg
    cat("Training set:\n  MSE =", round(mse(obs, fitted_vals()$preds), 3),
        "  R2 =", round(r2(obs, fitted_vals()$preds), 3), "\n")
  })
  output$testPerf <- renderPrint({
    obs <- split()$test$mpg
    cat("Test set:\n  MSE =", round(mse(obs, predicted()$preds), 3),
        "  R2 =", round(r2(obs, predicted()$preds), 3), "\n")
  })
  output$predPlot <- renderPlot({
    tr <- split()$train; te <- split()$test; te$id <- seq_len(nrow(te))
    nn <- segment_df(tr[, vars], te[, vars], predicted()$ids, input$k)
    te$pred <- predicted()$preds
    ggplot() +
      geom_segment(aes(x = test_wt, xend = train_wt, y = test_qsec, yend = train_qsec),
                   color = "grey50", linetype = "dotted", data = nn) +
      geom_point(aes(wt, qsec, color = mpg), size = 2, data = tr) +
      geom_text(aes(wt, qsec, color = pred, label = id), size = 5, fontface = "bold", data = te) +
      scale_color_gradient(low = "#6A00A8FF", high = "#FCA636FF") +
      theme_classic() + labs(x = "wt", y = "qsec")
  })
  output$predTable <- renderTable({
    te <- split()$test
    data.frame(id = seq_len(nrow(te)), car = rownames(te), actual = round(te$mpg, 2),
               predicted = round(predicted()$preds, 2))
  })
}

shinyApp(ui, server)
