class UserRegularcourse < ActiveRecord::Base
validates_presence_of :roleinregularcourse_id, :period_id
validates_numericality_of :regularcourse_id, :roleinregularcourse_id
belongs_to :regularcourse
belongs_to :roleinregularcourse
belongs_to :period
end
