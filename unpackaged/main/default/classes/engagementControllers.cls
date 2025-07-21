public class engagementControllers {
    
    public class vars {
        @InvocableVariable(label='Engagement' Required=true)
        public Engagement__c eng;
        @InvocableVariable(label='Member Count')
        public Integer memCnt;
    }
    
    @InvocableMethod
    public static list<list<Room__c>> getRooms(List<vars> vars){
        list<list<Room__c>> roomsRet = new list<list<Room__c>>();
        
        for(vars var : vars){
            list<Room__c> delRms = new list<Room__c>();
            list<Room__c> rms = [select id, Room_Date__c, Meeting_Day__c, Day_of_Week__c, ADA_Rooms__c, NCM_On_Site__c, Premium_Rooms__c, Run_of_House__c
                                    from Room__c 
                                    where Engagement__c = :var.eng.id
                                    order by Room_Date__c
                                ];
            
            integer lngth = var.eng.Rooms_From__c.daysBetween(var.eng.Rooms_To__c);
            for(integer i = 0; i <= lngth; i++){
                date currentDate = var.eng.Rooms_From__c.addDays(i);

                boolean alreadyExists = false;

                boolean meetingDay = false;
                if(currentDate >= var.eng.Engagement_Start_Date__c && currentDate <= var.eng.Engagement_End_Date__c){
                    meetingDay = true;
                }

                boolean ncmOnSite = false;
                if(currentDate >= var.eng.NCM_Arrival__c && currentDate < var.eng.NCM_Departure__c){
                    ncmOnSite = true;
                }

                if(rms.size() > 0){
                    for (Room__c rm : rms){
                        if (rm.Room_Date__c == currentDate){
                            alreadyExists = true;
                            if(meetingDay && !rm.Meeting_Day__c){
                                rm.Meeting_Day__c = true;
                            }
                            if(ncmOnSite && rm.NCM_On_Site__c < 1){
                                rm.NCM_On_Site__c = 1;
                            }
                            break;
                        }
                        if(rm.Room_Date__c > currentDate){
                            break;
                        }
                    }
                }

                if(!alreadyExists){
                    Room__c rm = new Room__c();

                    rm.Engagement__c = var.eng.Id;
                    rm.Room_Date__c = currentDate;
                    rm.ADA_Rooms__c = 0;
                    rm.Premium_Rooms__c = 0;

                    if (var.memCnt > 0){
                        rm.Run_of_House__c = var.memCnt;
                    } else{
                        rm.Run_of_House__c = 0;
                    }
                    if(meetingDay){
                        rm.Meeting_Day__c = true;
                    }
                    if(ncmOnSite){
                        rm.NCM_On_Site__c = 1;
                    } else{
                        rm.NCM_On_Site__c = 0;
                    }

                    rms.add(rm);
                }
            }

            upsert rms;

            for (Room__c rm : rms){
                if(rm.Room_Date__c < var.eng.Rooms_From__c || rm.Room_Date__c > var.eng.Rooms_To__c){
                    delRms.add(rm);
                }
            }
            if(delRms.size() > 0){
                delete delRms;
            }

            rms = [select id, Room_Date__c, Meeting_Day__c, Day_of_Week__c, ADA_Rooms__c, NCM_On_Site__c, Premium_Rooms__c, Run_of_House__c
                        from Room__c 
                        where Engagement__c = :var.eng.id
                        order by Room_Date__c
                    ];
            
            roomsRet.add(rms);
        }
        
        return roomsRet;
    }

    @AuraEnabled
    public static void updateRooms(List<Room__c> rms){
        update rms;
    }

    @AuraEnabled
    public static List<Room__c> getRoomsForEngagement(id engId){
        List<Room__c> rms = [select id, Room_Date__c, Meeting_Day__c, Day_of_Week__c, ADA_Rooms__c, NCM_On_Site__c, Premium_Rooms__c, Run_of_House__c 
            from Room__c 
            where Engagement__c = :engId 
            order by Room_Date__c];
            
        return rms;
    }

    @AuraEnabled
    public static list<Activity_Participation__c> getAttendeeParticipation(id attId){
        list<Activity_Participation__c> ptcs = new list<Activity_Participation__c>();
        Engagement_Attendee__c att = [select id, Engagement__c, 
                                            (select id, Engagement_Activity__c, Engagement_Activity__r.name, Total_Number_of_Participants__c 
                                                from Activity_Participation__r
                                            ) 
                                        from Engagement_Attendee__c 
                                        where id = :attId];

        list<Engagement_Activity__c> acts = [select id, name from Engagement_Activity__c where Engagement__c = :att.Engagement__c order by Start__c desc];
        for(Engagement_Activity__c act : acts){

            boolean needsPtc = true;
            for (Activity_Participation__c ptc : att.Activity_Participation__r){
                if (ptc.Engagement_Activity__c == act.id){
                    needsPtc = false;
                    ptcs.add(ptc);
                    break;
                }
            }

            if(needsPtc){
                Activity_Participation__c ptc = new Activity_Participation__c();
                ptc.Engagement_Activity__c = act.id;
                ptc.Engagement_Attendee__c = att.id;
                ptc.Total_Number_of_Participants__c = 0;
                ptcs.add(ptc);
            }
        }

        upsert ptcs;
        ptcs = [select id, Engagement_Activity__c, Engagement_Activity__r.name, Total_Number_of_Participants__c 
                from Activity_Participation__c 
                where Engagement_Attendee__c = :att.id
                order by Engagement_Activity__r.name];

        return ptcs;
    }

    @AuraEnabled
    public static list<Activity_Participation__c> getActivityParticipation(id actId){
        list<Activity_Participation__c> ptcs = [select id, Total_Number_of_Participants__c, Engagement_Attendee__r.Name
                                                from Activity_Participation__c 
                                                where Engagement_Activity__c = :actId
                                                order by Engagement_Attendee__r.Name];

        return ptcs;
    }

    @AuraEnabled
    public static void upsertParticipation(list<Activity_Participation__c> ptcs){
        list<Activity_Participation__c> delPtcs = new list<Activity_Participation__c>();
        for (integer i = 0; i < ptcs.size(); i){
            boolean remove = true;
            Activity_Participation__c ptc = ptcs.get(i);
            if (ptc.Total_Number_of_Participants__c > 0){
                remove = false;
            }

            if(remove){
                ptcs.remove(i);

                if(ptc.id != null){
                    delPtcs.add(ptc);
                }
            } else{
                i++;
            }
        }

        database.upsert(ptcs, false);

        if(delPtcs.size() > 0){
            database.delete(delPtcs, false);
        }
    }

}