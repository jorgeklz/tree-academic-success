######################################################################################################################
# How Predicting The Academic Success of Studentsof the ESPAM MFL?: A Preliminary DecisionTrees Based Study
# J.Parraga-Alava and Jessica Morales.
# IEEE Ecuador Technical Chapter Meeting (ETCM) 2018
# code by jorgeklz (jparraga@outlook.cl)
######################################################################################################################

dt=read.table("data.csv", header = TRUE, sep=",") 

lista_A<-list()
lista_B<-list()
lista_C<-list()
accuracy_A<-vector()
precision_A<-vector()
recall_A<-vector()
accuracy_B<-vector()
precision_B<-vector()
recall_B<-vector()
accuracy_C<-vector()
precision_C<-vector()
recall_C<-vector()

arboles<-list()
arboles_poda=list()


set.seed(1234)

#Runs

  for(i in 1:20){
      #--------- Split Train and Test Data

      rn = sample(1:nrow(dt), 0.70*nrow(dt))
      dt_train = dt[rn,]
      dt_test = dt[-rn,]
       
      #--------- Model c5.0
      library(C50)
      library(printr)
      modeloA<-C5.0(Class ~., data=dt_train)
      confusion_A=table(predict(object=modeloA, newdata=dt_test, type="class"), dt_test$Class)
      #Save Confusion Matrix
      lista_A[[i]]=confusion_A
      #Compute and Save Metrics
      accuracy_A[i]=sum(diag(confusion_A)) / sum(confusion_A)
      precision_A[i]=mean(diag(confusion_A) / rowSums(confusion_A))
      recall_A[i]=mean(diag(confusion_A) / colSums(confusion_A))
      
      #--------- Model Random Forest
      library(party)
      modeloB=party::cforest(Class~., data = dt_train)
      dt_test$predClass = predict(modeloB, newdata=dt_test, type="response")
      dt_test$predProb = sapply(predict(modeloB, newdata=dt_test,type="prob"),'[[',2)
      confusion_B=table(dt_test$predClass, dt_test$Class)
      #Save Confusion Matrix
      lista_B[[i]]=confusion_B
      #Compute and Save Metrics
      accuracy_B[i]=sum(diag(confusion_B)) / sum(confusion_B)
      precision_B[i]=mean(diag(confusion_B) / rowSums(confusion_B))
      recall_B[i]=mean(diag(confusion_B) / colSums(confusion_B))
      
      #--------- Model CART
      library(rpart)
      library(rpart.plot)
      modeloC <- rpart(Class ~ ., data = dt_train, control = rpart.control(cp = 0.0001))
      bestcp <- modeloC$cptable[which.min(modeloC$cptable[,"xerror"]),"CP"]
      tree.pruned <- prune(modeloC, cp = bestcp)
      confusion_C <- table(dt_train$Class, predict(tree.pruned,type="class"))
      #Save Confusion Matrix
      lista_C[[i]]=confusion_C
      #Compute and Save Metrics
      accuracy_C[i]=sum(diag(confusion_C)) / sum(confusion_C)
      precision_C[i]=mean(diag(confusion_C) / rowSums(confusion_C))
      recall_C[i]=mean(diag(confusion_C) / colSums(confusion_C))
     
      #Save Tree Object of Model CART
      arboles_poda[[i]]=tree.pruned
      arboles[[i]]=modeloC
      
  }



    #Function to delete Na produced.
    delete.na <- function(DF, n=0) {
      DF[rowSums(is.na(DF)) <= n,]
    }
    
    
      resultados_accuracy=as.data.frame(cbind(C5.0=accuracy_A, RandomForest=accuracy_B, CART=accuracy_C))
      #delete NAs
      resultados_accuracy=delete.na(resultados_accuracy)
      
      resultados_precision=as.data.frame(cbind(C5.0=precision_A, RandomForest=precision_B, CART=precision_C))
      #delete NAs
      resultados_precision=delete.na(resultados_precision)
      
      resultados_recall=as.data.frame(cbind(C5.0=recall_A, RandomForest=recall_B, CART=recall_C))
      #delete NAs
      resultados_recall=delete.na(resultados_recall)

  
    #Compute Statistical for paper
    #accuracy
    min=apply(resultados_accuracy, 2, min)
    max=apply(resultados_accuracy, 2, max)
    mean=apply(resultados_accuracy, 2, mean)
    sd=apply(resultados_accuracy, 2, sd)
    accuracy=as.data.frame(t(rbind(min,max,mean, sd)))
    #precision
    min=apply(resultados_precision, 2, min)
    max=apply(resultados_precision, 2, max)
    mean=apply(resultados_precision, 2, mean)
    sd=apply(resultados_precision, 2, sd)
    precision=as.data.frame(t(rbind(min,max,mean, sd)))
    #recall
    min=apply(resultados_recall, 2, min)
    max=apply(resultados_recall, 2, max)
    mean=apply(resultados_recall, 2, mean)
    sd=apply(resultados_recall, 2, sd)
    recall=as.data.frame(t(rbind(min,max,mean, sd)))


    table_latex=apply(cbind(accuracy, precision, recall),2, function(x) round(x,4))
    
    
    #Statistical Testes
    library("PMCMR")

    #------ Accuracy
    db_accuracy<-as.data.frame(rbind(cbind(resultados_accuracy[,"C5.0"], rep("C5.0",nrow(resultados_accuracy))),
                                    cbind(resultados_accuracy[,"RandomForest"], rep("RandomForest",nrow(resultados_accuracy))),
                                    cbind(resultados_accuracy[,"CART"], rep("CART",nrow(resultados_accuracy)))))
    #Test global
    kruskal.test(db_accuracy[,1], db_accuracy[,2]) 
    #Test pairwise
    posthoc.kruskal.nemenyi.test(V1  ~ V2, data = db_accuracy)

    
    #------ Precision
    db_precision<-as.data.frame(rbind(cbind(resultados_precision[,"C5.0"], rep("C5.0",nrow(resultados_precision))),
                                      cbind(resultados_precision[,"RandomForest"], rep("RandomForest",nrow(resultados_precision))),
                                cbind(resultados_precision[,"CART"], rep("CART",nrow(resultados_precision)))))
    #Test global
    kruskal.test(db_precision[,1], db_precision[,2]) 
    #Test pairwise
    posthoc.kruskal.nemenyi.test(V1  ~ V2, data = db_precision)


    #------ Recall
    db_recall<-as.data.frame(rbind(cbind(resultados_recall[,"C5.0"], rep("C5.0",nrow(resultados_recall))),
                              cbind(resultados_recall[,"RandomForest"], rep("RandomForest",nrow(resultados_recall))),
                              cbind(resultados_recall[,"CART"], rep("CART",nrow(resultados_recall)))))
    #Test global
    kruskal.test(db_recall[,1], db_recall[,2]) 
    #Test pairwise
    posthoc.kruskal.nemenyi.test(V1  ~ V2, data = db_recall)

