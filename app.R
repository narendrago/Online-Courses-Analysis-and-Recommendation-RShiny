# load the required packages
library(shiny)
require(shinydashboard)
library(ggplot2)
library(dplyr)
library(plotly)

library(stringr) #Remove special characters
library(tm) #vector source, stopwords etc.
library(superml) #for CV
library(Matrix) # for dense matrices
library(lsa) #for Cosine Simlarity
library(itertools)
library(tidytext)
library(wordcloud2)
library(recommenderlab)

# library(dplyr)
#figPath = system.file("/Users/narendraomprakash/Downloads/png-clipart-united-states-coursera-massive-open-online-course-education-united-states-blue-text1637609115.mask",package = "wordcloud2")

udemy <- read.csv('/Users/narendraomprakash/Desktop/Narendra/Semester-V-FALL2021/Data Visualization/J-Component/udemy_visualisation.csv')

coursera<- read.csv('/Users/narendraomprakash/Desktop/Narendra/Semester-V-FALL2021/Data Visualization/J-Component/coursera_visualisation.csv')

# udemy recommendation dataset
recommendation_udemy<-read.csv("/Users/narendraomprakash/Desktop/Narendra/Semester-V-FALL2021/Data Visualization/J-Component/udemy_recommendation.csv")

recommendation_coursera<-read.csv("/Users/narendraomprakash/Desktop/Narendra/Semester-V-FALL2021/Data Visualization/J-Component/coursera_recommendation.csv")

# For suggestions based on title
recommendation_udemy_title <- recommendation_udemy %>% 
  mutate(course_title=gsub("(http|https).+$|\\n|&amp|[[:punct:]]","",course_title),
         rowIndex=as.numeric(row.names(.))) %>% select(rowIndex,course_title)
recommendation_udemy_title_docList<-as.list(recommendation_udemy_title$course_title)
recommendation_udemy_title_docList.length<-length(recommendation_udemy_title_docList)

# For suggestions based on title
recommendation_coursera_title <- recommendation_coursera %>% 
  mutate(course_title=gsub("(http|https).+$|\\n|&amp|[[:punct:]]","",Name),
         rowIndex=as.numeric(row.names(.))) %>% select(rowIndex,course_title)
recommendation_coursera_title_docList<-as.list(recommendation_coursera_title$course_title)
recommendation_coursera_title_docList.length<-length(recommendation_coursera_title_docList)

recommendation_udemy_subscribers<-recommendation_udemy
#Recommender function based on title
recommender_title<-function(query,retrievingdf,y,y.length){

  # Storing docs in corpus class-basic DS in text mining
  recommendation.docs<-VectorSource(c(y,query))

  # Transform/standardize docs for analysis
  recommendation.corpus<-VCorpus(recommendation.docs) %>%
    tm_map(stemDocument) %>%
    tm_map(removeNumbers) %>%
    tm_map(content_transformer(tolower)) %>%
    tm_map(removeWords,stopwords("en")) %>%
    tm_map(stripWhitespace)

  #TF-IDF Matrix
  tf.idf.matrix<-TermDocumentMatrix(recommendation.corpus,control=list(weighting=function(x) weightSMART(x,spec="ltc"),
                                                                       wordLengths=c(1,Inf)))

  #TF-IDF->Data.Frame
  tf.idf.matrix.df<-tidy(tf.idf.matrix) %>%
    group_by(document) %>%
    mutate(vtrLen=sqrt(sum(count^2))) %>%
    mutate(count=count/vtrLen) %>%
    ungroup() %>%
    select(term:count)

  docMatrix<-tf.idf.matrix.df%>%mutate(document=as.numeric(document)) %>%
    filter(document<y.length+1)


  qryMatrix <-tf.idf.matrix.df%>%
    mutate(document=as.numeric(document))%>%
    filter(document>=y.length+1)

  # Top 10 recommendations
  recommendations<-docMatrix %>%
    inner_join(qryMatrix,by=c("term"="term"),
               suffix=c(".doc",".query")) %>%
    mutate(termScore=round(count.doc*count.query,4))%>%
    group_by(document.query,document.doc) %>%
    summarise(Score=sum(termScore)) %>%
    filter(row_number(desc(Score))<=10) %>%
    arrange(desc(Score)) %>%
    left_join(retrievingdf,by=c("document.doc"="rowIndex")) %>%
    ungroup() %>%
    rename(Result=course_title) %>%
    select(Result,Score) %>%
    data.frame()

  return(recommendations)

}

