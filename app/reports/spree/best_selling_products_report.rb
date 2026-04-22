# frozen_string_literal: true

module Spree
  # Best Selling Products Report
  class BestSellingProductsReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :sold_count
    HEADERS                    = { sku: :string, product_name: :string,
                                   sold_count: :integer, sales_amount: :string }.freeze
    SEARCH_ATTRIBUTES          = { start_date: :orders_completed_from,
                                   end_date: :orders_completed_to }.freeze
    SORTABLE_ATTRIBUTES        = [:product_name, :sku, :sold_count, :sales_amount].freeze

    deeplink product_name: {
      template: %(
        <a href="/#{I18n.locale}/admin/products/{%# o.product_slug %}" target="_blank">
        {%# o.product_name %}</a>
      )
    }

    money sales_amount: {
      template: %(
        {%# o.current_currency %} {%# parseFloat(o.sales_amount).toFixed(2) %}
      )
    }

    class Result < Spree::Report::Result
      # Observation class
      class Observation < Spree::Report::Observation
        observation_fields [
          :current_currency, :product_name, :product_slug, :sku, :sold_count, :sales_amount
        ]

        def current_currency
          currency = Spree::Store.current.default_currency || Spree::Config[:currency]
          Spree::Money.new(currency: currency).currency.symbol
        end

        def sku
          @sku.presence || @product_name
        end
      end
    end

    def report_query
      query_with_inventory_unit_quantities
    end

    def search_name
      search[:name].present? ? "%#{ search[:name] }%" : '%'
    end

    private

    def query_with_inventory_unit_quantities
      Spree::LineItem
        .joins(:order)
        .joins(:variant)
        .joins(product: :translations)
        .joins(:inventory_units)
        .where(Spree::Product.arel_table[:name].matches(search_name))
        .where(spree_orders: { state: 'complete' })
        .where(spree_orders: { completed_at: reporting_period, store_id: Spree::Store.current })
        .where.not(spree_inventory_units: { state: 'returned' })
        .group(:variant_id, :product_name, :product_slug, 'spree_variants.sku')
        .select(
          'spree_product_translations.name as product_name',
          'spree_product_translations.slug as product_slug',
          'spree_variants.sku as sku',
          'sum(spree_inventory_units.quantity) as sold_count',
          'sum(pre_tax_amount) as sales_amount'
        )
    end
  end
end
