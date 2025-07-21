@isTest(SeeAllData = true)
public with sharing class FollowersControllerTest
{
	public static testMethod void FollowersControllerTest()
	{
		Test.startTest();
		Id accId = [SELECT Id
		            FROM Account
		            LIMIT 1].Id;
		FollowersController.getFollowers(accId);
		Test.stopTest();
	}
}