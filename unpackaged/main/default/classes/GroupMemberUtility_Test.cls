@isTest
private class GroupMemberUtility_Test {

    @testSetup
    static void makeData() { 
        SampleDataFactory.createPropAnd20GroupData();
    }

    @isTest
    static void myUnitTest() {
        Id a = [SELECT Id FROM Account LIMIT 1].Id;
        List<String> alsos = GroupMemberUtility.getAlso(new List<Id>{a});
        Assert.areEqual('2001-01 null\n8888-10 null', alsos[0]);
    }
}