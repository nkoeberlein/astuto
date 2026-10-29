# LDAP / Active Directory login, one directory per feedback space
class CreateLdapConfigs < ActiveRecord::Migration[8.1]
  def change
    create_table :ldap_configs do |t|
      t.references :tenant, null: false, foreign_key: true, index: { unique: true }
      t.boolean :enabled, null: false, default: false
      t.string :label, null: false, default: 'Company account'
      t.string :host
      t.integer :port, null: false, default: 389
      # plain, start_tls or simple_tls (LDAPS)
      t.string :encryption, null: false, default: 'start_tls'
      t.boolean :verify_certificate, null: false, default: true
      t.string :base_dn
      # Service account for the search; blank searches anonymously
      t.string :bind_dn
      t.string :bind_password_ciphertext
      # %{login} is replaced by the escaped login name
      t.string :user_filter, null: false, default: '(|(uid=%{login})(sAMAccountName=%{login})(mail=%{login}))'
      t.string :email_attribute, null: false, default: 'mail'
      t.string :name_attribute, null: false, default: 'displayName'
      t.boolean :auto_create_users, null: false, default: true
      t.timestamps
    end
  end
end
