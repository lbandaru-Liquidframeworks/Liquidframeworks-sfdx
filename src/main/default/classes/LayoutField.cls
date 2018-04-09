global class LayoutField
{
    global String label {get;set;}
    global String fieldName {get;set;}
    global String inlineHelpText {get;set;}
    global Boolean required {get;set;}
    global Boolean editableForNew {get;set;}
    global Boolean editableForUpdate {get;set;}
    global Boolean autoNumber {get;set;}
    global String heading {get;set;}
    
    global LayoutField(){}
    
    public LayoutField(LayoutDescribe.FieldInfo f)    
    {
        this.label = f.label;        
        this.fieldName  = f.fieldName ;
        this.inlineHelpText  = f.inlineHelpText;
        this.required  = f.required;
        this.editableForNew  = f.editableForNew;
        this.editableForUpdate  = f.editableForUpdate;
        this.autoNumber  = f.autoNumber;
        this.heading  = f.heading;
    }
}