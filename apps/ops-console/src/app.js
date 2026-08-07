const target = document.querySelector("#api-base");
target.textContent = window.SKYBRIDGE_CONFIG?.apiBase || "Not configured";