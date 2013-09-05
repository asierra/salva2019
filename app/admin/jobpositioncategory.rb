ActiveAdmin.register Jobpositioncategory do

  index do 
    column :id
    column :name
    column :administrative_key
  end

  form do |f|
    f.inputs do
      f.input :jobpositiontype, :as => :select, :input_html => { :class => "chosen-select" }
      f.input :roleinjobposition, :as => :select, :input_html => { :class => "chosen-select" }
      f.input :jobpositionlevel, :as => :select, :input_html => { :class => "chosen-select" }
      f.input :administrative_key, :as => :string
    end
    f.buttons
  end
end
