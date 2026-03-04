library(shiny)

library(bs4Dash)
library(fresh)
library(plotly)
library(DBI)
library(RMySQL)
library(dplyr)
library(lubridate)
library(scales)

rm(list = ls())
source("ui.R")
source("server.R")

shinyApp(ui = ui, server = server)