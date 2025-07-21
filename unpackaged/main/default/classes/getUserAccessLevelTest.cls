@isTest(SeeAllData=true)
public class getUserAccessLevelTest {
  static testMethod void testGetUserAccess() {
    test.startTest();

    GetUserAccessLevel.Vars var = new GetUserAccessLevel.Vars();
    list<GetUserAccessLevel.Vars> vars = new List<GetUserAccessLevel.Vars>();

    var.userId = [SELECT Id FROM User WHERE IsActive = true LIMIT 1].Id;
    var.recId = [SELECT Id FROM Account LIMIT 1].Id;
    vars.add(var);

    GetUserAccessLevel.getUserAccess(vars);

    test.stopTest();
  }
}