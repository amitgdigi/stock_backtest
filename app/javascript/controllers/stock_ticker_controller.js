import { Controller } from "@hotwired/stimulus";
import "select2";

export default class extends Controller {
  connect() {
    const $ = jQuery;

    if (!$) {
      console.error("jQuery is not defined. Ensure it is loaded before select2.");
      return;
    }

    $(this.element).select2({
      placeholder: "Select or type a ticker...",
      allowClear: true,
      minimumInputLength: 2,
      ajax: {
        url: "/stocks/search",
        dataType: "json",
        delay: 500,
        data: function (params) {
          return { query: params.term };
        },
        processResults: function (data) {
          return {
            results: data.map(function (stock) {
              return {
                id: stock.ticker,
                text: stock.name ? `${stock.ticker} - ${stock.name}` : stock.ticker,
              };
            }),
          };
        },
        cache: true,
      },
    });

    $(this.element).on("select2:select", () => {
      this.element.dispatchEvent(new Event("change", { bubbles: true }));
    });
  }

  disconnect() {
    if (jQuery) {
      const $ = jQuery;
      $(this.element).select2("destroy");
    }
  }
}