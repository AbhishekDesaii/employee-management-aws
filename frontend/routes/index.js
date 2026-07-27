const express = require("express");
const axios = require("axios");
const router = express.Router();

function getApiUrl(req) {
  return req.app.locals.apiBaseUrl || process.env.API_BASE_URL || "http://localhost:5000";
}

router.get("/", (req, res) => {
  res.render("index", { title: "Home", activePage: "home", message: null });
});

router.get("/dashboard", async (req, res) => {
  try {
    const apiUrl = getApiUrl(req);
    const [empRes, deptRes, projRes, statsRes] = await Promise.all([
      axios.get(`${apiUrl}/api/employees`),
      axios.get(`${apiUrl}/api/departments`),
      axios.get(`${apiUrl}/api/projects`),
      axios.get(`${apiUrl}/api/stats`),
    ]);
    res.render("dashboard", {
      title: "Dashboard",
      activePage: "dashboard",
      employees: empRes.data,
      departments: deptRes.data,
      projects: projRes.data,
      stats: statsRes.data,
    });
  } catch (err) {
    res.render("dashboard", {
      title: "Dashboard",
      activePage: "dashboard",
      employees: [],
      departments: [],
      projects: [],
      stats: { total_employees: 0, total_departments: 0, total_projects: 0, total_salary: 0, avg_salary: 0 },
      error: "Failed to fetch data from API",
    });
  }
});

router.get("/employees", async (req, res) => {
  try {
    const apiUrl = getApiUrl(req);
    const response = await axios.get(`${apiUrl}/api/employees`);
    res.render("employees", {
      title: "Employees",
      activePage: "employees",
      employees: response.data,
    });
  } catch (err) {
    res.render("employees", {
      title: "Employees",
      activePage: "employees",
      employees: [],
      error: "Failed to fetch employees",
    });
  }
});

router.get("/employees/add", (req, res) => {
  res.render("add-employee", { title: "Add Employee", activePage: "employees", error: null });
});

router.get("/employees/edit/:id", async (req, res) => {
  try {
    const apiUrl = getApiUrl(req);
    const response = await axios.get(`${apiUrl}/api/employees/${req.params.id}`);
    res.render("edit-employee", {
      title: "Edit Employee",
      activePage: "employees",
      employee: response.data,
      error: null,
    });
  } catch (err) {
    res.redirect("/employees");
  }
});

router.get("/departments", async (req, res) => {
  try {
    const apiUrl = getApiUrl(req);
    const response = await axios.get(`${apiUrl}/api/departments`);
    res.render("departments", {
      title: "Departments",
      activePage: "departments",
      departments: response.data,
    });
  } catch (err) {
    res.render("departments", {
      title: "Departments",
      activePage: "departments",
      departments: [],
      error: "Failed to fetch departments",
    });
  }
});

router.get("/projects", async (req, res) => {
  try {
    const apiUrl = getApiUrl(req);
    const response = await axios.get(`${apiUrl}/api/projects`);
    res.render("projects", {
      title: "Projects",
      activePage: "projects",
      projects: response.data,
    });
  } catch (err) {
    res.render("projects", {
      title: "Projects",
      activePage: "projects",
      projects: [],
      error: "Failed to fetch projects",
    });
  }
});

router.get("/about", (req, res) => {
  res.render("about", { title: "About", activePage: "about" });
});

module.exports = router;