head(udemy)

library(readr)
library(dplyr)
library(e1071)
library(mlbench)

#Text mining packages
library(tm)
library(SnowballC)
library("wordcloud")
library("RColorBrewer")

#loading the data


corpus = Corpus(VectorSource(coursera$Name))
# Look at corpus


corpus = tm_map(corpus, PlainTextDocument)
corpus = tm_map(corpus, tolower)
#Removing Punctuation
corpus = tm_map(corpus, removePunctuation)

#Remove stopwords
corpus = tm_map(corpus, removeWords, c("cloth", stopwords("english")))

# Stemming
corpus = tm_map(corpus, stemDocument)

# Eliminate white spaces
corpus = tm_map(corpus, stripWhitespace)
# corpus[[1]][1] 

DTM <- TermDocumentMatrix(corpus)
mat <- as.matrix(DTM)
f <- sort(rowSums(mat),decreasing=TRUE)
wordcloud.df <- data.frame(word = names(f),freq=as.numeric(f))
# head(dat, 30)


set.seed(50)
# wordcloud(words = wordcloud.df$word, freq = wordcloud.df$freq, random.order=TRUE)




#Dashboard header carrying the title of the dashboard
header <- dashboardHeader(title = "Analysis Dashboard")  



#Sidebar content of the dashboard
sidebar <- dashboardSidebar(
  sidebarMenu(
    menuItem("Udemy", tabName = "dashboard", icon = icon("dashboard")),
    menuItem("Coursera", tabName = "cdashboard",icon=icon("dashboard")),
    menuItem("Udemy Recommender",tabName="uRecommender",icon=icon("dashboard")),
    menuItem("Coursera Recommender",tabName="cRecommender",icon=icon("dashboard"))
  )
)


frow1 <- fluidRow(
  
  box(
    title = "Number of Subscribers in each Subject"
    ,status = "primary"
    ,solidHeader = TRUE 
    ,collapsible = TRUE 
    ,plotlyOutput("subsribersBysubjects", height = "300px")
  )
  
  ,box(
    title = "Number of Subscribers by levels"
    ,status = "primary"
    ,solidHeader = TRUE 
    ,collapsible = TRUE 
    ,plotlyOutput("subscribersBylevels", height = "300px")
  ) 
  
)

frow2 <- fluidRow(
  
  box(
    title = "Count of courses of each subject"
    ,status = "primary"
    ,solidHeader = TRUE
    ,collapsible = TRUE
    ,plotlyOutput("CoursesEachSubj", height = "300px")
  )
  
  ,box(
    title = "Prices of each levels of courses"
    ,status = "primary"
    ,solidHeader = TRUE
    ,collapsible = TRUE
    ,plotlyOutput("pricesEachLevel", height = "300px")
  )
  
)

frow3 <- fluidRow(
  
  box(
    title = "Number of subscribers and reviews for each level"
    ,status = "primary"
    ,solidHeader = TRUE
    ,collapsible = TRUE
    ,plotlyOutput("SubsandReviewsBylevel", height = "300px")
  )
  
  ,box(
    title = "Number of subscribers and reviews for each subject"
    ,status = "primary"
    ,solidHeader = TRUE
    ,collapsible = TRUE
    ,plotlyOutput("SubsandReviewsBySubj", height = "300px")
  )
  
)

frow4 <- fluidRow(
  
  box(
    title = "Different Paid/Free Courses within a difficulty level"
    ,status = "primary"
    ,solidHeader = TRUE
    ,collapsible = TRUE
    ,plotlyOutput("PaidFree", height = "300px")
  )
  ,box(
    title = "Number of lectures and price of course based on difficulty levels"
    ,status = "primary"
    ,solidHeader = TRUE
    ,collapsible = TRUE
    ,plotlyOutput("LecPriceDiff", height = "300px")
  )
  
  
)

frow5 <- fluidRow(
  
  box(
    title = "Paid vs Unpaid courses"
    ,status = "primary"
    ,solidHeader = TRUE
    ,collapsible = TRUE
    ,plotlyOutput("PaidUnpaid", height = "300px")
  )
  ,box(
    title = "Number of lectures in each subject"
    ,status = "primary"
    ,solidHeader = TRUE
    ,collapsible = TRUE
    ,plotlyOutput("LecEachSubj", height = "300px")
  )
  
)
frow6 <-fluidRow(
  box(
    title = "Difficulty level vs Count"
    ,status = "primary"
    ,solidHeader = TRUE
    ,collapsible = TRUE
    ,plotlyOutput("DiffvsCount", height = "300px")
  ),
  box(
    title = "Most frequently provided rating for a particultar tag"
    ,status = "primary"
    ,solidHeader = TRUE
    ,collapsible = TRUE
    ,plotlyOutput("HighCountDiff", height = "300px")
  )
)

