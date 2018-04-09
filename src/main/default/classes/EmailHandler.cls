public class EmailHandler
{
    public static void SendEmail(String msg, String subject, String userId)
    {
        try {
             List<User> users = [Select Id, Email from User where Id =:userId];

            String sendTo = (!users.isEmpty() && !String.isBlank(users.get(0).Email))?
                users.get(0).Email : 'rluo@liquidframeworks.com';          

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            String[] toAddresses = new String[] {sendTo};
            mail.setToAddresses(toAddresses);
            mail.setSubject(subject);

            mail.setHtmlBody(msg);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
        }
        catch (Exception e) {
            
        } 
    }


    public static void SendEmail(String msg, String subject)
    {
        SendEmail(msg, subject, UserInfo.getUserId());      
    }
}