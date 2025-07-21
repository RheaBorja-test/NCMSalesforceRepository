@isTest
private class PopulateOppProdRevFields_Test {

    @isTest
    static void myUnitTest() {
        Database.executeBatch(new PopulateOppProdRevFields());
    }
}