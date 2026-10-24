require 'stripe'

Stripe.api_key = Rails.application.stripe_secret_key

# Keep the API version the billing code was written for (stripe gem 11).
# Newer versions change response shapes, e.g. invoice line items lost `price`
# in 2025-03-31, which BillingController#webhook reads. Raise this only together
# with a test against a Stripe test account, and set the same version on the
# webhook endpoint in the Stripe dashboard.
Stripe.api_version = '2024-04-10'
