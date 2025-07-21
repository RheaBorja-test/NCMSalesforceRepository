public class billingProductDaily implements Schedulable{
	public final date tDay = date.today();
	public void execute(SchedulableContext sc){
		integer dy = tDay.day();
		list<Billing_Configuration__c> bConfigs = [select id, Dimension_1__c, One_Time_Run__c, Split_on_CEM__c, Split_on_Dim_2__c, Billing_Product_WHERE__c
		                                           from Billing_Configuration__c 
		                                           where Recurring_Day__c = :dy];
		if (bConfigs != null){
			list<Billing_Configuration_Detail__c> bConfigDets = createBillConfigDets(bConfigs);
			if (bConfigDets.size() > 0 && !test.isRunningTest()){
				insert bConfigDets;
				batchAccountingBridge batchBrd = new batchAccountingBridge();
				database.executebatch(batchBrd, 1);
			}
		}
	}

	public static list<Billing_Configuration_Detail__c> createBillConfigDets(list<Billing_Configuration__c> bConfigs){
		list<Billing_Configuration_Detail__c> bConfigDets = new list<Billing_Configuration_Detail__c>();
		for (Billing_Configuration__c bConfig : bConfigs){
			string query = 'SELECT id, name, ';
			query = query + '( SELECT id, name, Dimension_1__c, Dimension_2__c, CEM_Id__c ';
			query = query + 'FROM Billing_Account__c.Billing_Products__r ';
			query = query + bConfig.Billing_Product_WHERE__c + ') ';
			query = query + 'FROM Billing_Account__c ';
			query = query + 'WHERE Status__c = \'Validated\' AND Id IN ';
			query = query + '(SELECT Billing_Account__c ';
			query = query + 'FROM Billing_Product__c ';
			query = query + bConfig.Billing_Product_WHERE__c + ')';
			list<Billing_Account__c> bAccs = Database.query(query);
			for (Billing_Account__c bAcc : bAccs){
				id dim2;
				id cemId;
				Billing_Configuration_Detail__c bConfigDet = crtDet(bConfig, bAcc.id);
				for (Billing_Product__c bProd : bAcc.Billing_Products__r){
					if (bConfig.Split_on_Dim_2__c || bConfig.Split_on_CEM__c){
						if (dim2 == null){
							dim2 = bProd.Dimension_2__c;
							cemId = bProd.CEM_Id__c;
						}
						if ((dim2 != bProd.Dimension_2__c && bConfig.Split_on_Dim_2__c) || (cemId != bProd.CEM_Id__c && bConfig.Split_on_CEM__c)){
							if (bConfig.Split_on_Dim_2__c){
								bConfigDet.Dimension_2__c = dim2;
							}
							if (bConfig.Split_on_CEM__c){
								bConfigDet.CEM_Id__c = cemId;
							}
							bConfigDets.add(bConfigDet);
							bConfigDet = crtDet(bConfig, bAcc.id);
							dim2 = bProd.Dimension_2__c;
							cemId = bProd.CEM_Id__c;
						}
					}


					if (!bConfig.Split_on_Dim_2__c && !bConfig.Split_on_CEM__c){
						break;
					}
				}
				if (!bConfig.Split_on_Dim_2__c && !bConfig.Split_on_CEM__c){
					bConfigDets.add(bConfigDet);
				}
			}
		}
		return bConfigDets;
	}

	private static Billing_Configuration_Detail__c crtDet(Billing_Configuration__c bConfig, id bAccId){
		Billing_Configuration_Detail__c det = new Billing_Configuration_Detail__c();
		det.Billing_Configuration__c = bConfig.id;
		det.Billing_Account__c = bAccId;
		return det;
	}
}