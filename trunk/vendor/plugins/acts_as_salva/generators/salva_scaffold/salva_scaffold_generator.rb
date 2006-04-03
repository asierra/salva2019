class ScaffoldingSandbox
  attr_accessor :form_action, :singular_name, :suffix, :model_instance
  def sandbox_binding
    binding
  end
  
  def set_label(column, required=nil)
    if required then 
      "<label for=\"#{column}\" class=\"label\"><%= get_label('#{column}') %> <span class=\"required\">*</span></label> \n"      
    else
      "<label for=\"#{column}\" class=\"label\"><%= get_label('#{column}') %></label> \n"
    end
  end

  def set_textfield(column, tabindex, required=nil)
    if required then
      "<%= text_field 'edit', '#{column}', 'size' => 30, 'maxsize'=> 40, 'tabindex'=> #{tabindex}, 'id' => '#{column}', 'z:required' => 'true', 'z:message' => 'Este campo es requerido' %>\n"  
    else
      "<%= text_field 'edit', '#{column}', 'size' => 30, 'maxsize'=> 40, 'tabindex'=> #{tabindex}, 'id' => '#{column}' %>\n"  
    end
  end
  
  def set_textarea(column, tabindex, required=nil)
    if required then
      "<%= text_area 'edit', '#{column}', 'rows' => 4, 'cols' => 40, 'tabindex' => #{tabindex}, 'id' => '#{column}', 'z:required' => 'true', 'z:message' => 'Este campo es requerido' %>\n"  
    else
      "<%= text_area 'edit', '#{column}', 'rows' => 4, 'cols' => 40, 'tabindex' => #{tabindex}, 'id' => '#{column}' %>"
    end
  end
  
  def set_select(column, model, tabindex, prefix=nil, required=nil)
    required ? req = 1 : req = 0
    select = "<div id=\"#{column}\">\n" 
    if prefix then 
      select << "<%= table_select('edit', #{Inflector.camelize(model)}, {:prefix => '#{prefix}', :tabindex => #{tabindex}, :required => #{req} }) %>\n" 
      select << "</div>\n"
      select << "<%= quickpost('#{model.downcase}') %> \n"
    else
      select << "<div id=\"#{column}\">\n"
      select << "<%= table_select('edit', #{Inflector.camelize(model)}, {:tabindex => #{tabindex}, :required => #{req} }) %> \n" 
      select << "</div>\n"
      select << "<%= quickpost('#{model.downcase}') %> \n"
    end
    select << "</div>\n"
  end

  def set_month(column, tabindex, required=nil)
    required ? req = 1 : req = 0
    "<%= month_select('edit', '#{column}', {:tabindex => #{tabindex}, :required => #{req} }) %> \n"
  end
  
  def set_year(column, tabindex, required=nil)
    required ? req = 1 : req = 0
    "<%= year_select('edit', '#{column}', {:tabindex => #{tabindex}, :required => #{req} }) %> \n"
  end
  
  def salva_tags (model_instance, singular_name)
    table_name =  Inflector.tableize(model_instance.class.name)
    attrs = model_instance.connection.columns(table_name)
    hidden = %w( id moduser_id user_id dbtime updated_on created_on)
    html = ""
    tabindex = 1
    attrs.each { | attr | 
      column = attr.name
      next if hidden.include? column
      html << "<div class=\"row\"> \n"
      model_instance.column_for_attribute(column).null ? required = false : required = true 
      html << set_label(column, required)
      if column =~ /_id$/ then
        prefix = nil
        model = column.sub(/_id/,'') 
        (prefix, model) = model.split('_') if model =~ /^\w+_/ 
        html << set_select(column, model, tabindex, prefix, required)
      elsif column =~ /month/ then
        html << set_month(column, tabindex, required)
      elsif column =~ /year/ then
        html << set_year(column, tabindex, required)
      elsif column =~ /other/ then
        html << set_textarea(column, tabindex, required)
      else
        html << set_textfield(column, tabindex, required)
      end
      html << "</div>\n\n" #</div class="row">
      tabindex += 1
    }
    html
  end
  
  def set_classmodel(required=[], numeric=[], belongs_to=[])
    classmodel = ''
    if required.length > 0
      classmodel = "validates_presence_of " + required.join(', ') + "\n"
    end
    
    if numeric.length > 0
      classmodel += "validates_numericality_of " + numeric.join(', ') + "\n" 
    end
    belongs_to.each { | params |
      if params.length > 1 then
        classmodel += "belongs_to :" + params[0].to_s + ", :class_name => '"\
        + params[1].to_s + "', :foreign_key => '" + params[2].to_s + "'\n"
      else 
        classmodel += "belongs_to :" + params[0].to_s + "\n"
      end
    }
    classmodel
  end

  def salva_model (model_instance, singular_name)
    table_name =  Inflector.tableize(model_instance.class.name)
    attrs = model_instance.connection.columns(table_name)
    hidden = %w( id moduser_id user_id dbtime updated_on created_on)
    required = []
    numeric = []
    belongs_to = []
    
    attrs.each { | attr | 
      column = attr.name
      next if hidden.include? column
      if column =~ /_id$/ then
        numeric << ':'+column
        if !model_instance.column_for_attribute(column).null
          required << ':'+column 
        end
        refmodel = column.sub(/_id/,'') 
        if refmodel =~ /^\w+_/ then
          (prefix, model) = refmodel.split('_')
          belongs_to << [ refmodel, Inflector.camelize(model), column ]
        else
          belongs_to << [ refmodel ]
        end
      else
        if !model_instance.column_for_attribute(column).null
          required << ':'+column
        end
      end
    }
    set_classmodel(required, numeric, belongs_to)
  end
