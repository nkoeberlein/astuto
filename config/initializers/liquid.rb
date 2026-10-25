require Rails.root.join('app/lib/custom_liquid_filters') # Load the custom filters module

# Register the custom filter
Liquid::Environment.default.register_filter(CustomLiquidFilters)