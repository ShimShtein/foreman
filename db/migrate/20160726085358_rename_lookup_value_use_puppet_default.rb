class RenameLookupValueUsePuppetDefault < ActiveRecord::Migration
  def change
    # this method is revesible
    rename_column :lookup_values, :use_puppet_default, :skip_foreman
  end
end
