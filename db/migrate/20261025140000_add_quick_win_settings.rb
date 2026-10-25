class AddQuickWinSettings < ActiveRecord::Migration[8.1]
  def change
    # Roadmap can be disabled entirely (#361)
    add_column :tenant_settings, :roadmap_enabled, :boolean, default: true, null: false

    # Instance-wide default post sorting (#193, #363), used when no ?sort= is given
    add_column :tenant_settings, :default_post_sorting, :string, default: "trending", null: false

    # Additional header links (#479, #351): [{ "label" => "...", "url" => "..." }]
    add_column :tenant_settings, :custom_links, :jsonb, default: [], null: false

    # Hide the email/password login and registration forms (#471)
    add_column :tenant_settings, :login_only_with_oauth, :boolean, default: false, null: false

    # Configurable favicon (#452)
    add_column :tenants, :site_favicon, :string
  end
end