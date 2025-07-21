@isTest(SeeAllData = true)
public class createCollectionActivityTest
{
	public static testMethod void TestcreateCollectionActivity()
	{
		Test.startTest();
        user u = 
		[
			SELECT Id
			FROM User
			WHERE 
				IsActive = true AND 
				Id IN 
				(
					SELECT UserId
					FROM UserPackageLicense
					WHERE PackageLicense.NamespacePrefix = 'c2g'
				) AND 
				Id IN 
				(
					SELECT c2g__User__c
					FROM c2g__codaUserCompany__c
				)
			ORDER BY LastName DESC
			LIMIT 1
		];

		System.runAs(u){
			Try{
				Client_Support_Ticket__c clientCase = 
				[
					SELECT Id
					FROM Client_Support_Ticket__c
					WHERE 
						Status__c = 'Open' AND 
						RecordTypeId = '0124A000001NTPoQAO'
					LIMIT 1
				];
				Database.delete( clientCase );
			} Catch (exception er){
				system.debug(er);
			}

			createCollectionActivity testSche = new createCollectionActivity(  );
			testSche.execute(null);

		}
		test.stopTest();
	}
}