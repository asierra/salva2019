class Projectresearcharea < ActiveRecord::Base
validates_presence_of :project_id, :researcharea_id
validates_numericality_of :project_id, :researcharea_id
belongs_to :project
belongs_to :researcharea
end
