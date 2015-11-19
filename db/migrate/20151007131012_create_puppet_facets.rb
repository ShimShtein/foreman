class CreatePuppetFacets < ActiveRecord::Migration
  def change
    create_table :puppet_facets do |t|
      t.integer :host_id
      t.integer :puppet_status
      t.integer :environment_id
      t.integer :puppet_ca_proxy_id
      t.integer :puppet_proxy_id

      t.timestamps
    end
  end
end
