# Notices for feedback spaces waiting for their owner's email confirmation or blocked by the
# instance admin. Rendered without the v2 frontend (the space itself is not loaded).
class StaticPagesController < ApplicationController
  skip_before_action :load_tenant_data, only: [:pending_tenant, :blocked_tenant]

  layout 'plain'

  def pending_tenant
  end

  def blocked_tenant
  end
end