frow7 <-fluidRow(
  box(
    title = "Highest Rating"
    ,status = "primary"
    ,width= "100%"
    ,solidHeader = TRUE
    ,collapsible = TRUE
    ,plotlyOutput("HighReview", height = "300px")
  )
  # ,box(
  #   title = "Review vs Tag"
  #   ,status = "primary"
  #   ,solidHeader = TRUE
  #   ,collapsible = TRUE
  #   ,plotlyOutput("ReviewvsTag", height = "300px")
  # )

)

frow8 <-fluidRow(
  box(
    title = "Tags vs Count"
    ,status = "primary"
    ,solidHeader = TRUE
    ,collapsible = TRUE
    ,plotlyOutput("TagsvsCount", height = "300px")
  ),box(
    title = "WordCloud"
    ,status = "primary"
    ,solidHeader = TRUE
    ,collapsible = TRUE
    ,wordcloud2Output("wordcloud",height = "300px")
  )

  
)

frow9 <- fluidRow(
  
  box(
    title = "Udemy Recommender based on Title"
    ,status = "primary"
    ,solidHeader = TRUE
    ,collapsible = TRUE
    # ,selectInput("filterVariable", "Filter:",
    #             c("Course Title" = "courseTitle",
    #               "Reviews" = "courseReviews"))
    # ,uiOutput('dynamic')
    ,textInput("udemyCourseTitle",label="Enter course title")
    ,submitButton("Submit", icon("refresh"))
  ),
  tableOutput("uRecommendationTable")

)


frow10 <- fluidRow(
  
  box(
    title = "Coursera Recommender based on Title"
    ,status = "primary"
    ,solidHeader = TRUE
    ,collapsible = TRUE
    # ,selectInput("filterVariable", "Filter:",
    #             c("Course Title" = "courseTitle",
    #               "Reviews" = "courseReviews"))
    # ,uiOutput('dynamic')
    ,textInput("courseraCourseTitle",label="Enter course title")
    ,submitButton("Submit", icon("refresh"))
  ),
  tableOutput("cRecommendationTable")
  
)



body <- dashboardBody(
  tabItems(
    tabItem(tabName = "dashboard",
            frow1,frow2,frow3,frow4,frow5
    ),
    
    tabItem(tabName = "cdashboard",
            frow6,frow7,frow8
    ),
    tabItem(tabName = "uRecommender",
            frow9
    ),
    tabItem(tabName = "cRecommender",
            frow10
    )
  )
)

# combine the two fluid rows to make the body

#completing the ui part with dashboardPage
ui <- dashboardPage(title = 'This is my Page title', header, sidebar, body, skin='purple')

