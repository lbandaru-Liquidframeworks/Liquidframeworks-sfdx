public class QueueableAdapter implements Queueable
{ 
    String batchableClassName {get;set;}
    Map<String,Object> batchableParams {get; set;}
    
    public QueueableAdapter(String batchableName, Map<String, Object> params)
    {
        batchableClassName = batchableName;
        batchableParams = params;
    }
    
    public void execute(QueueableContext context)
    {   
        Type t = Type.forName(batchableClassName);
        FXBatchableBase b = (FXBatchableBase)t.newInstance(); 
        b.SetParams(batchableParams);
        Database.executeBatch(b);   
    }
}