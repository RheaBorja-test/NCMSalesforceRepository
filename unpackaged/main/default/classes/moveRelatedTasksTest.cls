@isTest(SeeAllData=true)
public class moveRelatedTasksTest {
  public static testMethod void TestMoveRelatedTasks() {
    List<Task> tsks = [SELECT WhatId FROM Task LIMIT 200];

    Test.startTest();
    list<moveRelatedTasks.vars> vars = new List<moveRelatedTasks.vars>();
    moveRelatedTasks.vars var = new moveRelatedTasks.vars();
    var.recId = tsks.get(0).WhatId;
    list<id> ids = new List<id>();
    for (Task tsk : tsks) {
      if (tsk.WhatId != var.recId) {
        ids.add(tsk.whatId);
      }
    }
    var.oldRelIds = ids;
    vars.add(var);
    moveRelatedTasks.moveTasks(vars);
    Test.stopTest();
  }
}