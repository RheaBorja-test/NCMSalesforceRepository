@isTest(SeeAllData = true)
public class billingProductDailyTest{
	public static testMethod void testBilling(){
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
		system.runas(u){
			List<String> fieldNames = new List<String>(Billing_Product__c.getSObjectType().getDescribe().fields.getMap().keySet());
			String query = ' SELECT ' + String.join(fieldNames, ', ') + ' FROM Billing_Product__c WHERE Dimension_1__r.Name like \'8000-axcessa\' and Dimension_2__c != null limit 1';
			Billing_Product__c bProd = Database.query(query);
			bProd.Billing_Product_Status__c = 'Active';
			bProd.Next_Billing_Date__c = date.today().addDays( - 1);
			list<Billing_Product__c> bProds = new list<Billing_Product__c>();
			bProds.add(bProd);
			bProd = bProd.clone();
			bProd.axcessa_Platform_Engagement__c = 
			[
				SELECT Id
				FROM axcessa_Platform_Engagement__c 
				WHERE Store_Status__c = 'Active'
				LIMIT 1
			].id;
			bProds.add(bProd);
			bProd = bProd.clone();
			bProd.Dimension_2__c = 
			[
				SELECT Id
				FROM c2g__codaDimension2__c 
				WHERE name like '%Stephen Clark%'
				LIMIT 1
			].id;
			bProds.add(bProd);
			upsert bProds;
			Billing_Account__c bAcc = 
			[
				SELECT id
				FROM Billing_Account__c 
				WHERE id = :bProd.Billing_Account__c
			];
			bAcc.Status__c = 'Validated';
			try{
				update bAcc;
			} catch (exception er){
				bAcc.Primary_Contact__c = 
				[
					SELECT Id
					FROM Contact 
					WHERE Name LIKE 'Stephen Clark'
					LIMIT 1
				].Id;
				update bAcc;
			}
			Billing_Configuration__c bConfig = new Billing_Configuration__c();
			bConfig.Dimension_1__c = 
			[
				SELECT id
				FROM c2g__codaDimension1__c 
				WHERE Name LIKE '8000-axcessa'
				LIMIT 1
			].id;
			bConfig.Split_on_Dim_2__c = true;
			bConfig.Split_on_CEM__c = true;
			bConfig.One_Time_Run__c = true;
			bConfig.Recurring_Day__c = date.today().day();
			bConfig.Billing_Product_WHERE__c = 'WHERE Dimension_1__c = \'' + bConfig.Dimension_1__c + '\'';
			insert bConfig;
			BillingProductDaily testSche = new BillingProductDaily();
			testSche.execute(null);
		}
		Test.stopTest();
	}
}