# Serves the built v2 frontend (frontend/ → public/next) for all its client-side routes.
class SpaController < ActionController::Base
  INDEX = Rails.root.join('public/next/index.html')

  def show
    response.headers['Cache-Control'] = 'no-cache'

    if INDEX.exist?
      render file: INDEX, layout: false, content_type: 'text/html'
    else
      render plain: 'The v2 frontend is not built. Run `npm run build` in frontend/ or use the Vite dev server (port 5173).', status: :not_found
    end
  end
end
