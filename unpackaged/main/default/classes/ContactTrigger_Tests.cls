@isTest 
public class ContactTrigger_Tests {
    
    @testSetup
    static void makeData(){
        
        String contactRecType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business Development Contact').getRecordTypeId();
        Contact testContact = new Contact(
            FirstName = 'Joe', 
            LastName='Simpson', 
            Email='joe.simpson@here.com',
            RecordTypeId = contactRecType  
        );
        insert(testContact);
        System.debug('testContact.Id: ' + testContact.id);
		
    }
    
    @isTest
    public static void mktoUpdateContactNameTest() {

        User mktoUser = [select Id, Name from User WHERE FirstName = 'Marketo' and LastName = 'Sync'];
        System.debug('Marketo Sync User Id: ' + mktoUser.Id);
        
		Profile powerUserProfile = [select id from profile where name = 'NCM Power Users'];
		mktoUser.ProfileId = powerUserProfile.Id;
		update(mktoUser);        
        
        Contact testContact = [SELECT Id, FirstName, LastName, Email FROM Contact WHERE RecordType.Name = 'Business Development Contact' LIMIT 1];
        
        Test.startTest();
        System.runAs(mktoUser){
            testContact.FirstName = 'joeseph';
            testContact.LastName = 'simpson2';
            testContact.Email = 'jsimpson@noemail.com';
            update(testContact);
        }
        Test.stopTest();

        Contact testResult = [SELECT Name, Email FROM Contact WHERE Id = :testContact.Id];
        Assert.areEqual('Joe Simpson', testResult.Name); // Marketo shouldn't be allowed to change first + last name.
        Assert.areEqual('jsimpson@noemail.com', testResult.Email); // Marketo should be able to change email.

    }
}