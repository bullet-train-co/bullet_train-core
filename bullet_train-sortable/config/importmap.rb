pin_all_from File.expand_path("../app/javascript/controllers", __dir__), under: "controllers"
# TODO: Why doesn't this work here? We seem to have to put it in the downstream app.
pin "@rails/request.js", to: "requestjs.js"
