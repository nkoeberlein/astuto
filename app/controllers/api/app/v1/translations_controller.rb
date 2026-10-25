module Api::App::V1
  # Frontend translations for a locale, with English as fallback.
  # Source: config/locales/<locale>.yml (frontend keys) plus ActiveRecord model names.
  class TranslationsController < Api::App::BaseController
    FRONTEND_KEYS = (
      YAML.load_file(Rails.root.join('config/locales/en.yml'))['en'].keys.map(&:to_sym) + %i[activerecord devise]
    ).freeze

    # GET /api/app/v1/translations/:locale
    def show
      locale = I18n.available_locales.map(&:to_s).find { |l| l == params[:locale] }
      return render_not_found if locale.nil?

      expires_in 1.hour, public: true
      render json: translations_for(:en).deep_merge(translations_for(locale.to_sym))
    end

    private

      def translations_for(locale)
        I18n.backend.send(:init_translations) unless I18n.backend.initialized?
        all = I18n.backend.send(:translations)[locale] || {}
        all.slice(*FRONTEND_KEYS)
      end
  end
end
