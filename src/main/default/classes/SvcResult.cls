global class SvcResult
{
    public Boolean IsSuccess {get;set;}
    public String Result {get;set;}
    public String Message {get; set;}
    
    global SvcResult(){}
    
    public SvcResult(Boolean success, String r, String m)
    {
        IsSuccess = success;
        Result = r;
        Message = m;        
    }
}