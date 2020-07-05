
# Dichotomous Model based on Rasch Measurement
#' @importFrom R6 R6Class
#' @import jmvcore
#' @importFrom TAM tam.jml
#' @importFrom TAM tam.jml.fit
#' @importFrom TAM tam.mml
#' @importFrom TAM IRT.WrightMap
#' @export


dichotomousClass <- if (requireNamespace('jmvcore'))
  R6::R6Class(
    "dichotomousClass",
    inherit = dichotomousBase,
    private = list(
 #=============================================================
      
      .init = function() {
        if (is.null(self$data) | is.null(self$options$vars)) {
          self$results$instructions$setVisible(visible = TRUE)
          
        }
        
        self$results$instructions$setContent(
          "<html>
            <head>
            </head>
            <body>
            <div class='instructions'>
            <p>Welcome to Dichotomous Rasch Model.</p>

            <p><b>To get started:</b></p>

            <p>- The input dataset require dichotomous data with the type of <b>numeric-continuous</b> in jamovi.</p>
            <p>- Just highlight the variables and click the arrow to move it across into the 'Variables' box.</p>
            <p>- The result tables are estimated by Rasch  model with Joint Maximum Likelihood(JML) estimation.</p>
            <p>- MADaQ3 statistic(an effect size of model fit) is estimated based on Marginal Maximum Likelihood(MML) estimation.</P>
            <p>If you encounter any errors, or have questions, please e-mail me: snow@cau.ac.kr</a></p>
            </div>
            </body>
            </html>"
        )
        
        #  private$.initItemsTable()
        
        if(self$options$modelfitp)
          self$results$scale$setNote("Note","MADaQ3= Mean of absolute values of centered Q_3 statistic with p value obtained by Holm
adjustment; Ho= the data fit the Rasch model.")
       
        if(self$options$infit)
          self$results$items$setNote("Note","Infit= Information-weighted mean square statistic; Outfit= Outlier-sensitive means square statistic.")
        
         
        if (length(self$options$vars) <= 1)
          self$setStatus('complete')
      },
      
      
      
      #======================================++++++++++++++++++++++
      .run = function() {
        
        # get variables-------
        
        data <- self$data
        
        vars <- self$options$get('vars')
        
        
        # Ready--------
        
        ready <- TRUE
        
        if (is.null(self$options$vars) ||
            length(self$options$vars) < 2)
          
          ready <- FALSE
        
        if (ready) {
          data <- private$.cleanData()
          
          results <- private$.compute(data)
          
          # populate scale table-----
          
          private$.populateScaleTable(results)
          
          # populate item table----
          
          private$.populateItemsTable(results)
          
          # prepare plot-----
          
          private$.prepareWrightmapPlot(data)
          
          
        }
        
      },
      
      
      # compute results=====================================================
      
      .compute = function(data) {
        
        # get variables------
        
        data <- self$data
        
        vars <- self$options$get('vars')
        
        
        # estimate the Rasch model with JML using function 'tam.jml'-----
        
        tamobj = TAM::tam.jml(resp = as.matrix(data))
        
        
        # estimate Item Total Score(Sufficient Statistics)-------
        
        itotal <- tamobj$ItemScore
        itotal <- -itotal
        
        # computing proportions for each item---------
        
        n <- tamobj$nstud
        prop <- itotal / n
        
        # estimate item difficulty measure---------------
        
        imeasure <-  tamobj$xsi
        
        
        # estimate standard error of the item parameter-----
        
        ise <- tamobj$errorP
        
        
        # computing infit statistics---------------------
        
        infit <- TAM::tam.jml.fit(tamobj = tamobj)$fit.item$infitItem
        
        # computing outfit statistics-----------------------
        
        outfit <- TAM::tam.jml.fit(tamobj = tamobj)$fit.item$outfitItem
        
        # computing person separation reliability-------
        
        reliability <- tamobj$WLEreliability
        
        #computing an effect size of model fit(MADaQ3) using MML-------
        
        tamobj1 = TAM::tam.mml(resp = as.matrix(data))
        
        # assess model fit---- 
        
        res <- TAM::tam.modelfit(tamobj = tamobj1)
        
        modelfit <- res$stat.MADaQ3$MADaQ3
        
        # pvalue--------
        
        modelfitp <- res$stat.MADaQ3$p
        
      
        results <-
          list(
            'itotal' = itotal,
            'prop' = prop,
            'imeasure' = imeasure,
            'ise' = ise,
            'infit' = infit,
            'outfit' = outfit,
            'reliability' = reliability,
            'modelfit' = modelfit,
            'modelfitp' = modelfitp
            
          )
        
      },
      
      #### Init. tables ====================================================
      
      .initItemsTable = function() {
       
         table <- self$results$items
        
        for (i in seq_along(items))
          table$addFootnote(rowKey = items[i], 'name')
        
      },
      
      # populate scale table-------------------
      
      .populateScaleTable = function(results) {
        table <- self$results$scale
        
        reliability <- results$reliability
        
        modelfit <- results$modelfit
        modelfitp <- results$modelfitp
        
        row <- list()
        
        row[['reliability']] <- reliability
        row[['modelfit']] <- modelfit
        row[['modelfitp']] <- modelfitp
        
        table$setRow(rowNo = 1, values = row)
        
#         #setNote--------
#         
#         table$setNote("Note", paste0(
#           ifelse(
#             self$options$get('modelfitp'),
#             "MADaQ3= Mean of absolute values of centered Q_3 statistic with p value obtained by Holm
# adjustment; Ho= the data fit the Rasch model.",
#             ""
#           )
#         ))
        
      },
      
      
      # populate item tables==============================================
      
      .populateItemsTable = function(results) {
  
        table <- self$results$items
        
        items <- self$options$vars
        
        
        itotal <- results$itotal
        prop <- results$prop
        
        imeasure <- results$imeasure
        ise <- results$ise
        
        infit <- results$infit
        outfit <- results$outfit
        
        
        for (i in seq_along(items)) {
     
               row <- list()
          
          
          row[["total"]] <- itotal[i, 1]
          row[["prop"]] <- prop[i, 1]
          
          row[["measure"]] <- imeasure[i]
          
          row[["ise"]] <- ise[i]
          
          row[["infit"]] <- infit[i]
          
          row[["outfit"]] <- outfit[i]
          
          
          table$setRow(rowKey = items[i], values = row)
        }
        
        #setNote--------
        
        # table$setNote("Note", paste0(
        #   ifelse(
        #     self$options$get('infit'),
        #     "Infit= Information-weighted mean square statistic.",
        #     ""
        #   ),
        #   
        #   ifelse(
        #     self$options$get('outfit'),
        #     "Outfit= Outlier-sensitive means square statistic.",
        #     ""
        #   )
        # ))
        
      },
      
 
 #### Plot functions ----
 
 .prepareWrightmapPlot = function(data) {
   
   
   wright = TAM::tam.mml(resp = as.matrix(data))
   
   
   # Prepare Data For Plot -------
   
   image <- self$results$plot
   image$setState(wright)
   
 
 },
 
 #================================================================
 
 .plot = function(image, ...) {
 
    wrightmap <- self$options$wrightmap
    
    if (!wrightmap)
      return()
   
   
   wright <- image$state
   
   plot <- TAM::IRT.WrightMap(wright ) 
   
   print(plot)
   TRUE
 },
 
 
 #### Helper functions =================================
      
      .cleanData = function() {
        items <- self$options$vars
        
        data <- list()
        
        for (item in items)
          data[[item]] <- jmvcore::toNumeric(self$data[[item]])
        
        attr(data, 'row.names') <- seq_len(length(data[[1]]))
        attr(data, 'class') <- 'data.frame'
        data <- jmvcore::naOmit(data)
        
        return(data)
      }
    )
  )