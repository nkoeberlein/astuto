# Configure I18n to look at subfolders too
I18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.yml')]

I18n.available_locales = [:en, :it, :de, :fr, :es, :pt, 'zh-CN', :ru, :vi, :tr, :cs, :pl, :el, :hi, :nl, :sr, :sv]

# Custom pluralization rules
# The frontend (frontend/src/lib/i18n.tsx) picks one/other from `count` on its own
I18n::Backend::Simple.include(I18n::Backend::Pluralization)
I18n.backend.store_translations 'zh-CN', i18n: { plural: { rule: lambda { |_n| :other } } } # Chinese simplified
I18n.backend.store_translations :vi, i18n: { plural: { rule: lambda { |_n| :other } } } # Vietnamese