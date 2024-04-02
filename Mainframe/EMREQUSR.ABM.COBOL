       Identification Division.                                                 
       Program-Id. NUREQUSR.                                                    
                                                                                
       Environment Division.                                                    
       Input-Output Section.                                                    
       File-Control.                                                            
           Select Merged-Ulist Assign To MRGFILE                                
           Organization Is Line Sequential                                      
           Access is Sequential.                                                
           Select New-Ulist Assign To DISPLAY                                   
           Organization Is Line Sequential                                      
           Access is Sequential.                                                
                                                                                
      DATA DIVISION.                                                            
      File Section.                                                             
       FD Merged-Ulist                                                          
           Label Records Are Standard.                                          
        01 Merged-Ulist-Rec.                                                    
          02 M-ACTION          PIC X.                                           
          02 M-ADS-ID          PIC X(64).                                       
          02 FILLER            PIC X.                                           
          02 M-RACF-ID         PIC X(8).                                        
                                                                                
       FD New-Ulist                                                             
           Label Records Are Standard.                                          
        01 New-Ulist-Rec.                                                       
          02 N-ACTION          PIC X value spaces.                              
          02 N-ADS-ID          PIC X(64).                                       
          02 N-FILLER          PIC X value spaces.                              
          02 N-RACF-ID         PIC X(8).                                        
                                                                                
      WORKING-STORAGE Section.                                                  
      01 Buffer-Ulist-Rec.                                                      
          02 B-ACTION          PIC X value spaces.                              
          02 B-ADS-ID          PIC X(64) value spaces.                          
          02 FILLER            PIC X value spaces.                              
          02 B-RACF-ID         PIC X(8) value spaces.                           
      77 EOF-Ulist-Recs        PIC X value 'N'.                                 
                                                                                
      PROCEDURE DIVISION.                                                       
       Main-Para.                                                               
           Perform Open-Para                                                    
           Perform Process-Para Until EOF-Ulist-Recs = 'Y'                      
           Perform End-Para                                                     
           Stop Run.                                                            
                                                                                
       Open-Para.                                                               
           Open  Input Merged-Ulist                                             
                 Output New-Ulist                                               
           Read Merged-Ulist At End Move 'Y' To EOF-Ulist-Recs.                 
           perform Copy-to-Buffer.                                              
                                                                                
       Process-Para.                                                            
           Read Merged-Ulist At End Move 'Y' To EOF-Ulist-Recs.                 
           if B-ADS-ID is EQUAL M-ADS-ID  
               if M-ACTION = 'D'                                                 
                  if EOF-Ulist-Recs not equal 'Y'                                
                     Read Merged-Ulist At End Move 'Y' To EOF-Ulist-Recs         
                  end-if                                                         
                  perform Copy-to-Buffer                                         
               Else if M-action = 'C'                                            
                  perform Copy-to-Output                                         
                  write New-Ulist-Rec                                            
                  if EOF-Ulist-Recs not equal 'Y'                                
                     Read Merged-Ulist At End Move 'Y' To EOF-Ulist-Recs         
                  end-if                                                         
                  perform Copy-to-Buffer                                         
                  Move spaces to New-Ulist-Rec                                   
               End-IF                                                            
           else                                                                  
              if M-ADS-ID not equal  B-ADS-ID                                    
                if M-ACTION equal spaces                                         
                    perform Copy-to-Output                                       
                    move B-ADS-ID to N-ADS-ID                                    
                    move B-RACF-ID to N-RACF-ID                                  
                    write New-Ulist-Rec                                          
                    perform Copy-to-Buffer                                       
                    Move spaces to New-Ulist-Rec                                 
                 else if M-ACTION = 'A'                                          
                    perform Copy-to-Output                                       
                    write New-Ulist-Rec                                          
                    if EOF-Ulist-Recs not equal 'Y'                              
                       Read Merged-Ulist At End Move 'Y' To EOF-Ulist-Recs       
                    end-if                                                       
                    perform Copy-to-Buffer                                       
                    move spaces to New-Ulist-Rec                                 
                 end-if                                                          
              end-if                                                             
           end-if.                                                               
                                                                                 
       Copy-to-Buffer.                                                           
           move M-ACTION to B-ACTION                                             
           move M-ADS-ID to B-ADS-ID                                             
           move M-RACF-ID to B-RACF-ID.                                          
                                                                                 
       Copy-to-Output.                                                           
           move spaces to N-ACTION                                               
           move spaces to N-FILLER                                               
           move B-ADS-ID to N-ADS-ID                                             
           move B-RACF-ID to N-RACF-ID.                                          
                                                                                 
       End-Para.                                                                 
           if M-ACTION = spaces                                                  
               move M-ADS-ID to N-ADS-ID                                         
               move M-RACF-ID to N-RACF-ID                                       
               write New-Ulist-Rec                                               
           else if M-ACTION = 'A'                                                
               move M-ADS-ID to N-ADS-ID                                         
               move M-RACF-ID to N-RACF-ID                                       
               write New-Ulist-Rec                                               
           end-if                                                                
           Close Merged-Ulist New-Ulist.                                         

        EXIT PROGRAM.