end  

class SalvaScaffoldGenerator < Rails::Generator::NamedBase
  attr_reader   :controller_name,
                :controller_class_path,
                :controller_file_path,
                :controller_class_nesting,
                :controller_class_nesting_depth,
                :controller_class_name,
                :controller_singular_name,
                :controller_plural_name
  alias_method  :controller_file_name,  :controller_singular_name
  alias_method  :controller_table_name, :controller_plural_name
  
  def initialize(runtime_args, runtime_options = {})
    super

    # Take controller name from the next argument.  Default to the pluralized model name.
    @controller_name = args.shift
    @controller_name ||= @name #ActiveRecord::Base.pluralize_table_names ? @name.pluralize : 
    
    base_name, @controller_class_path, @controller_file_path, @controller_class_nesting, @controller_class_nesting_depth = extract_modules(@controller_name)
    @controller_class_name_without_nesting, @controller_singular_name, @controller_plural_name = inflect_names(base_name)

    if @controller_class_nesting.empty?
      @controller_class_name = @controller_class_name_without_nesting
    else
      @controller_class_name = "#{@controller_class_nesting}::#{@controller_class_name_without_nesting}"
    end
  end


  def manifest
    record do |m|
      # Check for class naming collisions.
      m.class_collisions controller_class_path, "#{controller_class_name}Controller", 
                                                #"#{controller_class_name}ControllerTest", 
                                                "#{controller_class_name}Helper"
      m.class_collisions class_path,            "#{class_name}"
                                                #"#{class_name}Test"

      # Controller, views, and test directories.
      m.directory File.join('app/models', class_path)
      m.directory File.join('app/controllers', controller_class_path)
      m.directory File.join('app/views', controller_class_path, 
                            controller_file_name)
      m.directory File.join('test/functional', controller_class_path)
      m.directory File.join('test/unit', class_path)

      # Scaffolded models.
      m.complex_template "model_salva.rb",
        File.join('app/models',
                  class_path,
                  "#{file_name}.rb"),
        :insert => 'model_scaffolding.rb',
        :sandbox => lambda { create_sandbox }

      m.template 'controller.rb',
                  File.join('app/controllers',
                            controller_class_path,
                            "#{controller_file_name}_controller.rb")

      m.template 'functional_test.rb',
                  File.join('test/functional',
                            controller_class_path,
                            "#{controller_file_name}_controller_test.rb")

      m.template 'unit_test.rb',
                  File.join('test/unit',
                            class_path,
                            "#{file_name}_test.rb")

      # Scaffolded forms.
        m.complex_template "form.rhtml",
        File.join('app/views',
                  controller_class_path,
                  controller_file_name,
                  "_form.rhtml"),
        :insert => 'form_scaffolding.rhtml',
        :sandbox => lambda { create_sandbox },
        :begin_mark => 'form',
        :end_mark => 'eoform',
        :mark_id => singular_name

      # Scaffolded views and partials.
      %w(list show _show new edit).each do |action|
                              m.template "view_#{action}.rhtml",
                   File.join('app/views',
                             controller_class_path,
                             controller_file_name,
                             "#{action}.rhtml"),
                              :assigns => { :action => action }
                            end
                            
                          end
                        end

  protected
    # Override with your own usage banner.
    def banner
      "Usage: #{$0} salva_scaffold ModelName [ControllerName]"
    end
    
    def model_name
      class_name.demodulize
    end
    
    def unscaffolded_actions
      args - scaffold_actions
    end

    def suffix
      "_#{singular_name}" if options[:suffix]
    end

    def create_sandbox
      sandbox = ScaffoldingSandbox.new
      sandbox.singular_name = singular_name
      sandbox.model_instance = model_instance
      sandbox.instance_variable_set("@#{singular_name}", 
                                    sandbox.model_instance)
      sandbox.suffix = suffix
      sandbox
    end
    
    def model_instance
      base = class_nesting.split('::').inject(Object) do |base, nested|
        break base.const_get(nested) if base.const_defined?(nested)
        print "nested #{nested}\n"
        base.const_set(nested, Module.new)
      end
      unless base.const_defined?(@class_name_without_nesting)
        base.const_set(@class_name_without_nesting, 
                       Class.new(ActiveRecord::Base))
      end
      class_name.constantize.new 
    end
    
  end
