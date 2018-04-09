public class LayoutDescribe
{

	public class RecordTypeLayout
	{
		public List<EditLayoutSection> editLayoutSections {get;set;}

		public List<FieldInfo> getFieldInfo()
		{
			List<FieldInfo> results = new List<FieldInfo>();
			for(EditLayoutSection s : editLayoutSections)
			{
				results.addAll(s.getFieldInfo());
			}
			return results;
		}			

	}
	public class EditLayoutSection
	{
		public Integer columns {get;set;}
		public Integer rows {get;set;}
		public String heading {get;set;}
		public Boolean useHeading {get; set;}
		public List<LayoutRow> layoutRows {get;set;}
		public List<FieldInfo> Fields 
		{
			get { return getFieldInfo(); }
		}

		public List<FieldInfo> getFieldInfo()
		{
			List<FieldInfo> results = new List<FieldInfo>();
			if(layoutRows!=null)			
			{
				for(LayoutRow r : layoutRows)
				{
					results.addAll(r.getFieldInfo(this.heading));
				}
			}
			return results;
		}

	}

	public class LayoutRow
	{
		public List<LayoutItem> layoutItems {get;set;}
		List<FieldInfo> getFieldInfo(String heading)
		{
			List<FieldInfo> results = new List<FieldInfo>();
			for(LayoutItem o : layoutItems)
			{
				if(String.isBlank(o.label)) continue;
				FieldInfo f = new FieldInfo(o);
				f.heading = heading;
				results.add(f);
			}
			return results;
		}
	}
	public class LayoutItem
	{
		public String label {get;set;}
		public Boolean placeHolder {get;set;}
		public Boolean required {get;set;}
		public Boolean editableForNew {get;set;}
		public Boolean editableForUpdate {get;set;}
		public List<LayoutComponent> layoutComponents {get;set;}

	}

	public class LayoutComponent
	{
		public Integer displayLines {get;set;}
		public String type {get;set;}
		public String value {get;set;}
		public LayoutComponentDetail details {get;set;}
	}

	public class LayoutComponentDetail
	{
		public Boolean autoNumber {get;set;}
		public String inlineHelpText {get;set;}
		public String label {get;set;}
		public String name {get;set;}
		public Boolean nameField {get;set;}
	}

	public class FieldInfo
	{
		public FieldInfo(){}
		public FieldInfo(LayoutItem c)
		{
			this.label = c.label;
			this.required = c.required;
			this.editableForNew  = c.editableForNew;
			this.editableForUpdate = c.editableForUpdate;

			if(c.layoutComponents!=null && !c.layoutComponents.isEmpty())
			{
				LayoutComponent lc = c.layoutComponents.get(0);
				this.autoNumber = lc.details.autoNumber;
				this.fieldName = lc.details.name;
				this.inlineHelpText = lc.details.inlineHelpText;				
			}

		}
		public String label {get;set;}
		public String fieldName {get;set;}
		public String inlineHelpText {get;set;}
		public Boolean required {get;set;}
		public Boolean editableForNew {get;set;}
		public Boolean editableForUpdate {get;set;}
		public Boolean autoNumber {get;set;}
		public String heading {get;set;}

	}
	
	public static List<EditLayoutSection> GetEditLayoutSectionTestData(String sobjType)
	{
		List<EditLayoutSection> sections = new List<EditLayoutSection>();
		EditLayoutSection s = new EditLayoutSection();
		s.heading = 'Test Data';
		sections.add(s);
		return sections;
	}
	
	public static List<FieldInfo> GetFieldInfoTestData(String sobjType)
	{	
		List<FieldInfo> fields = new List<FieldInfo>();
		Schema.DescribeSObjectResult dsr = Schema.getGlobalDescribe().get(sobjType).getDescribe();
		for(Schema.SObjectField f : dsr.fields.getMap().values())
		{
			Schema.DescribeFieldResult  dsf = f.getDescribe();
			if(!dsf.isAccessible() || !dsf.isCustom() || dsf.isAutoNumber() || dsf.isCalculated()) continue;
			FieldInfo fi = new FieldInfo();
			fi.label = dsf.getLabel();
			fi.fieldName = dsf.getName();
			fi.editableForNew = dsf.isCreateable();
			fi.editableForUpdate = dsf.isUpdateable();
			fi.autoNumber = dsf.isAutoNumber();
			fi.required = false;
			fi.inlineHelpText = '';
			fields.add(fi);
		}
		return fields;
	}
}