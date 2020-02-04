library(shiny)
library(shinydashboard)
library(IDGF)
library(DT)

css3 <- HTML("
.shiny-download-link {width: 100%;text-align: center;}")

## CSS pour la couleur du sidebar
css2 <- HTML("
.text {
    fill: #FFFFFF
}")

# Define UI for application that draws a histogram
ui <- dashboardPage(skin = "green",

                    ## Le header
                    dashboardHeader(title="Applicatif IDGF", titleWidth = 300),

                    ## Le sidebar, avec l'input, des item et subitem
                    dashboardSidebar(width = 350,h4(
                                     fileInput("files", "Charger le fichier de données (format excel)", accept = c(".xls",".xlsx",".csv")),
                                     sidebarMenu(id = "tabs",
                                                 menuItem("Résultats bruts", tabName = "table", icon = icon("list")),
                                                 menuItem("Graphiques de diagnostic", tabName = "diagnostic", icon = icon("tachometer"))))),

                    dashboardBody(
                        tags$head(tags$style(css2)),
                        tags$head(tags$style(css3)),
                        tabItems(
                            tabItem(tabName = "diagnostic",
                                    plotOutput("myplot", height = "900px")),
                            tabItem(tabName = "table",
                                    uiOutput("mytext", ),
                                    br(),
                                    box(tableOutput("mytable"), width = 12),
                                    br(),
                                    uiOutput("dl"))
                        )
                    )

)


# Define server logic required to draw a histogram
server <- function(input, output) {

    IDGFdata <- eventReactive(input$files, {

    IDGF::importIDGF(input = input$files$datapath)

    })

    ## Production des plots dimension
    IDGFres <- eventReactive(input$files, {

        IDGFdata() %>% computeIDGF()

    })

    ## Production des diagrammes radar
    IDGFresrad <- eventReactive(input$files, {

        IDGFres() %>% radarIDGF()

    })


    output$myplot <- renderPlot({

        ggpubr::ggarrange(plotlist = IDGFresrad()$plot)

    })

    output$mytable <- renderTable({

    IDGFres() %>% dplyr::mutate(id_releve = as.character(id_releve))

    })


    output$mytext <- renderUI({

        inFile <- input$files

        if (is.null(inFile))
            return(

                h1(tags$b(div(style="display:inline-block;width:100%;text-align: left;","\U2190 Pour démarrer l'application, charger un fichier de données au format .xls, .xlsx ou .csv")))
            )



        n_operations = dplyr::n_distinct(IDGFres()$id_releve)



        h2(tags$b(div(style="display:inline-block;width:100%;text-align: left;",paste0("\U2713 Le fichier de données a été correctement importé. Il contient ",n_operations," opérations de contrôle."))),style = "color:green")


    })



    output$dl <- renderUI({

        inFile <- input$files

        if (is.null(inFile))
            return()

        downloadButton("zipfile", "Exporter ce tableau au format .csv ainsi que les graphiques au format .png", style = "width:100%;")


    })


    output$zipfile <- downloadHandler(
        filename = "export_IDGF.zip",
        content = function(file) {


            inFile <- input$files

            if (is.null(inFile))
                return(

                    h1(tags$b(div(style="display:inline-block;width:100%;text-align: left;","\U2190 Pour démarrer l'application, charger un fichier de données au format .xls, .xlsx ou .csv")))
                )



            withProgress(message = "Production des figures en cours........", detail = "Merci de patienter quelques instants", value = 0.2,{

            outdir <- file.path(tempdir(),"results")

            exportIDGF(IDGFresrad(), outdir = outdir)

            setwd(outdir)
            fs <- file.path(list.files(outdir, recursive = TRUE))

            zip(zipfile = file, files = fs)
            incProgress(0.8)
            })



        }
        ,contentType = "application/zip"
    )




}

# Run the application
shinyApp(ui = ui, server = server)
