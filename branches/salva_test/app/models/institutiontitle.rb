class Institutiontitle < ActiveRecord::Base
  validates_numericality_of :id, :allow_nil => true, :only_integer => true

  validates_presence_of :name
  validates_uniqueness_of :name

  validates_associated :institution, :on => :update
  has_many :institution
end
