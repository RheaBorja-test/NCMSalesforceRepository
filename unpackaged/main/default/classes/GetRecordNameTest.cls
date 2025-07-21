@isTest(SeeAllData=true)
public class GetRecordNameTest
{
    @isTest
    static void testRecordName()
    {
        User u = [SELECT Id
                  FROM User
                  WHERE IsActive = true AND Profile.Name = 'System Administrator'
                  LIMIT 1];

        System.runAs(u)
        {


            Account acc = [ SELECT Id, Name FROM Account LIMIT 1 ];

            List<Id> recIds = new List<Id>();
            recIds.add(acc.Id);

            test.startTest();
            List<String> recNames = GetRecordName.getRecordNameById(recIds);
            test.stopTest();

            String recName = recNames.get(0);
            System.assertEquals(acc.Name, recName, 'Account Name not Returned');
        }
    }

}