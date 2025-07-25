// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "jquery";
import "controllers";


let timeout = null;

const handleSearchInput = function (event) {
  event.preventDefault();
  event.stopPropagation();

  clearTimeout(timeout);

  timeout = setTimeout(() => {
    const query = this.value;
    if (query.length >= 2) {
      fetch(`${this.dataset.url}?query=${encodeURIComponent(query)}`, {
        headers: {
          Accept: "text/vnd.turbo-stream.html",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        },
      })
        .then((response) => {
          if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
          }
          return response.text();
        })
        .then((html) => {
          Turbo.renderStreamMessage(html);
        })
        .catch((error) => {
          console.error("Search error:", error);
        });
    }
  }, 1000);
};

document.addEventListener("turbo:load", function () {

  clearTimeout(timeout);
  const searchInput = document.querySelector("#ticker_search");
  if (searchInput) {
    searchInput.removeEventListener("input", handleSearchInput);
    searchInput.addEventListener("input", handleSearchInput);
  }
});

// document.addEventListener("turbo:load", function () {
//   document.querySelector("#ticker_search")?.addEventListener("input", function (event) {
//     event.preventDefault(); // Prevent Turbo interference
//     event.stopPropagation(); // Stop event bubbling  clearTimeout(timeout);
//     clearTimeout(timeout); // Clear previous keystroke timeout
//     timeout = setTimeout(() => {
//       const query = this.value;
//       if (query.length >= 2) {
//         fetch(`${this.dataset.url}?query=${encodeURIComponent(query)}`, {
//           headers: {
//             Accept: "text/vnd.turbo-stream.html",
//             "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
//           },
//         })
//           .then((response) => {
//             if (!response.ok) { throw new Error(`HTTP error! Status: ${response.status}`); }
//             return response.text();
//           })
//           .then((html) => { Turbo.renderStreamMessage(html) })
//           .catch((error) => console.error("Search error:", error));
//       }
//     }, 1000);
//   });
// });