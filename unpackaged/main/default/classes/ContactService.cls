public class ContactService {
    public static void preventMktoUpdates(List<Contact> newList, Map<Id,Contact> oldMap) {

        if(oldMap == null){
            System.debug('No updates (oldMap is null). Exiting.');
            return;
        }

        if(UserInfo.getUserName().containsIgnoreCase('marketo@ncmassociates.com')){
            System.debug('Marketo User updating Contacts');
            for(Contact ct:newList){
                Contact oldCt = oldMap.get(ct.Id);
                if(
                    ct.FirstName != oldCt.FirstName ||
                    ct.LastName != oldCt.Lastname
                ){
                    System.debug('Restricted field updated by Marketo, reversing change.');
                    ct.FirstName = oldCt.FirstName;
                    ct.LastName = oldCt.LastName;
                }
            }
        } else {
            System.debug('Non-Marketo user updating contacts. Exiting..');
            return;
        }
    }
}