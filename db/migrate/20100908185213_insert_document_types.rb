class InsertDocumentTypes < ActiveRecord::Migration[6.1]
  def self.up
    ['Informe anual de actividades', 'Informe anual', 'Informe final', 'Informe semestral'].each do |name|
      DocumentType.create(:name => name)
    end
  end

  def self.down
    DocumentType.destroy_all
  end
end
