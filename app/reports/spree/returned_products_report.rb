# frozen_string_literal: true

module Spree
  # Returned_products Report
  class ReturnedProductsReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :product_name
    HEADERS                    = { sku: :string, product_name: :string,
                                   return_count: :integer }.freeze
    SEARCH_ATTRIBUTES          = { start_date: :product_returned_from,
                                   end_date: :product_returned_till }.freeze
    SORTABLE_ATTRIBUTES        = [:product_name, :sku, :return_count].freeze

    deeplink product_name: {
      template: %(
        <a href="/#{I18n.locale}/admin/products/{%# o.product_slug %}" target="_blank">
        {%# o.product_name %}</a>
      )
    }

    class Result < Spree::Report::Result
      # Observation class
      class Observation < Spree::Report::Observation
        observation_fields [:sku, :product_name, :return_count, :product_slug]

        def sku
          @sku.presence || @product_name
        end
      end
    end

    def report_query
      return query_with_inventory_unit_quantities if Spree.version.to_f >= 3.3

      query_without_inventory_unit_quantities
    end

    private

    def query_with_inventory_unit_quantities
      Spree::ReturnAuthorization.by_store(Spree::Store.current)
        .joins(return_items: { inventory_unit: { variant: { product: :translations } } })
        .where(spree_return_items: { created_at: reporting_period })
        .group(
          'spree_variants.id',
          'spree_product_translations.name',
          'spree_product_translations.slug',
          'spree_variants.sku'
        )
        .select(
          'spree_product_translations.name as product_name',
          'spree_product_translations.slug as product_slug',
          'spree_variants.sku as sku',
          'sum(spree_inventory_units.quantity) as return_count'
        )
    end

    def query_without_inventory_unit_quantities
      Spree::ReturnAuthorization.by_store(Spree::Store.current)
        .joins(return_items: { inventory_unit: { variant: { product: :translations } } })
        .where(spree_return_items: { created_at: reporting_period })
        .group(
          'spree_variants.id',
          'spree_product_translations.name',
          'spree_product_translations.slug',
          'spree_variants.sku'
        )
        .select(
          'spree_product_translations.name as product_name',
          'spree_product_translations.slug as product_slug',
          'spree_variants.sku as sku',
          'COUNT(spree_variants.id) as return_count'
        )
    end
  end
end
