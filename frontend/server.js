const express = require("express");
const path = require("path");
const indexRouter = require("./routes/index");

const app = express();
const PORT = process.env.PORT || 3000;
const API_BASE_URL = process.env.API_BASE_URL || "http://localhost:5000";

app.set("view engine", "ejs");
app.set("views", path.join(__dirname, "views"));
app.use(express.static(path.join(__dirname, "public")));

app.use((req, res, next) => {
  res.locals.apiBaseUrl = API_BASE_URL;
  next();
});

app.use("/", indexRouter);

app.use((req, res) => {
  res.status(404).render("index", {
    title: "404 - Not Found",
    message: "Page not found",
    activePage: "",
  });
});

app.listen(PORT, () => {
  console.log(`Frontend server running on port ${PORT}`);
  console.log(`API Base URL: ${API_BASE_URL}`);
});

module.exports = app;