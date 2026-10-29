# SAML 2.0 single sign-on, one identity provider per feedback space
class CreateSamlConfigs < ActiveRecord::Migration[8.1]
  def change
    create_table :saml_configs do |t|
      t.references :tenant, null: false, foreign_key: true, index: { unique: true }
      t.boolean :enabled, null: false, default: false
      t.string :label, null: false, default: 'Single sign-on'
      t.string :idp_entity_id
      t.string :idp_sso_url
      t.text :idp_cert
      # Attribute names in the assertion; blank email uses the NameID
      t.string :email_attribute
      t.string :name_attribute
      # Create an account on the first login (otherwise only existing accounts sign in)
      t.boolean :auto_create_users, null: false, default: true
      t.timestamps
    end
  end
end
