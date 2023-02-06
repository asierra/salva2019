class RemovingNotNullConstraintsInTheses < ActiveRecord::Migration[6.1]
  def up
      execute "ALTER TABLE theses ALTER COLUMN startyear DROP NOT NULL;"
  end

  def down
      execute "ALTER TABLE theses ALTER COLUMN startyear SET NOT NULL;"
  end
end
