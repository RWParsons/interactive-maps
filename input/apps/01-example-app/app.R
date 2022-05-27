library(shiny)

ui <- fluidPage(
  numericInput(inputId='n', label='sample size', value=10),
  plotOutput('plot')
)

server <- function(input, output, session) {
  output$plot <- renderPlot({
    hist(x=rnorm(input$n))
  })
}

shinyApp(ui, server)
