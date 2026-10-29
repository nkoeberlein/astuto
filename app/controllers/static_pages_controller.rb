# Rails-rendered pages that are not part of the v2 frontend: the multi-tenancy showcase and
# the notices for pending or blocked feedback spaces
class StaticPagesController < ApplicationController
  skip_before_action :load_tenant_data, only: [:showcase, :pending_tenant, :blocked_tenant]

  def showcase
    render html: 'Showcase home page.'
  end

  def pending_tenant
  end

  def blocked_tenant
  end
end
