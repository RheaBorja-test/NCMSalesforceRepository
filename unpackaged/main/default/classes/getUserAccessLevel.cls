public class getUserAccessLevel {
  public class Vars {
    @InvocableVariable(label='Record ID' Required=true)
    public Id recId;
    @InvocableVariable(label='User Id' Required=true)
    public id userId;
  }

  @InvocableMethod
  public static list<UserRecordAccess> getUserAccess(List<Vars> vars) {
    list<UserRecordAccess> maxAccessLevels = new List<UserRecordAccess>();

    for (Vars var : vars) {
      UserRecordAccess usrAcc = [
        SELECT RecordId, MaxAccessLevel
        FROM UserRecordAccess
        WHERE UserId = :var.userId AND RecordId = :var.recId
      ];
      maxAccessLevels.add(usrAcc);
    }

    return maxAccessLevels;
  }
}