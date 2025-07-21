public class chatterSubscribe {
    
    public class vars {
        @InvocableVariable(label='User Id' Required=true)
        public id userId;
        @InvocableVariable(label='Record Ids' Required=false)
        public List<Id> recIds;
        @InvocableVariable(label='Record Id' Required=false)
        public Id recId;
    }
    
	@InvocableMethod
    public static void addSub(List<vars> vars){
        list<EntitySubscription> ESs = new list<EntitySubscription>();
        for (vars var : vars){
            if (var.recId != null){
                List<id> ids = new List<id>();
        		ids.add(var.recId);
                var.recIds = ids;
            }
            
            for (id recId : var.recIds){
                EntitySubscription es = new EntitySubscription();
                
                es.ParentId = recId;
                es.SubscriberId = var.userId;
                
                list<EntitySubscription> existingESs = [select id, SubscriberId from EntitySubscription where ParentId = :recId];
                boolean doesExist = false;
                for (EntitySubscription existES : existingESs){
                    if(existES.SubscriberId == es.SubscriberId){
                        doesExist = true;
                        break;
                    }
                }
                if (!doesExist){
					ESs.add(es);   
                }
            }   
        }
        if (ESs.size() > 0){
            try {
                insert ESs;
            } catch (exception er){
                system.debug(er);
            }
        }
    }
}