# create the server functions for the dashboard  
server <- function(input, output) { 
  
  
  #creating the plotOutput content
  
  output$subsribersBysubjects <- renderPlotly({
    p1 <- plot_ly(udemy,x=~subject.f,y=~num_subscribers,type = "bar")
    p1
  })
  
  output$subscribersBylevels <- renderPlotly({
    # p2<-ggplot(udemy, aes(x="", y=num_subscribers, fill=level.f)) +
    #   geom_bar(stat="identity", width=1) +
    #   coord_polar("y", start=0)
    # p3<-ggplotly(p2)
    # p3
    fig <- plot_ly(udemy, labels = ~level.f, values = ~num_subscribers, type = 'pie')
    fig <- fig %>% layout(title = 'Number of subscribers by levels',
                          xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
                          yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE))
    
    fig
  })
  
  output$CoursesEachSubj <- renderPlotly({
    udem<-udemy
    
    udem <- udem %>% group_by(udem$subject.f)
    udem <- udem %>% summarize(count = n())
    colnames(udem)[1] <- "subject"
    fig <- udem %>% plot_ly(labels = ~subject, values = ~count)
    fig <- fig %>% add_pie(hole = 0.6)
    fig <- fig %>% layout(title = "Count of courses of each subject",  showlegend = F,
                          xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
                          yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE))
    
    fig
  })
  
  output$pricesEachLevel <- renderPlotly({
    fig <- plot_ly(udemy, y = ~price, color = ~level.f, type = "box")
    fig <- fig %>% layout(title = 'Prices of each Levels of Courses')
    
    fig
    
  })
  output$SubsandReviewsBylevel <- renderPlotly({
    
    fig <- plot_ly(udemy, x = ~udemy$level.f, y = ~udemy$num_subscribers, type = 'bar', name = 'Num of Subscribers', marker = list(color = 'rgb(49,130,189)'))
    fig <- fig %>% add_trace(y = ~udemy$num_reviews, name = 'Number of reviews', marker = list(color ='rgb(204,204,204)'))
    fig <- fig %>% layout(xaxis = list(title = "", tickangle = -45),
                          yaxis = list(title = ""),
                          margin = list(b = 100),
                          barmode = 'group')
    
    fig
    
  })
  output$SubsandReviewsBySubj <- renderPlotly({
    
    fig <- plot_ly(udemy, x = ~udemy$subject.f, y = ~udemy$num_subscribers, type = 'bar', name = 'Num of Subscribers', marker = list(color = 'rgb(49,130,189)'))
    fig <- fig %>% add_trace(y = ~udemy$num_reviews, name = 'Number of reviews', marker = list(color = 'rgb(204,204,204)'))
    fig <- fig %>% layout(xaxis = list(title = "", tickangle = -45),
                          yaxis = list(title = ""),
                          margin = list(b = 100),
                          barmode = 'group')
    
  })
  output$PaidFree <- renderPlotly({
    
    all_levels_paid<-filter(udemy,level.f=="All Levels" & is_paid.f=="True")
    all_levels_free<-filter(udemy,level.f=="All Levels" & is_paid.f=="False")
    intermediate_levels_paid<-filter(udemy,level.f=="Intermediate Level" & is_paid.f=="True")
    intermediate_levels_free<-filter(udemy,level.f=="Intermediate Level" & is_paid.f=="False")
    beginner_levels_paid<-filter(udemy,level.f=="Beginner Level" & is_paid.f=="True")
    beginner_levels_free<-filter(udemy,level.f=="Beginner Level" & is_paid.f=="False")
    expert_levels_paid<-filter(udemy,level.f=="Expert Level" & is_paid.f=="True")
    expert_levels_free<-filter(udemy,level.f=="Expert Level" & is_paid.f=="False")
    
    
    dlevels<-c("All Levels","Expert Level","Intermediate Level","Beginner Level")
    paid<-c(1807,58,391,1112)
    free<-c(122,0,30,158)
    fig <- plot_ly(udemy, x = ~dlevels, y = ~paid, type = 'bar', name = 'Paid')
    fig <- fig %>% add_trace(y = ~free, name = 'Free')
    fig <- fig %>% layout(title='Different Paid/Free Courses within a difficulty level',yaxis = list(title = 'Count'), barmode = 'stack')
    
    fig
    
  })
  
  output$LecPriceDiff <- renderPlotly({
    
    all_levels_paid<-filter(udemy,level.f=="All Levels" & is_paid.f=="True")
    all_levels_free<-filter(udemy,level.f=="All Levels" & is_paid.f=="False")
    intermediate_levels_paid<-filter(udemy,level.f=="Intermediate Level" & is_paid.f=="True")
    intermediate_levels_free<-filter(udemy,level.f=="Intermediate Level" & is_paid.f=="False")
    beginner_levels_paid<-filter(udemy,level.f=="Beginner Level" & is_paid.f=="True")
    beginner_levels_free<-filter(udemy,level.f=="Beginner Level" & is_paid.f=="False")
    expert_levels_paid<-filter(udemy,level.f=="Expert Level" & is_paid.f=="True")
    expert_levels_free<-filter(udemy,level.f=="Expert Level" & is_paid.f=="False")
    
    
    dlevels<-c("All Levels","Expert Level","Intermediate Level","Beginner Level")
    paid<-c(1807,58,391,1112)
    free<-c(122,0,30,158)
    udemy1 <- udemy[order(udemy$num_reviews), ]
    
    fig <- plot_ly(udemy1, x = ~num_lectures, y = ~level.f, name = "No. of lectures", type = 'scatter',
                   mode = "markers", marker = list(color = "pink"))
    fig <- fig %>% add_trace(x = ~price, y = ~level.f, name = "Price",type = 'scatter',
                             mode = "markers", marker = list(color = "blue"))
    fig <- fig %>% layout(
      title = "Number of lectures and price of course based on difficulty levels",
      xaxis = list(title = "Number of lectures/Price"),
      yaxis= list(title="Difficulty Level"),
      margin = list(l = 1)
    )
    
    fig
    
  })
  
  output$PaidUnpaid <- renderPlotly({
    
    s1<-count(udemy,'is_paid.f')
    fig <- plot_ly(udemy, labels = ~udemy$is_paid.f, values =s1, type = 'pie')
    fig <- fig %>% layout(title = 'Paid Courses VS Unpaid Courses',
                          xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
                          yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE))
    
    fig
    
  })
  
  output$LecEachSubj <- renderPlotly({
    
    # Violin Plot (plot-3)
    g <- ggplot(udemy, aes(subject.f,num_lectures,fill=subject.f))
    g + geom_violin() + 
      labs(title="Violin plot", 
           subtitle="Subject vs Number of lectures",
           x="Subject",
           y="Number of lectures")
    
  })
  # output$DiffvsRating <- renderPlotly({
  #   
  #   p1 <- plot_ly(x = coursera$Difficulty.f,
  #                 y = coursera$Rating,
  #                 name = "Cities",
  #                 type = "bar")
  #   p1
  #   
  # })
  #coursera plots
  output$DiffvsCount <- renderPlotly({
    fig <- plot_ly()
    sort<-coursera[order(coursera$Rating,decreasing = TRUE),]
    
    remove_none<- filter(sort,(sort$Rating %in% c('None'))==FALSE)
    remove_none<- filter(remove_none,(remove_none$Difficulty.f %in% c('None'))==FALSE)
    
    fig <- fig %>% add_pie(data = count(remove_none, Difficulty.f), labels = ~Difficulty.f, values = ~n,
                           name = "Difficulty.f")
    fig
    
  })
  
  
  output$HighCountDiff <- renderPlotly({
    
    # sort<-coursera[order(coursera$Rating,decreasing = TRUE),]
    # 
    # remove_none<- filter(sort,(sort$Rating %in% c('None'))==FALSE)
    # remove_none<- filter(remove_none,(remove_none$Difficulty.f %in% c('None'))==FALSE)
    # df1<-remove_none %>% group_by(remove_none$Rating,remove_none$Difficulty.f) %>% summarise(n = n()) %>% arrange(desc(n))
    # df1
    # 
    # sort_rating<-df1[order(df1$`remove_none$Rating`,decreasing = TRUE),]
    # 
    # ## scatterplot to find the highest count and difficulty level
    # 
    # fig <- plot_ly(df1, x = ~df1$`remove_none$Rating`, y = ~df1$n, text = ~df1$`remove_none$Difficulty.f`, type = 'scatter', mode = 'markers', size = ~df1$n, color = ~df1$`remove_none$Rating`, colors = 'Paired',
    #                #Choosing the range of the bubbles' sizes:
    #                sizes = c(10, 50),
    #                marker = list(opacity = 0.5, sizemode = 'diameter'))
    # fig <- fig %>% layout(title = 'Difficulty Level vs Count',
    #                       xaxis = list(title='Rating'),
    #                       yaxis = list(title='count'),
    #                       showlegend = FALSE)
    # 
    # fig
    
    df5<-coursera%>% group_by(coursera$Rating,coursera$Tags) %>% summarise(n = n()) %>% arrange(desc(n))
    df6<-head(df5,200)
    
    fig <- plot_ly(df6, x = ~df6$`coursera$Rating`, y = ~df6$n, text = ~df6$`coursera$Tags`, type = 'scatter', mode = 'markers', size = ~df6$n, color = ~df6$`coursera$Rating`, colors = 'Paired',
                   #Choosing the range of the bubbles' sizes:
                   sizes = c(10, 50),
                   marker = list(opacity = 0.5, sizemode = 'diameter'))
    fig <- fig %>% layout(
                          xaxis = list(title='Rating'),
                          yaxis = list(title='count'),
                          showlegend = FALSE)
    
    fig
  })
  output$HighReview <- renderPlotly({
    sort<-coursera[order(coursera$Rating,decreasing = TRUE),]
    
    remove_none<- filter(sort,(sort$Rating %in% c('None'))==FALSE)
    remove_none<- filter(remove_none,(remove_none$Difficulty.f %in% c('None'))==FALSE)
    df1<-remove_none %>% group_by(remove_none$Rating,remove_none$Difficulty.f) %>% summarise(n = n()) %>% arrange(desc(n))
    df1
    
    sort_rating<-df1[order(df1$`remove_none$Rating`,decreasing = TRUE),]
    
    plot_ly(sort_rating, x = ~sort_rating$`remove_none$Rating`, y = ~n, type = 'bar', 
            name = ~sort_rating$`remove_none$Difficulty.f`, color = ~sort_rating$`remove_none$Difficulty.f`) %>%
      layout(yaxis = list(title = 'Count'), barmode = 'stack', xaxis = list(title = 'Rating'))
    
    
  })
  
  # output$ReviewvsTag <- renderPlotly({
  #   sort<-coursera[order(coursera$Rating,decreasing = TRUE),]
  #   
  #   remove_none<- filter(sort,(sort$Rating %in% c('None'))==FALSE)
  #   remove_none<- filter(remove_none,(remove_none$Difficulty.f %in% c('None'))==FALSE)
  #   df1<-remove_none %>% group_by(remove_none$Rating,remove_none$Difficulty.f) %>% summarise(n = n()) %>% arrange(desc(n))
  #   df1
  #   df3<-remove_none
  #   df4<-df3 %>% group_by(df3$Rating,df3$Tags,df3$Difficulty.f) %>% summarise(n = n()) %>% arrange(desc(n))
  #   df4
  #   df5<-head(df4,100)
  #   fig <- plot_ly(df5, labels = ~df5$`df3$Tags`, values = ~df5$n, type = 'pie')
  #   fig <- fig %>% layout(
  #     xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
  #     yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE))
  #   
  #   fig
  #   
  # })
  
  output$TagsvsCount <- renderPlotly({
    sort<-coursera[order(coursera$Rating,decreasing = TRUE),]
    
    remove_none<- filter(sort,(sort$Rating %in% c('None'))==FALSE)
    remove_none<- filter(remove_none,(remove_none$Difficulty.f %in% c('None'))==FALSE)
    df1<-remove_none %>% group_by(remove_none$Rating,remove_none$Difficulty.f) %>% summarise(n = n()) %>% arrange(desc(n))
    df1
    df3<-remove_none
    df4<-df3 %>% group_by(df3$Rating,df3$Tags,df3$Difficulty.f) %>% summarise(n = n()) %>% arrange(desc(n))
    df4
    df5<-head(df4,100)
    
    plot_ly(df4, x = ~df4$`df3$Tags`, y = ~n, type = 'bar', 
            name = ~df4$`df3$Difficulty.f`, color = ~df4$`df3$Difficulty.f`) %>%
      layout(yaxis = list(title = 'Count'), xaxis = list(title = 'Tags'), barmode = 'stack')
    
    
  })
  output$DiffvsRating <- renderPlotly({
    df5<-coursera %>% group_by(coursera$Difficulty.f,coursera$Rating) %>% summarise(n = n()) %>% arrange(desc(n))
    df5 %>%
      plot_ly(
        x = ~n
        ,y = ~df5$`coursera$Difficulty.f`
        ,color = ~df5$`coursera$Rating`
        ,name = ~df5$`coursera$Rating`
        ,type = "bar"
        ,orientation = "h"
      ) %>%
      layout(
        barmode = "stack"
      )%>%
      layout(title = 'Difficulty Level Vs Rating', plot_bgcolor = "#e5ecf6", xaxis = list(title = 'count'), 
             yaxis = list(title = 'Difficulty Level'))
    
    
  })
  # output$dynamic <- renderUI({
  #   tags<-tagList()
  #   if(input$filterVariable=="courseTitle"){
  #   tags[[1]]<-textInput("filter",label="Enter course title")
  #   }else if(input$filterVariable=="courseReviews"){
  #     tags[[1]]<-numericInput("filter",label="Enter course reviews",value=9)
  #   }
  #   tags[[2]]<-submitButton("Submit", icon("submit"))
  #   tags
  # }
  
# )
  output$uRecommendationTable<-renderTable(recommender_title(input$udemyCourseTitle,recommendation_udemy_title,recommendation_udemy_title_docList,recommendation_udemy_title_docList.length))

  output$cRecommendationTable<-renderTable(recommender_title(input$courseraCourseTitle,recommendation_coursera_title,recommendation_coursera_title_docList,recommendation_coursera_title_docList.length))
                                                                                    
  output$wordcloud<-renderWordcloud2({
    wordcloud2(wordcloud.df, color = "random-light", backgroundColor="white")
    
  })

}




shinyApp(ui, server)