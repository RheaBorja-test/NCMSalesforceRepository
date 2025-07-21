public with sharing class moveRelatedTasks {
  public class vars {
    @InvocableVariable(label='New Related Id' Required=true)
    public Id recId;
    @InvocableVariable(label='Related Ids to Reparent' Required=true)
    public list<id> oldRelIds;
  }

  @InvocableMethod
  public static void moveTasks(List<vars> vars) {
    list<Task> updTasks = new List<Task>();
    for (vars var : vars) {
      list<Task> tasks = [SELECT id FROM Task WHERE WhatId IN :var.oldRelIds];
      if (tasks.size() > 0) {
        for (Task tsk : tasks) {
          tsk.WhatId = var.recId;
          updTasks.add(tsk);
        }
      }
    }

    if (updTasks.size() > 0) {
      update updTasks;
    }
  }
}