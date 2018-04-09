global class LayoutSection
{
    global LayoutSection() {}
    public LayoutSection(LayoutDescribe.EditLayoutSection s)
    {
        heading = s.heading;
        useHeading = s.useHeading;
        columns = s.columns;
        fields = new List<LayoutField>();
        for(LayoutDescribe.FieldInfo f : s.fields)
        {
            fields.add(new LayoutField(f));
        }
    }
    
    global String heading {get;set;}
    global Boolean useHeading {get; set;}
    global Integer columns {get;set;}
    global List<LayoutField> fields {get;set;}
    
    
    
}