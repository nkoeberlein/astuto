require 'rails_helper'

# Every static key the v2 frontend translates with t('...') must exist in English; missing keys
# show up as the raw key (e.g. as the label of a form field).
RSpec.describe 'translation keys of the v2 frontend' do
  frontend = Rails.root.join('frontend/src')

  def translated?(translations, key)
    node = key.split('.').reduce(translations) { |hash, part| hash.is_a?(Hash) ? hash[part.to_sym] : nil }
    node.is_a?(String) || (node.is_a?(Hash) && (node.key?(:one) || node.key?(:other)))
  end

  it 'finds every key in the English translations' do
    skip 'frontend sources are not in this image' unless frontend.exist?

    I18n.backend.send(:init_translations) unless I18n.backend.initialized?
    english = I18n.backend.send(:translations)[:en]
    keys = Dir[frontend.join('**/*.{ts,tsx}')].reject { |file| file.include?('.test.') }.flat_map do |file|
      File.read(file, encoding: 'UTF-8').scan(/\bt\(\s*'([a-z0-9_.]+)'/).flatten
    end.uniq

    expect(keys.size).to be > 100
    expect(keys.reject { |key| translated?(english, key) }).to eq([])
  end
end
