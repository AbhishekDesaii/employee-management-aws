const express = require("express");
const axios = require("axios");

const router = express.Router();

// Where the Flask API lives. Overridable with the API_BASE_URL env var
// (set by docker-compose or Kubernetes), otherwise falls back to localhost.
function apiUrl(req) {
  return req.app.locals.apiBaseUrl || process.env.API_BASE_URL || "http://localhost:5000";
}

// Small helper so the page still renders (with an error banner) when the API
// is down instead of crashing.
async function getData(req, url) {
  try {
    const res = await axios.get(`${apiUrl(req)}${url}`);
    return { data: res.data, error: null };
  } catch (err) {
    return { data: [], error: "Could not reach the API right now." };
  }
}

router.get("/", (req, res) => {
  res.render("index", { title: "Home", activePage: "home", message: null });
});

router.get("/dashboard", async (req, res) => {
  const [employees, departments, projects, stats] = await Promise.all([
    getData(req, "/api/employees"),
    getData(req, "/api/departments"),
    getData(req, "/api/projects"),
    getData(req, "/api/stats"),
  ]);
  const error = employees.error || departments.error || projects.error || stats.error || null;
  res.render("dashboard", {
    title: "Dashboard",
    activePage: "dashboard",
    employees: employees.data,
    departments: departments.data,
    projects: projects.data,
    stats: stats.data.total_employees
      ? stats.data
      : { total_employees: 0, total_departments: 0, total_projects: 0, total_salary: 0, avg_salary: 0 },
    error,
  });
});

router.get("/employees", async (req, res) => {
  const result = await getData(req, "/api/employees");
  res.render("employees", {
    title: "Employees",
    activePage: "employees",
    employees: result.data,
    error: result.error,
  });
});

router.get("/employees/add", (req, res) => {
  res.render("add-employee", { title: "Add Employee", activePage: "employees", error: null });
});

router.get("/employees/edit/:id", async (req, res) => {
  try {
    const res2 = await axios.get(`${apiUrl(req)}/api/employees/${req.params.id}`);
    res.render("edit-employee", {
      title: "Edit Employee",
      activePage: "employees",
      employee: res2.data,
      error: null,
    });
  } catch (err) {
    res.redirect("/employees");
  }
});

router.get("/departments", async (req, res) => {
  const result = await getData(req, "/api/departments");
  res.render("departments", {
    title: "Departments",
    activePage: "departments",
    departments: result.data,
    error: result.error,
  });
});

router.get("/projects", async (req, res) => {
  const result = await getData(req, "/api/projects");
  res.render("projects", {
    title: "Projects",
    activePage: "projects",
    projects: result.data,
    error: result.error,
  });
});

router.get("/about", (req, res) => {
  res.render("about", { title: "About", activePage: "about" });
});

module.exports = router;
